import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { text, image, location, system, unknown }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderType;
  final ChatMessageType type;
  final String? text;
  final String? imageUrl;
  final Map<String, dynamic>? locationData;
  final DateTime? createdAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.type,
    this.text,
    this.imageUrl,
    this.locationData,
    this.createdAt,
    this.readAt,
  });

  bool get isAdminMessage => senderType == 'admin';

  bool get isUserMessage => senderType == 'user';

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    final typeStr = (data['type'] ?? 'text').toString();
    final type = switch (typeStr) {
      'text' => ChatMessageType.text,
      'image' => ChatMessageType.image,
      'location' => ChatMessageType.location,
      'system' => ChatMessageType.system,
      _ => ChatMessageType.unknown,
    };

    final senderType = (data['senderType'] ?? data['sender'] ?? '').toString();

    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      senderType: senderType,
      type: type,
      text: data['text']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      locationData: data['locationData'] is Map<String, dynamic>
          ? data['locationData'] as Map<String, dynamic>
          : null,
      createdAt: parseDate(data['createdAt']),
      readAt: parseDate(data['readAt']),
    );
  }
}
