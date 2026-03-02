class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: (json['title'] as String?)?.trim() ?? '',
      body:
          (json['body'] as String?)?.trim() ??
          (json['message'] as String?)?.trim() ??
          '',
      notificationType:
          json['notification_type'] as String? ??
          json['type'] as String? ??
          'general',
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      notificationType: notificationType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }
}
