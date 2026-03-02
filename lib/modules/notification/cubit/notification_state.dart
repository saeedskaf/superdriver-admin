import 'package:superdriver_admin/domain/models/notification_model.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

// Fetch notifications
class NotificationsLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  NotificationsLoaded(this.notifications);
}

class NotificationsError extends NotificationState {
  final String message;
  NotificationsError(this.message);
}

// Mark as read
class MarkReadLoading extends NotificationState {}

class MarkReadSuccess extends NotificationState {}

class MarkReadError extends NotificationState {
  final String message;
  MarkReadError(this.message);
}

// Unread count
class UnreadCountLoaded extends NotificationState {
  final int count;
  UnreadCountLoaded(this.count);
}

// Notification detail
class NotificationDetailLoading extends NotificationState {}

class NotificationDetailLoaded extends NotificationState {
  final NotificationModel notification;
  NotificationDetailLoaded(this.notification);
}

class NotificationDetailError extends NotificationState {
  final String message;
  NotificationDetailError(this.message);
}
