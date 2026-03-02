import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/domain/models/admin_chat_conversation.dart';
import 'package:superdriver_admin/domain/models/chat_message.dart';
import 'package:superdriver_admin/modules/add_order/add_order_screen.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

import 'cubit/admin_chat_room_cubit.dart';
import 'cubit/admin_chat_room_state.dart';

class AdminChatRoomScreen extends StatefulWidget {
  const AdminChatRoomScreen({super.key, required this.conversation});

  final AdminChatConversation conversation;

  @override
  State<AdminChatRoomScreen> createState() => _AdminChatRoomScreenState();
}

class _AdminChatRoomScreenState extends State<AdminChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  late final AdminChatRoomCubit _cubit;
  late AdminChatConversation _conversation;
  StreamSubscription? _conversationSub;
  final Set<String> _selectedMessageIds = <String>{};

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;

    final prefs = locator<SharedPreferencesRepository>();
    final storedAdminId = prefs.getData(key: 'user_id')?.toString().trim();
    final adminId = (storedAdminId?.isNotEmpty ?? false)
        ? storedAdminId!
        : 'admin';

    _cubit = AdminChatRoomCubit(
      conversationId: _conversation.conversationId,
      adminId: adminId,
    )..start();

    _conversationSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(_conversation.conversationId)
        .snapshots()
        .listen((doc) {
          if (!mounted || !doc.exists) return;
          setState(() {
            _conversation = AdminChatConversation.fromDoc(doc);
          });
        });
  }

  @override
  void dispose() {
    _conversationSub?.cancel();
    _msgCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _setStatus(String status) async {
    try {
      await _cubit.setStatus(status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update status: $e')));
    }
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
          'This will delete the conversation, all messages, and its chat FCM tokens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _cubit.deleteConversation();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete chat: $e')));
    }
  }

  bool get _canCreateOrderFromChat => _conversation.isOrderRequest;

  List<ChatMessage> get _currentMessages {
    final state = _cubit.state;
    if (state is AdminChatRoomLoaded) return state.messages;
    return const <ChatMessage>[];
  }

  void _toggleMessageSelection(ChatMessage message) {
    if (message.type != ChatMessageType.text || (message.text ?? '').isEmpty) {
      return;
    }

    setState(() {
      if (_selectedMessageIds.contains(message.id)) {
        _selectedMessageIds.remove(message.id);
      } else {
        _selectedMessageIds.add(message.id);
      }
    });
  }

  void _clearSelection() {
    if (_selectedMessageIds.isEmpty) return;
    setState(() => _selectedMessageIds.clear());
  }

  List<ChatMessage> _resolveDescriptionMessages(List<ChatMessage> messages) {
    final selected = messages
        .where(
          (message) =>
              _selectedMessageIds.contains(message.id) &&
              message.type == ChatMessageType.text &&
              (message.text ?? '').trim().isNotEmpty,
        )
        .toList();

    if (selected.isNotEmpty) {
      selected.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      return selected;
    }
    return const <ChatMessage>[];
  }

  Future<void> _openCreateOrderFlow() async {
    if (!_canCreateOrderFromChat) return;

    final descriptionMessages = _resolveDescriptionMessages(_currentMessages);
    final lines = descriptionMessages
        .map((message) => message.text!.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final description = lines.join('\n');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Create Order From Chat'),
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          body: ManualOrderScreen(
            initialSource: 'chat',
            lockSource: true,
            initialChatOrderId: _conversation.referenceId,
            initialPhone: _conversation.userPhone,
            initialDescription: description,
            initialUserId: int.tryParse(_conversation.userId),
            initialAddressId: _conversation.addressId,
          ),
        ),
      ),
    );

    if (!mounted) return;
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: _ChatAppBar(
          conversation: _conversation,
          onOpen: _conversation.isOpen ? null : () => _setStatus('open'),
          onClose: _conversation.isOpen ? () => _setStatus('closed') : null,
          onDelete: _deleteConversation,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _ConversationSummaryCard(
                conversation: _conversation,
                canCreateOrder: _canCreateOrderFromChat,
                selectionCount: _selectedMessageIds.length,
                onCreateOrder: _openCreateOrderFlow,
                onClearSelection: _clearSelection,
              ),
              Expanded(
                child: _MessageArea(
                  conversation: _conversation,
                  selectedMessageIds: _selectedMessageIds,
                  selectionMode: _selectedMessageIds.isNotEmpty,
                  onToggleMessageSelection: _toggleMessageSelection,
                ),
              ),
              _InputBar(controller: _msgCtrl, cubit: _cubit),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.conversation,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
  });

  final AdminChatConversation conversation;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final VoidCallback onDelete;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 63,
      backgroundColor: AppColors.card,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderLight),
      ),
      titleSpacing: 0,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(initials: _initials(conversation.userName)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextCustom(
                  text: conversation.userName,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  maxLines: 1,
                ),
                if (conversation.userPhone.isNotEmpty)
                  const SizedBox(height: 2),
                if (conversation.userPhone.isNotEmpty)
                  TextCustom(
                    text: conversation.userPhone,
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'open' && onOpen != null) onOpen!();
              if (value == 'closed' && onClose != null) onClose!();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              if (onOpen != null)
                const PopupMenuItem(value: 'open', child: Text('Mark as open')),
              if (onClose != null)
                const PopupMenuItem(
                  value: 'closed',
                  child: Text('Mark as closed'),
                ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversationSummaryCard extends StatelessWidget {
  const _ConversationSummaryCard({
    required this.conversation,
    required this.canCreateOrder,
    required this.selectionCount,
    required this.onCreateOrder,
    required this.onClearSelection,
  });

  final AdminChatConversation conversation;
  final bool canCreateOrder;
  final int selectionCount;
  final Future<void> Function() onCreateOrder;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final accentColor = conversation.isEmergencyTicket
        ? AppColors.error
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        4,
        AppSpacing.screenPadding,
        4,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  conversation.isEmergencyTicket
                      ? Icons.warning_amber_rounded
                      : Icons.shopping_bag_outlined,
                  color: accentColor,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: conversation.referenceId,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _HeaderChip(
                          label: conversation.typeLabel,
                          color: accentColor,
                        ),
                        _HeaderChip(
                          label: conversation.isOpen ? 'Open' : 'Closed',
                          color: conversation.isOpen
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        if (conversation.unreadByAdmin > 0)
                          _HeaderChip(
                            label: '${conversation.unreadByAdmin} unread',
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canCreateOrder) ...[
            const SizedBox(height: 5),
            if (selectionCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppRadius.round,
                            ),
                          ),
                          child: TextCustom(
                            text: '$selectionCount selected',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: TextCustom(
                            text: 'Use selected messages as description',
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onClearSelection,
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: onCreateOrder,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Use Selected'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: TextCustom(
                        text: 'Create order from this chat',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onCreateOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Create Order'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.round),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: TextCustom(
        text: label,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextCustom(
        text: initials,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _MessageArea extends StatelessWidget {
  const _MessageArea({
    required this.conversation,
    required this.selectedMessageIds,
    required this.selectionMode,
    required this.onToggleMessageSelection,
  });

  final AdminChatConversation conversation;
  final Set<String> selectedMessageIds;
  final bool selectionMode;
  final ValueChanged<ChatMessage> onToggleMessageSelection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/icons/chat_background.png',
            fit: BoxFit.cover,
          ),
        ),
        BlocBuilder<AdminChatRoomCubit, AdminChatRoomState>(
          builder: (context, state) => switch (state) {
            AdminChatRoomLoading() => const _LoadingView(),
            AdminChatRoomError(:final message) => _ErrorView(message: message),
            AdminChatRoomLoaded(:final messages) when messages.isEmpty =>
              const _EmptyView(),
            AdminChatRoomLoaded(:final messages) => _MessageList(
              messages: messages,
              selectedMessageIds: selectedMessageIds,
              selectionMode: selectionMode,
              onToggleMessageSelection: onToggleMessageSelection,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 30,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextCustom(
            text: message,
            fontSize: 14,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const TextCustom(
            text: 'No messages yet',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.selectedMessageIds,
    required this.selectionMode,
    required this.onToggleMessageSelection,
  });

  final List<ChatMessage> messages;
  final Set<String> selectedMessageIds;
  final bool selectionMode;
  final ValueChanged<ChatMessage> onToggleMessageSelection;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isMe = msg.isAdminMessage;
        final timeText = msg.createdAt == null
            ? ''
            : DateFormat('HH:mm').format(msg.createdAt!);
        final showDateChip = _shouldShowDateChip(messages, i);
        final dateText = msg.createdAt == null
            ? ''
            : _formatDateChip(msg.createdAt!);

        return Column(
          children: [
            if (showDateChip && dateText.isNotEmpty) _DateChip(label: dateText),
            _MessageBubble(
              isMe: isMe,
              message: msg,
              timeText: timeText,
              selected: selectedMessageIds.contains(msg.id),
              selectionMode: selectionMode,
              onToggleSelection: () => onToggleMessageSelection(msg),
            ),
          ],
        );
      },
    );
  }

  static bool _shouldShowDateChip(List<ChatMessage> msgs, int i) {
    if (i == msgs.length - 1) return true;
    final cur = msgs[i].createdAt;
    final prev = msgs[i + 1].createdAt;
    if (cur == null || prev == null) return false;
    return cur.year != prev.year ||
        cur.month != prev.month ||
        cur.day != prev.day;
  }

  static String _formatDateChip(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final d = DateUtils.dateOnly(date);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.cubit});

  final TextEditingController controller;
  final AdminChatRoomCubit cubit;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    await cubit.sendImage(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + bottomPadding,
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AttachButton(onTap: _pickImage),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _MessageTextField(controller: controller)),
            const SizedBox(width: AppSpacing.sm),
            BlocBuilder<AdminChatRoomCubit, AdminChatRoomState>(
              builder: (context, state) {
                final sending = state is AdminChatRoomLoaded && state.sending;
                return _SendButton(
                  sending: sending,
                  onTap: sending
                      ? null
                      : () {
                          cubit.sendText(controller.text);
                          controller.clear();
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: const Icon(
            Icons.attach_file_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _MessageTextField extends StatelessWidget {
  const _MessageTextField({required this.controller});

  final TextEditingController controller;

  static OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        fontSize: 14.5,
        color: AppColors.textPrimary,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: 'Type a message...',
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        isDense: true,
        border: _border(AppColors.surfaceVariant),
        enabledBorder: _border(AppColors.surfaceVariant),
        focusedBorder: _border(AppColors.primary, width: 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, width: 1.5),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onTap});

  final bool sending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: sending
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.primary,
                  ],
                ),
          color: sending ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          border: sending ? Border.all(color: AppColors.borderLight) : null,
          boxShadow: sending
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: sending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.borderLight)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.round),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow12, blurRadius: 4),
              ],
            ),
            child: TextCustom(
              text: label,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.borderLight)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isMe,
    required this.message,
    required this.timeText,
    required this.selected,
    required this.selectionMode,
    required this.onToggleSelection,
  });

  final bool isMe;
  final ChatMessage message;
  final String timeText;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onToggleSelection;

  bool get _isImage =>
      message.type == ChatMessageType.image &&
      (message.imageUrl ?? '').isNotEmpty;

  bool get _isLocation => message.type == ChatMessageType.location;

  bool get _isSelectableText =>
      message.type == ChatMessageType.text && (message.text ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isImage) {
      child = _ImageBubble(
        imageUrl: message.imageUrl!,
        timeText: timeText,
        isMe: isMe,
        isRead: message.readAt != null,
      );
    } else {
      final text = switch (message.type) {
        ChatMessageType.location =>
          message.text?.isNotEmpty == true ? message.text! : 'Location shared',
        ChatMessageType.system =>
          message.text?.isNotEmpty == true ? message.text! : 'System message',
        _ => message.text ?? '',
      };

      child = _TextBubble(
        text: _isLocation && text.isEmpty ? 'Location shared' : text,
        timeText: timeText,
        isMe: isMe,
        isRead: message.readAt != null,
        system: message.type == ChatMessageType.system,
      );
    }

    return GestureDetector(
      onLongPress: _isSelectableText ? onToggleSelection : null,
      onTap: selectionMode && _isSelectableText ? onToggleSelection : null,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.round),
                      ),
                      child: const TextCustom(
                        text: 'Selected',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.text,
    required this.timeText,
    required this.isMe,
    required this.isRead,
    this.system = false,
  });

  final String text;
  final String timeText;
  final bool isMe;
  final bool isRead;
  final bool system;

  static bool _isArabic(String s) {
    if (s.isEmpty) return false;
    final arabicCount = s.runes
        .where(
          (r) => (r >= 0x0600 && r <= 0x06FF) || (r >= 0xFB50 && r <= 0xFDFF),
        )
        .length;
    return arabicCount / s.length > 0.3;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = _isArabic(text);
    final background = system ? AppColors.surface : AppColors.card;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.only(left: 11, right: 11, top: 7, bottom: 5),
      decoration: BoxDecoration(
        gradient: isMe && !system
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.primary,
                ],
              )
            : null,
        color: isMe && !system ? null : background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border: isMe && !system
            ? null
            : Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: isMe && !system
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Directionality(
            textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Text(
              text,
              textAlign: rtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: isMe && !system ? Colors.white : AppColors.textPrimary,
                fontStyle: system ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: _Timestamp(timeText: timeText, isMe: isMe, isRead: isRead),
          ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.imageUrl,
    required this.timeText,
    required this.isMe,
    required this.isRead,
  });

  final String imageUrl;
  final String timeText;
  final bool isMe;
  final bool isRead;

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImageView(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                color: AppColors.surface,
                child: const Center(child: Icon(Icons.broken_image_rounded)),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.round),
                ),
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: _Timestamp(
                    timeText: timeText,
                    isMe: isMe,
                    isRead: isRead,
                    light: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenImageView extends StatelessWidget {
  const _FullscreenImageView({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
    );
  }
}

class _Timestamp extends StatelessWidget {
  const _Timestamp({
    required this.timeText,
    required this.isMe,
    required this.isRead,
    this.light = false,
  });

  final String timeText;
  final bool isMe;
  final bool isRead;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light
        ? Colors.white
        : isMe
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timeText, style: TextStyle(fontSize: 10, color: color)),
        if (isMe) ...[
          const SizedBox(width: 3),
          Icon(
            isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: light ? 12 : 13,
            color: color,
          ),
        ],
      ],
    );
  }
}
