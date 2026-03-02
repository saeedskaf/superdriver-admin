import 'dart:convert';

import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/domain/models/admin_chat_conversation.dart';
import 'package:superdriver_admin/firebase_options.dart';
import 'package:superdriver_admin/modules/chat/admin_chat_room_screen.dart';
import 'package:superdriver_admin/modules/splash/splash_screen.dart';
import 'package:superdriver_admin/shared/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Globals
// ─────────────────────────────────────────────────────────────────────────────

/// Global navigator key — used for notification-tap navigation from anywhere.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
  'chat',
  'Chat Notifications',
  description: 'Notifications for new chat messages',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

// ─────────────────────────────────────────────────────────────────────────────
// Background handler (must be top-level)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tap handler
// ─────────────────────────────────────────────────────────────────────────────

/// Navigates to the chat room when a notification is tapped.
/// Works for both FCM messages and local notification taps.
void _handleNotificationNavigation(Map<String, dynamic>? data) {
  if (data == null) return;

  final chatId = data['chatId']?.toString();
  if (chatId == null || chatId.isEmpty) return;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => AdminChatRoomScreen(
        conversation: AdminChatConversation(
          conversationId: chatId,
          userId: data['userId']?.toString() ?? '',
          userName: (data['userName'] ?? 'User').toString(),
          userPhone: data['userPhone']?.toString() ?? '',
          referenceId: data['referenceId']?.toString() ?? chatId,
          type: AdminChatConversationType.unknown,
          status: 'open',
          lastMessage: '',
          lastMessageBy: '',
          unreadByAdmin: 0,
          unreadByUser: 0,
        ),
      ),
    ),
  );
}

/// Parses JSON payload from local notification tap → navigation data.
void _handleLocalNotificationTap(String? payload) {
  if (payload == null || payload.isEmpty) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    _handleNotificationNavigation(data);
  } catch (_) {
    _handleNotificationNavigation({'chatId': payload});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local notifications setup
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _initLocalNotifications() async {
  await localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (response) {
      _handleLocalNotificationTap(response.payload);
    },
  );

  final android = localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await android?.createNotificationChannel(chatChannel);
  await android?.requestNotificationsPermission();
}

// ─────────────────────────────────────────────────────────────────────────────
// Foreground message listener
// ─────────────────────────────────────────────────────────────────────────────

void _listenToForegroundMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Encode useful data as JSON so the tap handler can navigate.
    final payload = jsonEncode({
      'chatId': message.data['chatId'],
      'userId': message.data['userId'],
      'userName': message.data['userName'],
      'userPhone': message.data['userPhone'],
      'referenceId': message.data['referenceId'],
    });

    localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'New Message',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          chatChannel.id,
          chatChannel.name,
          channelDescription: chatChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupLocator();
  await _initLocalNotifications();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Disable FCM's own foreground banner on iOS.
  // Foreground display is handled exclusively by _listenToForegroundMessages.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  _listenToForegroundMessages();

  // App resumed by tapping a notification (background → foreground).
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  });

  // App launched by tapping a notification (terminated → foreground).
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay slightly to ensure navigation stack is ready after splash.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationNavigation(initialMessage.data);
      });
    });
  }

  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SuperDriver Admin',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
