import '../../../domain/models/admin_chat_conversation.dart';

abstract class AdminChatsState {}

class AdminChatsInitial extends AdminChatsState {}

class AdminChatsLoading extends AdminChatsState {}

class AdminChatsLoaded extends AdminChatsState {
  final List<AdminChatConversation> conversations;
  AdminChatsLoaded(this.conversations);
}

class AdminChatsError extends AdminChatsState {
  final String message;
  AdminChatsError(this.message);
}
