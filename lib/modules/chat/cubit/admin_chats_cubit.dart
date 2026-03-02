import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/admin_chat_conversation.dart';
import 'admin_chats_state.dart';

class AdminChatsCubit extends Cubit<AdminChatsState> {
  AdminChatsCubit() : super(AdminChatsInitial());

  StreamSubscription? _sub;

  void start() {
    emit(AdminChatsLoading());

    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chats')
        .snapshots()
        .listen(
          (snap) {
            final conversations =
                snap.docs.map(AdminChatConversation.fromDoc).toList()
                  ..sort((a, b) {
                    final bAt = b.sortAt;
                    final aAt = a.sortAt;
                    if (aAt == null && bAt == null) return 0;
                    if (aAt == null) return 1;
                    if (bAt == null) return -1;
                    return bAt.compareTo(aAt);
                  });

            if (!isClosed) emit(AdminChatsLoaded(conversations));
          },
          onError: (e) {
            if (!isClosed) emit(AdminChatsError(e.toString()));
          },
        );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
