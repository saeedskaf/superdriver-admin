import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminChatConversationType { orderRequest, emergencyTicket, unknown }

class AdminChatConversation {
  const AdminChatConversation({
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.referenceId,
    required this.type,
    required this.status,
    required this.lastMessage,
    required this.lastMessageBy,
    required this.unreadByAdmin,
    required this.unreadByUser,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
    this.addressId,
    this.addressTitle,
    this.addressSummary,
    this.issueCategory,
    this.issueLabel,
    this.relatedOrderId,
  });

  final String conversationId;
  final String userId;
  final String userName;
  final String userPhone;
  final String referenceId;
  final AdminChatConversationType type;
  final String status;
  final String lastMessage;
  final String lastMessageBy;
  final int unreadByAdmin;
  final int unreadByUser;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? addressId;
  final String? addressTitle;
  final String? addressSummary;
  final String? issueCategory;
  final String? issueLabel;
  final String? relatedOrderId;

  bool get isOpen => status == 'open';

  bool get isOrderRequest => type == AdminChatConversationType.orderRequest;

  bool get isEmergencyTicket =>
      type == AdminChatConversationType.emergencyTicket;

  String get typeKey => switch (type) {
    AdminChatConversationType.orderRequest => 'order_request',
    AdminChatConversationType.emergencyTicket => 'emergency_ticket',
    AdminChatConversationType.unknown => 'unknown',
  };

  String get typeLabel => switch (type) {
    AdminChatConversationType.orderRequest => 'Order Request',
    AdminChatConversationType.emergencyTicket => 'Emergency Ticket',
    AdminChatConversationType.unknown => 'Conversation',
  };

  DateTime? get sortAt => updatedAt ?? lastMessageAt ?? createdAt;

  factory AdminChatConversation.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    final rawType = (data['type'] ?? '').toString();
    final type = switch (rawType) {
      'order_request' => AdminChatConversationType.orderRequest,
      'emergency_ticket' => AdminChatConversationType.emergencyTicket,
      _ => AdminChatConversationType.unknown,
    };

    return AdminChatConversation(
      conversationId: doc.id,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'User').toString(),
      userPhone: (data['userPhone'] ?? '').toString(),
      referenceId: (data['referenceId'] ?? doc.id).toString(),
      type: type,
      status: (data['status'] ?? 'open').toString(),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageBy: (data['lastMessageBy'] ?? '').toString(),
      unreadByAdmin: parseInt(data['unreadByAdmin']) ?? 0,
      unreadByUser: parseInt(data['unreadByUser']) ?? 0,
      lastMessageAt: parseDate(data['lastMessageAt']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      addressId: parseInt(data['addressId']),
      addressTitle: data['addressTitle']?.toString(),
      addressSummary: data['addressSummary']?.toString(),
      issueCategory: data['issueCategory']?.toString(),
      issueLabel: data['issueLabel']?.toString(),
      relatedOrderId: data['relatedOrderId']?.toString(),
    );
  }
}
