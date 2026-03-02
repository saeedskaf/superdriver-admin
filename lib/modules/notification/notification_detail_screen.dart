import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:superdriver_admin/domain/models/notification_model.dart';
import 'package:superdriver_admin/modules/notification/cubit/notification_cubit.dart';
import 'package:superdriver_admin/modules/notification/cubit/notification_state.dart';
import 'package:superdriver_admin/modules/notification/notification_screen.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});

  final int notificationId;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late final NotificationCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NotificationCubit()..getNotificationDetail(widget.notificationId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const TextCustom(
            text: 'Notification',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) => switch (state) {
            NotificationDetailLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            NotificationDetailError(:final message) => _ErrorView(
              message: message,
              onRetry: () =>
                  _cubit.getNotificationDetail(widget.notificationId),
            ),
            NotificationDetailLoaded(:final notification) => _DetailContent(
              notification: notification,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

// ── Detail content ────────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final meta = NotificationMeta.from(notification.notificationType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeHeader(meta: meta),
          const SizedBox(height: AppSpacing.xl),
          _InfoCard(
            label: 'Title',
            child: TextCustom(
              text: notification.title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            label: 'Message',
            child: TextCustom(
              text: notification.body,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TimestampCard(createdAt: notification.createdAt),
        ],
      ),
    );
  }
}

// ── Type header ───────────────────────────────────────────────────────────────

class _TypeHeader extends StatelessWidget {
  const _TypeHeader({required this.meta});

  final NotificationMeta meta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.icon, size: 40, color: meta.color),
          ),
          const SizedBox(height: AppSpacing.md),
          NotificationTypeChip(meta: meta),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(text: label, fontSize: 12, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.xxs),
          child,
        ],
      ),
    );
  }
}

// ── Timestamp card ────────────────────────────────────────────────────────────

class _TimestampCard extends StatelessWidget {
  const _TimestampCard({required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: AppSizes.iconSm,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.xs),
          TextCustom(
            text: DateFormat('yyyy/MM/dd  hh:mm a').format(createdAt),
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ],
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
                Icons.error_outline_rounded,
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
