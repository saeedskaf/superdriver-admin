import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/data/env/end_points.dart';
import 'package:superdriver_admin/domain/models/user.dart';
import 'package:superdriver_admin/modules/login/cubit/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial()) {
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      _onTokenRefreshed,
    );
  }

  static LoginCubit get(BuildContext context) => BlocProvider.of(context);

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  StreamSubscription<String>? _tokenRefreshSub;

  static const _timeout = Duration(seconds: 10);

  // ── Token Refresh Handler ───────────────────────────────────────────────

  /// Called when FCM rotates the device token.
  /// Updates SharedPreferences, Backend API, and Firestore so notifications
  /// continue to arrive on the new token.
  Future<void> _onTokenRefreshed(String newToken) async {
    try {
      final prefs = locator<SharedPreferencesRepository>();
      await prefs.savedata(key: 'device_token', value: newToken);

      // Update Backend API.
      final accessToken = prefs.accessToken;
      if (accessToken != null) {
        await http
            .post(
              Uri.parse(ConstantsService.registerDeviceEndpoint),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode({
                'token': newToken,
                'device_type': Platform.isIOS ? 'ios' : 'android',
                'device_name': Platform.isAndroid ? 'Android Device' : 'iPhone',
                'language': 'en',
              }),
            )
            .timeout(_timeout);
      }

      // Update Firestore.
      final adminId = prefs.getData(key: 'user_id')?.toString().trim();
      if (adminId != null && adminId.isNotEmpty) {
        await _ensureAdminFirestoreDoc(adminId);
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId)
            .collection('fcmTokens')
            .doc(newToken)
            .set({
              'token': newToken,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      debugPrint('🔄 FCM token refreshed everywhere');
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> loginUser() async {
    emit(LoginLoading());

    try {
      final response = await http
          .post(
            Uri.parse(ConstantsService.loginEndpoint),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'phone_number': phoneController.text.trim(),
              'password': passwordController.text.trim(),
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      switch (response.statusCode) {
        case 200:
          await _handleSuccess(body);
        case 400:
          emit(LoginFailure(_extract400Error(body)));
        case 401:
          emit(LoginFailure('Invalid phone number or password'));
        default:
          emit(LoginFailure('Login failed (${response.statusCode})'));
      }
    } on SocketException {
      emit(LoginFailure('No internet connection'));
    } catch (e) {
      debugPrint('Login error: $e');
      emit(LoginFailure('Connection error'));
    }
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleSuccess(Map<String, dynamic> body) async {
    final tokens = body['tokens'] as Map<String, dynamic>;
    final accessToken = tokens['access'] as String;
    final refreshToken = tokens['refresh'] as String;
    final user = User.fromJson(body['user'] as Map<String, dynamic>);

    if (user.role != 'admin') {
      emit(LoginFailure('Access denied. Admin accounts only.'));
      return;
    }

    final prefs = locator<SharedPreferencesRepository>();

    await Future.wait([
      prefs.savedata(key: 'access_token', value: accessToken),
      prefs.savedata(key: 'refresh_token', value: refreshToken),
      prefs.saveUserInfo(user: user),
      prefs.setLoggedIn(isLoggedIn: true),
    ]);

    // Get FCM token once, then register everywhere in parallel.
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null && fcmToken.isNotEmpty) {
      final adminId = user.id.toString();
      final displayName = [user.firstName, user.lastName]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ');

      // Firestore writes are best-effort and must not block successful login.
      try {
        await _ensureAdminFirestoreDoc(
          adminId,
          name: displayName,
          phone: user.phoneNumber,
        );
      } catch (e) {
        debugPrint('Failed to save admin profile to Firestore: $e');
      }

      await Future.wait([
        _registerDeviceToken(accessToken, fcmToken),
        _saveFcmTokenToFirestore(adminId, fcmToken),
      ]);
    }

    emit(LoginSuccess());
  }

  String _extract400Error(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map) {
      final nonFieldErrors = errors['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        return nonFieldErrors.first.toString();
      }
    }
    return 'Invalid phone number or password';
  }

  // ── Device token registration ──────────────────────────────────────────────

  Future<void> _registerDeviceToken(String accessToken, String token) async {
    try {
      final response = await http
          .post(
            Uri.parse(ConstantsService.registerDeviceEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'token': token,
              'device_type': Platform.isIOS ? 'ios' : 'android',
              'device_name': Platform.isAndroid ? 'Android Device' : 'iPhone',
              'language': 'en',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = locator<SharedPreferencesRepository>();

        await Future.wait([
          if (responseBody['id'] != null)
            prefs.savedata(
              key: 'device_id',
              value: responseBody['id'].toString(),
            ),
          prefs.savedata(key: 'device_token', value: token),
        ]);

        debugPrint('✅ Device token registered');
      } else {
        debugPrint('⚠️ Device register failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Device register error: $e');
    }
  }

  // ── Firestore FCM token ────────────────────────────────────────────────────

  Future<void> _ensureAdminFirestoreDoc(
    String adminId, {
    String? name,
    String? phone,
  }) async {
    await FirebaseFirestore.instance.collection('admins').doc(adminId).set({
      'adminId': adminId,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveFcmTokenToFirestore(String adminId, String token) async {
    try {
      await _ensureAdminFirestoreDoc(adminId);
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Failed to save FCM token to Firestore: $e');
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
