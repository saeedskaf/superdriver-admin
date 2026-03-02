import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:superdriver_admin/domain/models/admin_chat_conversation.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

import 'admin_chat_room_screen.dart';
import 'cubit/admin_chats_cubit.dart';
import 'cubit/admin_chats_state.dart';

class AdminChatsScreen extends StatelessWidget {
  const AdminChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminChatsCubit()..start(),
      child: BlocBuilder<AdminChatsCubit, AdminChatsState>(
        builder: (context, state) {
          if (state is AdminChatsLoading) return const _LoadingView();
          if (state is AdminChatsError) {
            return _ErrorView(message: state.message);
          }
          if (state is AdminChatsLoaded) {
            if (state.conversations.isEmpty) return const _EmptyView();
            return _ChatList(conversations: state.conversations);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.conversations});

  final List<AdminChatConversation> conversations;

  @override
  Widget build(BuildContext context) {
    final unreadCount = conversations.fold<int>(0, (sum, item) {
      return sum + item.unreadByAdmin;
    });
    final openCount = conversations.where((item) => item.isOpen).length;
    final emergencyCount = conversations
        .where((item) => item.isEmergencyTicket)
        .length;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/icons/chat_background.png',
            fit: BoxFit.cover,
            color: Colors.white.withValues(alpha: 0.94),
            colorBlendMode: BlendMode.lighten,
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          itemCount: conversations.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ChatsOverview(
                  totalCount: conversations.length,
                  unreadCount: unreadCount,
                  openCount: openCount,
                  emergencyCount: emergencyCount,
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: i == conversations.length ? 0 : AppSpacing.sm,
              ),
              child: _ChatTile(conversation: conversations[i - 1]),
            );
          },
        ),
      ],
    );
  }
}

class _ChatsOverview extends StatelessWidget {
  const _ChatsOverview({
    required this.totalCount,
    required this.unreadCount,
    required this.openCount,
    required this.emergencyCount,
  });

  final int totalCount;
  final int unreadCount;
  final int openCount;
  final int emergencyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.96),
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextCustom(
            text: 'Conversation Inbox',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          TextCustom(
            text:
                '$totalCount active threads across orders, issues, and live replies.',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Unread',
                  value: '$unreadCount',
                  icon: Icons.mark_chat_unread_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewStat(
                  label: 'Open',
                  value: '$openCount',
                  icon: Icons.folder_open_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewStat(
                  label: 'Emergency',
                  value: '$emergencyCount',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 8),
          TextCustom(
            text: value,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          TextCustom(
            text: label,
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.conversation});

  final AdminChatConversation conversation;

  Color get _accentColor {
    if (conversation.isEmergencyTicket) return AppColors.error;
    if (conversation.isOrderRequest) return AppColors.warning;
    return AppColors.info;
  }

  Color get _softSurface {
    if (conversation.isEmergencyTicket) return AppColors.errorBg;
    if (conversation.isOrderRequest) return AppColors.infoSurface;
    return AppColors.warningBg;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 24) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadByAdmin > 0;
    final lastAt = conversation.sortAt;
    final lastMessage = conversation.lastMessage.isEmpty
        ? 'No messages yet'
        : conversation.lastMessage;
    final accentColor = _accentColor;
    final softSurface = _softSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminChatRoomScreen(conversation: conversation),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasUnread
                  ? [accentColor.withValues(alpha: 0.08), AppColors.card]
                  : [AppColors.card, softSurface.withValues(alpha: 0.32)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: hasUnread
                  ? accentColor.withValues(alpha: 0.24)
                  : accentColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: hasUnread
                    ? accentColor.withValues(alpha: 0.1)
                    : AppColors.shadow12,
                blurRadius: hasUnread ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 86,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppRadius.round),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _GradientAvatar(
                initials: _initials(conversation.userName),
                primaryColor: accentColor,
                secondaryColor: hasUnread
                    ? accentColor.withValues(alpha: 0.78)
                    : accentColor.withValues(alpha: 0.62),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextCustom(
                            text: conversation.userName,
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                            maxLines: 1,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        if (lastAt != null)
                          TextCustom(
                            text: _formatTime(lastAt),
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: hasUnread
                                ? accentColor
                                : AppColors.textTertiary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          label: conversation.referenceId,
                          color: accentColor,
                          light: true,
                        ),
                        _MetaChip(
                          label: conversation.typeLabel,
                          color: accentColor,
                          light: true,
                        ),
                        _MetaChip(
                          label: conversation.isOpen ? 'Open' : 'Closed',
                          color: conversation.isOpen
                              ? AppColors.success
                              : AppColors.textSecondary,
                          light: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (conversation.isOrderRequest &&
                        (conversation.addressTitle ?? '').isNotEmpty)
                      TextCustom(
                        text: conversation.addressTitle!,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (conversation.isEmergencyTicket &&
                        (conversation.issueLabel ?? '').isNotEmpty)
                      TextCustom(
                        text: conversation.issueLabel!,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (conversation.lastMessageBy == 'admin')
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: TextCustom(
                              text: 'You: ',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        Expanded(
                          child: TextCustom(
                            text: lastMessage,
                            fontSize: 12,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasUnread)
                    _UnreadBadge(count: conversation.unreadByAdmin),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    this.light = false,
  });

  final String label;
  final Color color;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: light ? color.withValues(alpha: 0.08) : color,
        borderRadius: BorderRadius.circular(AppRadius.round),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: TextCustom(
        text: label,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: light ? color : Colors.white,
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({
    required this.initials,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String initials;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [secondaryColor, primaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.24),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextCustom(
        text: initials,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.round),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextCustom(
        text: count > 99 ? '99+' : '$count',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: TextCustom(
          text: message,
          fontSize: 14,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
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
            text: 'No conversations yet',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
