import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:superdriver_admin/domain/models/notification_model.dart';
import 'package:superdriver_admin/modules/notification/cubit/notification_cubit.dart';
import 'package:superdriver_admin/modules/notification/cubit/notification_state.dart';
import 'package:superdriver_admin/modules/notification/notification_detail_screen.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit()..getNotifications(),
      child: const _NotificationsView(),
    );
  }
}

// ── Root view ─────────────────────────────────────────────────────────────────

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationCubit, NotificationState>(
      listener: _onStateChange,
      builder: (context, state) {
        final cubit = NotificationCubit.get(context);

        return switch (state) {
          NotificationsLoading() => const _LoadingView(),
          NotificationsError(:final message) => _ErrorView(
            message: message,
            onRetry: cubit.getNotifications,
          ),
          _ when cubit.notifications.isEmpty => _EmptyView(
            onRefresh: cubit.getNotifications,
          ),
          _ => _NotificationsList(cubit: cubit),
        };
      },
    );
  }

  void _onStateChange(BuildContext context, NotificationState state) {
    if (state is! MarkReadSuccess) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.done_all_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'All marked as read',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.screenPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ── Notifications list ────────────────────────────────────────────────────────

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.cubit});

  final NotificationCubit cubit;

  int get _unreadCount => cubit.notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_unreadCount > 0)
          _UnreadBanner(count: _unreadCount, onMarkAll: cubit.markAllAsRead),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: cubit.getNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              itemCount: cubit.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = cubit.notifications[i];
                return _NotificationCard(
                  notification: n,
                  onTap: () => _openDetail(context, n),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, NotificationModel n) {
    if (!n.isRead) cubit.markAsRead(n.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notificationId: n.id),
      ),
    ).then((_) => cubit.getNotifications());
  }
}

// ── Unread banner ─────────────────────────────────────────────────────────────

class _UnreadBanner extends StatelessWidget {
  const _UnreadBanner({required this.count, required this.onMarkAll});

  final int count;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          _UnreadBadge(count: count),
          const SizedBox(width: 8),
          const TextCustom(
            text: 'unread',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onMarkAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(
              Icons.done_all_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            label: const TextCustom(
              text: 'Mark all read',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final meta = NotificationMeta.from(notification.notificationType);

    return Material(
      color: isRead ? AppColors.card : AppColors.primarySurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isRead
                  ? AppColors.borderLight
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationTypeBadge(meta: meta),
              const SizedBox(width: 12),
              Expanded(
                child: _CardBody(notification: notification, meta: meta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.notification, required this.meta});

  final NotificationModel notification;
  final NotificationMeta meta;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextCustom(
                text: notification.title,
                fontSize: 14,
                fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
                color: AppColors.textPrimary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isRead) ...[const SizedBox(width: 8), const _UnreadDot()],
          ],
        ),
        const SizedBox(height: 4),
        TextCustom(
          text: notification.body,
          fontSize: 12.5,
          color: AppColors.textSecondary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            NotificationTypeChip(meta: meta),
            const Spacer(),
            Icon(
              Icons.access_time_rounded,
              size: 12,
              color: AppColors.textTertiary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 3),
            TextCustom(
              text: formatNotificationDate(notification.createdAt),
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Shared notification widgets (also used in detail screen) ──────────────────

class NotificationTypeBadge extends StatelessWidget {
  const NotificationTypeBadge({super.key, required this.meta});

  final NotificationMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(meta.icon, color: meta.color, size: 22),
    );
  }
}

class NotificationTypeChip extends StatelessWidget {
  const NotificationTypeChip({super.key, required this.meta});

  final NotificationMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: meta.color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  static Widget _bone({
    required double height,
    double? width,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bone(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 160, height: 14),
                const SizedBox(height: 8),
                _bone(width: double.infinity, height: 12),
                const SizedBox(height: 4),
                _bone(width: 120, height: 12),
                const SizedBox(height: 10),
                _bone(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const TextCustom(
              text: 'No notifications yet',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            const TextCustom(
              text: "You're all caught up!",
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const TextCustom(
              text: 'Something went wrong',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 6),
            TextCustom(
              text: message,
              fontSize: 13,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification metadata ─────────────────────────────────────────────────────

class NotificationMeta {
  const NotificationMeta({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  factory NotificationMeta.from(String type) => switch (type) {
    'new_order_for_admin' || 'order_placed' => const NotificationMeta(
      icon: Icons.shopping_bag_outlined,
      color: AppColors.primary,
      label: 'New Order',
    ),
    'order_accepted' || 'order_preparing' => const NotificationMeta(
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      label: 'In Progress',
    ),
    'order_delivered' => const NotificationMeta(
      icon: Icons.local_shipping_outlined,
      color: AppColors.success,
      label: 'Delivered',
    ),
    'order_cancelled' => const NotificationMeta(
      icon: Icons.cancel_outlined,
      color: AppColors.error,
      label: 'Cancelled',
    ),
    'manual_order' => const NotificationMeta(
      icon: Icons.add_circle_outline,
      color: AppColors.primary,
      label: 'Manual Order',
    ),
    'driver_assigned' => const NotificationMeta(
      icon: Icons.delivery_dining,
      color: AppColors.info,
      label: 'Driver',
    ),
    'promotion' => const NotificationMeta(
      icon: Icons.campaign_outlined,
      color: Color(0xFFE67E22),
      label: 'Promotion',
    ),
    _ => const NotificationMeta(
      icon: Icons.notifications_outlined,
      color: AppColors.info,
      label: 'General',
    ),
  };
}

// ── Date formatting ───────────────────────────────────────────────────────────

String formatNotificationDate(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d, yyyy').format(date);
}
