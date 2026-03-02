import 'package:superdriver_admin/domain/models/chat_message.dart';

abstract class AdminChatRoomState {}

class AdminChatRoomLoading extends AdminChatRoomState {}

class AdminChatRoomLoaded extends AdminChatRoomState {
  final List<ChatMessage> messages;
  final bool sending;
  AdminChatRoomLoaded(this.messages, {this.sending = false});
}

class AdminChatRoomError extends AdminChatRoomState {
  final String message;
  AdminChatRoomError(this.message);
}
