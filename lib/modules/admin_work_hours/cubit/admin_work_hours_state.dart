import 'package:flutter/material.dart';
import 'package:superdriver_admin/domain/models/admin_work_hours.dart';

enum AdminWorkHoursScope { today, daily, range }

abstract class AdminWorkHoursState {}

class AdminWorkHoursLoading extends AdminWorkHoursState {}

class AdminWorkHoursLoaded extends AdminWorkHoursState {
  AdminWorkHoursLoaded({
    required this.status,
    required this.summaryStats,
    required this.logs,
    required this.scope,
    this.rangeStats,
    this.selectedDate,
    this.selectedRange,
    this.logsDate,
    this.isToggling = false,
    this.notice,
  });

  final AdminWorkStatus status;
  final AdminWorkStats summaryStats;
  final List<AdminWorkLog> logs;
  final AdminWorkHoursScope scope;
  final AdminWorkRangeStats? rangeStats;
  final DateTime? selectedDate;
  final DateTimeRange? selectedRange;
  final DateTime? logsDate;
  final bool isToggling;
  final String? notice;

  AdminWorkHoursLoaded copyWith({
    AdminWorkStatus? status,
    AdminWorkStats? summaryStats,
    List<AdminWorkLog>? logs,
    AdminWorkHoursScope? scope,
    AdminWorkRangeStats? rangeStats,
    bool clearRangeStats = false,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    DateTimeRange? selectedRange,
    bool clearSelectedRange = false,
    DateTime? logsDate,
    bool isToggling = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return AdminWorkHoursLoaded(
      status: status ?? this.status,
      summaryStats: summaryStats ?? this.summaryStats,
      logs: logs ?? this.logs,
      scope: scope ?? this.scope,
      rangeStats: clearRangeStats ? null : (rangeStats ?? this.rangeStats),
      selectedDate: clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      selectedRange: clearSelectedRange
          ? null
          : (selectedRange ?? this.selectedRange),
      logsDate: logsDate ?? this.logsDate,
      isToggling: isToggling,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

class AdminWorkHoursError extends AdminWorkHoursState {
  AdminWorkHoursError(this.message);

  final String message;
}
