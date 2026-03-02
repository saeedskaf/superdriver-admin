import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/chat_message.dart';
import 'admin_chat_room_state.dart';

class AdminChatRoomCubit extends Cubit<AdminChatRoomState> {
  AdminChatRoomCubit({required this.conversationId, required this.adminId})
    : super(AdminChatRoomLoading());

  final String conversationId;
  final String adminId;

  StreamSubscription? _sub;

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(conversationId);

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _chatRef.collection('messages');

  Future<void> start() async {
    emit(AdminChatRoomLoading());

    await _markConversationRead();

    _sub?.cancel();
    _sub = _messagesRef
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen(
          (snap) {
            if (!isClosed) {
              final messages = snap.docs.map(ChatMessage.fromDoc).toList();
              emit(AdminChatRoomLoaded(messages));
            }
          },
          onError: (e) {
            if (!isClosed) emit(AdminChatRoomError(e.toString()));
          },
        );
  }

  Future<void> _markConversationRead() async {
    final now = FieldValue.serverTimestamp();

    await _chatRef.update({'unreadByAdmin': 0}).catchError((_) {});

    try {
      final snap = await _messagesRef.limit(200).get();
      final unreadDocs = snap.docs.where((doc) {
        final data = doc.data();
        if (data['readAt'] != null) return false;

        final senderType = (data['senderType'] ?? data['sender'] ?? '')
            .toString();
        return senderType == 'user';
      }).toList();

      if (unreadDocs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadDocs) {
        batch.update(doc.reference, {'readAt': now});
      }
      await batch.commit();
    } catch (_) {
      // Ignore read-marking failures so the room can still open.
    }
  }

  Future<void> setStatus(String status) async {
    await _chatRef.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteConversation() async {
    await _deleteCollection(_messagesRef);
    await _deleteCollection(_chatRef.collection('fcmTokens'));
    await _chatRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    while (true) {
      final snap = await ref.limit(100).get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final current = state;
    if (current is AdminChatRoomLoaded) {
      emit(AdminChatRoomLoaded(current.messages, sending: true));
    }

    try {
      final now = FieldValue.serverTimestamp();

      await _messagesRef.add({
        'text': t,
        'senderId': adminId,
        'senderType': 'admin',
        'type': 'text',
        'createdAt': now,
        'readAt': null,
      });

      await _chatRef.update({
        'lastMessage': t,
        'lastMessageAt': now,
        'lastMessageBy': 'admin',
        'unreadByUser': FieldValue.increment(1),
        'updatedAt': now,
      });
    } catch (_) {
      final latest = state;
      if (!isClosed && latest is AdminChatRoomLoaded) {
        emit(AdminChatRoomLoaded(latest.messages, sending: false));
      }
    }
  }

  Future<void> sendImage(File file) async {
    final current = state;
    if (current is AdminChatRoomLoaded) {
      emit(AdminChatRoomLoaded(current.messages, sending: true));
    }

    try {
      final now = FieldValue.serverTimestamp();
      final path =
          'chat_images/$conversationId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final task = await FirebaseStorage.instance.ref(path).putFile(file);
      final url = await task.ref.getDownloadURL();

      await _messagesRef.add({
        'senderId': adminId,
        'senderType': 'admin',
        'type': 'image',
        'imageUrl': url,
        'createdAt': now,
        'readAt': null,
      });

      await _chatRef.update({
        'lastMessage': '📷',
        'lastMessageAt': now,
        'lastMessageBy': 'admin',
        'unreadByUser': FieldValue.increment(1),
        'updatedAt': now,
      });
    } catch (_) {
      final latest = state;
      if (!isClosed && latest is AdminChatRoomLoaded) {
        emit(AdminChatRoomLoaded(latest.messages, sending: false));
      }
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
