import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/data/env/end_points.dart';
import 'package:superdriver_admin/domain/models/notification_model.dart';
import 'package:superdriver_admin/modules/notification/cubit/notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());

  static NotificationCubit get(BuildContext context) => BlocProvider.of(context);

  static const _longTimeout = Duration(seconds: 15);
  static const _shortTimeout = Duration(seconds: 10);

  List<NotificationModel> notifications = [];
  int unreadCount = 0;

  String? get _token =>
      locator<SharedPreferencesRepository>().getData(key: 'access_token');

  Map<String, String> get _headers => {
    if (_token != null) 'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  void _emit(NotificationState state) {
    if (!isClosed) emit(state);
  }

  // ── Fetch Notifications ───────────────────────────────────────────────────

  Future<void> getNotifications({bool unreadOnly = false}) async {
    if (_token == null) {
      _emit(NotificationsError('Not logged in'));
      return;
    }
    _emit(NotificationsLoading());

    try {
      final url = unreadOnly
          ? '${ConstantsService.notificationsEndpoint}?unread_only=true'
          : ConstantsService.notificationsEndpoint;

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_longTimeout);

      if (isClosed) return;

      switch (response.statusCode) {
        case 200:
          final decoded = jsonDecode(response.body);
          final raw = _extractList(decoded);
          notifications = raw
              .map((e) => NotificationModel.fromJson(e))
              .toList();
          _emit(NotificationsLoaded(notifications));
        case 401:
          _emit(NotificationsError('Session expired'));
        case 403:
          _emit(NotificationsError('No permission'));
        default:
          _emit(
            NotificationsError(
              'Failed to load notifications (${response.statusCode})',
            ),
          );
      }
    } catch (_) {
      _emit(NotificationsError('Connection error'));
    }
  }

  // ── Mark Single As Read ───────────────────────────────────────────────────

  Future<void> markAsRead(int notificationId) async {
    if (_token == null) return;

    try {
      final url = Uri.parse(
        ConstantsService.notificationReadEndpoint(notificationId),
      );

      final response = await http
          .post(url, headers: _headers)
          .timeout(_shortTimeout);

      if (response.statusCode == 200) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(isRead: true);
          _emit(NotificationsLoaded(List.of(notifications)));
        }
        await getUnreadCount();
      } else {
        debugPrint('Mark read failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  // ── Mark All As Read ──────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    if (_token == null) {
      _emit(MarkReadError('Not logged in'));
      return;
    }
    _emit(MarkReadLoading());

    try {
      final url = Uri.parse(ConstantsService.notificationsReadAllEndpoint);

      final response = await http
          .post(url, headers: _headers)
          .timeout(_shortTimeout);

      if (response.statusCode == 200) {
        _emit(MarkReadSuccess());
        notifications = notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _emit(NotificationsLoaded(List.of(notifications)));
        await getUnreadCount();
      } else {
        _emit(MarkReadError('Failed to mark all as read'));
      }
    } catch (_) {
      _emit(MarkReadError('Connection error'));
    }
  }

  // ── Unread Count ──────────────────────────────────────────────────────────

  Future<void> getUnreadCount() async {
    if (_token == null) return;

    try {
      final url = Uri.parse(ConstantsService.notificationsUnreadCountEndpoint);

      final response = await http
          .get(url, headers: _headers)
          .timeout(_shortTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        unreadCount = data['count'] ?? data['unread_count'] ?? 0;
        _emit(UnreadCountLoaded(unreadCount));
      }
    } catch (_) {}
  }

  // ── Notification Detail ───────────────────────────────────────────────────

  Future<void> getNotificationDetail(int notificationId) async {
    if (_token == null) {
      _emit(NotificationDetailError('Not logged in'));
      return;
    }
    _emit(NotificationDetailLoading());

    try {
      final url = Uri.parse(
        ConstantsService.notificationDetailEndpoint(notificationId),
      );

      final response = await http
          .get(url, headers: _headers)
          .timeout(_longTimeout);

      switch (response.statusCode) {
        case 200:
          final notification = NotificationModel.fromJson(
            jsonDecode(response.body),
          );
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) notifications[index] = notification;
          _emit(NotificationDetailLoaded(notification));
        case 404:
          _emit(NotificationDetailError('Notification not found'));
        default:
          _emit(NotificationDetailError('Failed to load details'));
      }
    } catch (_) {
      _emit(NotificationDetailError('Connection error'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      return decoded['data'] ??
          decoded['notifications'] ??
          decoded['results'] ??
          [];
    }
    return [];
  }
}
