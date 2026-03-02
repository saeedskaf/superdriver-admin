import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:superdriver_admin/domain/models/admin_work_hours.dart';
import 'package:superdriver_admin/modules/admin_work_hours/cubit/admin_work_hours_cubit.dart';
import 'package:superdriver_admin/modules/admin_work_hours/cubit/admin_work_hours_state.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

class AdminWorkHoursScreen extends StatefulWidget {
  const AdminWorkHoursScreen({super.key});

  @override
  State<AdminWorkHoursScreen> createState() => _AdminWorkHoursScreenState();
}

class _AdminWorkHoursScreenState extends State<AdminWorkHoursScreen> {
  late final AdminWorkHoursCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AdminWorkHoursCubit()..initialize();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickDailyDate() async {
    final initial = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.subtract(const Duration(days: 365)),
      lastDate: initial,
    );

    if (date == null || !mounted) return;
    await _cubit.loadDaily(date);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
    );

    if (range == null || !mounted) return;
    await _cubit.loadRange(range);
  }

  Future<void> _pickLogsDate(DateTime current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: current.subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;
    await _cubit.loadLogsForDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AdminWorkHoursCubit, AdminWorkHoursState>(
        listener: (context, state) {
          if (state is AdminWorkHoursLoaded &&
              state.notice != null &&
              state.notice!.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.notice!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          AdminWorkHoursLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          AdminWorkHoursError(:final message) => _ErrorView(
            message: message,
            onRetry: _cubit.initialize,
          ),
          AdminWorkHoursLoaded() => _ContentView(
            state: state,
            cubit: _cubit,
            onPickDailyDate: _pickDailyDate,
            onPickRange: _pickRange,
            onPickLogsDate: _pickLogsDate,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _WorkHoursFormat {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • hh:mm a');

  static String dateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _dateTimeFormat.format(parsed.toLocal());
  }

  static String dateFromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _dateFormat.format(parsed);
  }

  static String date(DateTime? value) {
    if (value == null) return '-';
    return _dateFormat.format(value);
  }

  static String dateRange(DateTimeRange? value) {
    if (value == null) return 'Selected Range';
    return '${date(value.start)} -> ${date(value.end)}';
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView({
    required this.state,
    required this.cubit,
    required this.onPickDailyDate,
    required this.onPickRange,
    required this.onPickLogsDate,
  });

  final AdminWorkHoursLoaded state;
  final AdminWorkHoursCubit cubit;
  final Future<void> Function() onPickDailyDate;
  final Future<void> Function() onPickRange;
  final Future<void> Function(DateTime current) onPickLogsDate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: cubit.initialize,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(
              status: state.status,
              isToggling: state.isToggling,
              onToggle: cubit.toggleOnlineStatus,
            ),
            const SizedBox(height: AppSpacing.md),
            _ScopeCard(
              state: state,
              onToday: cubit.loadToday,
              onDaily: onPickDailyDate,
              onRange: onPickRange,
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryCard(state: state),
            if (state.scope == AdminWorkHoursScope.range &&
                state.rangeStats != null &&
                state.rangeStats!.dailyStats.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _RangeBreakdownCard(rangeStats: state.rangeStats!),
            ],
            const SizedBox(height: AppSpacing.md),
            _LogsCard(
              logs: state.logs,
              logsDate: state.logsDate ?? DateTime.now(),
              onPickDate: () => onPickLogsDate(state.logsDate ?? DateTime.now()),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.isToggling,
    required this.onToggle,
  });

  final AdminWorkStatus status;
  final bool isToggling;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final isOnline = status.isOnline;
    final accent = isOnline ? AppColors.success : AppColors.textSecondary;
    final bg = isOnline ? AppColors.successSurface : AppColors.surfaceVariant;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionBadge(
                icon: isOnline ? Icons.radio_button_checked : Icons.pause_circle,
                color: accent,
                background: bg,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: isOnline ? 'You are Online' : 'You are Offline',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    if ((status.lastOnline ?? '').isNotEmpty)
                      TextCustom(
                        text:
                            'Last online: ${_WorkHoursFormat.dateTime(status.lastOnline)}',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: ElevatedButton(
                  onPressed: isToggling ? null : onToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline
                        ? AppColors.textSecondary
                        : AppColors.success,
                    minimumSize: const Size(118, 42),
                  ),
                  child: isToggling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isOnline ? 'Go Offline' : 'Go Online'),
                ),
              ),
            ],
          ),
          if (status.activeSession != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _InfoMetric(
                    label: 'Started At',
                    value: _WorkHoursFormat.dateTime(
                      status.activeSession!.startedAt,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoMetric(
                    label: 'Current Session',
                    value: status.activeSession!.duration,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.state,
    required this.onToday,
    required this.onDaily,
    required this.onRange,
  });

  final AdminWorkHoursLoaded state;
  final Future<void> Function() onToday;
  final Future<void> Function() onDaily;
  final Future<void> Function() onRange;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.analytics_outlined,
            title: 'Statistics Scope',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ScopeButton(
                  label: 'Today',
                  selected: state.scope == AdminWorkHoursScope.today,
                  onTap: onToday,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScopeButton(
                  label: 'Daily',
                  selected: state.scope == AdminWorkHoursScope.daily,
                  onTap: onDaily,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScopeButton(
                  label: 'Range',
                  selected: state.scope == AdminWorkHoursScope.range,
                  onTap: onRange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final AdminWorkHoursLoaded state;

  @override
  Widget build(BuildContext context) {
    final stats = state.summaryStats;
    final rangeStats = state.rangeStats;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.access_time_rounded,
            title: 'Summary',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScopeLabel(state: state),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Hours',
                  value: state.scope == AdminWorkHoursScope.range
                      ? rangeStats?.formattedTotal ?? stats.formattedHours
                      : stats.formattedHours,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryMetric(
                  label: 'Sessions',
                  value: '${stats.totalSessions}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'First Online',
                  value: _WorkHoursFormat.dateTime(stats.firstOnline),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryMetric(
                  label: 'Last Offline',
                  value: _WorkHoursFormat.dateTime(stats.lastOffline),
                ),
              ),
            ],
          ),
          if (state.scope == AdminWorkHoursScope.range && rangeStats != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _SummaryMetric(label: 'Days Count', value: '${rangeStats.daysCount}'),
          ],
        ],
      ),
    );
  }
}

class _RangeBreakdownCard extends StatelessWidget {
  const _RangeBreakdownCard({required this.rangeStats});

  final AdminWorkRangeStats rangeStats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.calendar_view_week_outlined,
            title: 'Daily Breakdown',
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(
            rangeStats.dailyStats.length,
            (index) => _DailyStatTile(
              stat: rangeStats.dailyStats[index],
              isLast: index == rangeStats.dailyStats.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogsCard extends StatelessWidget {
  const _LogsCard({
    required this.logs,
    required this.logsDate,
    required this.onPickDate,
  });

  final List<AdminWorkLog> logs;
  final DateTime logsDate;
  final Future<void> Function() onPickDate;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _WorkHoursFormat.date(logsDate);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.timeline_rounded,
                  title: 'On/Off Logs',
                ),
              ),
              TextButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.date_range, size: AppSizes.iconSm),
                label: Text(dateLabel),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const TextCustom(
                text: 'No logs found for this date.',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...List.generate(
              logs.length,
              (index) => _LogTile(
                log: logs[index],
                isLast: index == logs.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyStatTile extends StatelessWidget {
  const _DailyStatTile({required this.stat, required this.isLast});

  final AdminWorkDailyStat stat;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextCustom(
                text: _WorkHoursFormat.dateFromString(stat.date),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextCustom(
              text: stat.formattedHours,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.isLast});

  final AdminWorkLog log;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isOnline = log.status == 'online';
    final color = isOnline ? AppColors.success : AppColors.textSecondary;
    final bg = isOnline ? AppColors.successSurface : AppColors.surfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            _SectionBadge(
              icon: isOnline ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              background: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextCustom(
                text: isOnline ? 'Online' : 'Offline',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextCustom(
              text: _WorkHoursFormat.dateTime(log.timestamp),
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeLabel extends StatelessWidget {
  const _ScopeLabel({required this.state});

  final AdminWorkHoursLoaded state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.scope) {
      AdminWorkHoursScope.today => 'Today',
      AdminWorkHoursScope.daily => state.selectedDate == null
          ? 'Selected Day'
          : _WorkHoursFormat.date(state.selectedDate),
      AdminWorkHoursScope.range => _WorkHoursFormat.dateRange(
          state.selectedRange,
        ),
    };

    return TextCustom(
      text: label,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            text: label,
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          TextCustom(
            text: value,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(text: label, fontSize: 11, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          TextCustom(
            text: value,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: TextCustom(
              text: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SectionBadge(
          icon: icon,
          color: AppColors.primary,
          background: AppColors.primarySurface,
        ),
        const SizedBox(width: AppSpacing.sm),
        TextCustom(
          text: title,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

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
      child: child,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppSizes.iconLg,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            TextCustom(
              text: message,
              fontSize: 14,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
