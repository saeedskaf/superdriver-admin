import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/data/env/end_points.dart';

import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  static const _timeout = Duration(seconds: 10);

  /// Ensure admin's FCM token exists in Firestore on every app open.
  /// Uses the `admins` collection (the same one Cloud Function reads from).
  Future<void> refreshAdminFcmToken() async {
    try {
      final prefs = locator<SharedPreferencesRepository>();
      final adminId = prefs.getData(key: 'user_id')?.toString().trim();
      if (adminId == null || adminId.isEmpty) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;

      await FirebaseFirestore.instance.collection('admins').doc(adminId).set({
        'adminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('✅ Admin FCM token refreshed');
    } catch (e) {
      debugPrint('⚠️ refreshAdminFcmToken error: $e');
    }
  }

  /// Remove FCM token from Firestore before logout.
  Future<void> _deleteFcmTokenFromFirestore() async {
    try {
      final prefs = locator<SharedPreferencesRepository>();
      final adminId = prefs.getData(key: 'user_id')?.toString().trim();
      final token = await FirebaseMessaging.instance.getToken();

      if (adminId == null || adminId.isEmpty || token == null) return;

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('fcmTokens')
          .doc(token)
          .delete();

      debugPrint('✅ FCM token deleted from Firestore');
    } catch (e) {
      debugPrint('⚠️ Failed to delete FCM token from Firestore: $e');
    }
  }

  /// Unregister device from the Backend API so push notifications stop.
  Future<void> _unregisterDeviceFromBackend() async {
    try {
      final prefs = locator<SharedPreferencesRepository>();
      final accessToken = prefs.accessToken;
      final deviceToken = prefs.getData(key: 'device_token')?.toString();

      if (accessToken == null || deviceToken == null) return;

      final response = await http
          .post(
            Uri.parse(ConstantsService.unregisterDeviceEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({'token': deviceToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Device unregistered from backend');
      } else {
        debugPrint('⚠️ Device unregister failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Device unregister error: $e');
    }
  }

  /// Full logout: delete token from everywhere, then clear local storage.
  Future<void> logout() async {
    emit(HomeLoggingOut());

    await Future.wait([
      _goOfflineSilently(),
      _deleteFcmTokenFromFirestore(),
      _unregisterDeviceFromBackend(),
    ]);

    await locator<SharedPreferencesRepository>().logout();
    emit(HomeLoggedOut());
  }

  Future<void> _goOfflineSilently() async {
    try {
      final accessToken = locator<SharedPreferencesRepository>().accessToken;
      if (accessToken == null) return;

      await http
          .post(
            Uri.parse(ConstantsService.adminGoOfflineEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(_timeout);
    } catch (_) {
      // Ignore: backend logout also handles offline automatically.
    }
  }
}
