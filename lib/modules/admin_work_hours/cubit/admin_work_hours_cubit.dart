import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/data/env/end_points.dart';
import 'package:superdriver_admin/domain/models/admin_work_hours.dart';

import 'admin_work_hours_state.dart';

class AdminWorkHoursCubit extends Cubit<AdminWorkHoursState> {
  AdminWorkHoursCubit() : super(AdminWorkHoursLoading());

  static AdminWorkHoursCubit get(BuildContext context) =>
      BlocProvider.of(context);

  static const _timeout = Duration(seconds: 15);

  String? get _token =>
      locator<SharedPreferencesRepository>().getData(key: 'access_token');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  AdminWorkStatus? _statusCache;
  AdminWorkStats? _summaryCache;
  AdminWorkRangeStats? _rangeCache;
  List<AdminWorkLog> _logsCache = <AdminWorkLog>[];
  AdminWorkHoursScope _scope = AdminWorkHoursScope.today;
  DateTime? _selectedDate;
  DateTimeRange? _selectedRange;
  DateTime _logsDate = DateTime.now();

  Future<void> initialize() async {
    if (_token == null) {
      emit(AdminWorkHoursError('Not logged in'));
      return;
    }

    emit(AdminWorkHoursLoading());

    try {
      final results = await Future.wait([
        _fetchStatus(),
        _fetchTodayStats(),
        _fetchLogs(_logsDate),
      ]);

      _statusCache = results[0] as AdminWorkStatus;
      _summaryCache = results[1] as AdminWorkStats;
      _logsCache = results[2] as List<AdminWorkLog>;
      _scope = AdminWorkHoursScope.today;
      _rangeCache = null;
      _selectedDate = null;
      _selectedRange = null;

      _emitLoaded();
    } catch (e) {
      emit(AdminWorkHoursError(e.toString()));
    }
  }

  Future<void> toggleOnlineStatus() async {
    if (_token == null) {
      emit(AdminWorkHoursError('Not logged in'));
      return;
    }

    final current = _currentLoadedState;
    if (current == null) return;

    emit(current.copyWith(isToggling: true, clearNotice: true));

    try {
      final endpoint = current.status.isOnline
          ? ConstantsService.adminGoOfflineEndpoint
          : ConstantsService.adminGoOnlineEndpoint;

      final response = await http
          .post(Uri.parse(endpoint), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to update status (${response.statusCode})');
      }

      final actionStatus = AdminWorkStatus.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      _statusCache = actionStatus;
      _summaryCache = await _resolveSummaryForCurrentScope();
      _logsCache = await _fetchLogs(_logsDate);

      _emitLoaded(notice: actionStatus.message ?? 'Status updated');
    } catch (e) {
      emit(current.copyWith(isToggling: false, notice: e.toString()));
    }
  }

  Future<void> loadToday() async {
    await _loadSummaryScope(
      scope: AdminWorkHoursScope.today,
      loader: _fetchTodayStats,
      clearDate: true,
      clearRange: true,
    );
  }

  Future<void> loadDaily(DateTime date) async {
    _selectedDate = date;
    await _loadSummaryScope(
      scope: AdminWorkHoursScope.daily,
      loader: () => _fetchDailyStats(date),
      clearRange: true,
    );
  }

  Future<void> loadRange(DateTimeRange range) async {
    final current = _currentLoadedState;
    if (current == null) return;

    emit(current.copyWith(clearNotice: true));

    try {
      _selectedRange = range;
      _scope = AdminWorkHoursScope.range;
      _rangeCache = await _fetchRangeStats(range);
      _summaryCache = AdminWorkStats(
        date:
            '${DateFormat('yyyy-MM-dd').format(range.start)} -> ${DateFormat('yyyy-MM-dd').format(range.end)}',
        totalHours: _rangeCache!.totalHours,
        formattedHours: _rangeCache!.formattedTotal,
        totalOnlineSeconds: _rangeCache!.totalSeconds,
        totalSessions: _rangeCache!.totalSessions,
      );

      _emitLoaded();
    } catch (e) {
      emit(current.copyWith(notice: e.toString()));
    }
  }

  Future<void> loadLogsForDate(DateTime date) async {
    final current = _currentLoadedState;
    if (current == null) return;

    emit(current.copyWith(clearNotice: true));

    try {
      _logsDate = date;
      _logsCache = await _fetchLogs(date);
      _emitLoaded();
    } catch (e) {
      emit(current.copyWith(notice: e.toString()));
    }
  }

  Future<void> _loadSummaryScope({
    required AdminWorkHoursScope scope,
    required Future<AdminWorkStats> Function() loader,
    bool clearDate = false,
    bool clearRange = false,
  }) async {
    final current = _currentLoadedState;
    if (current == null) return;

    emit(current.copyWith(clearNotice: true));

    try {
      _scope = scope;
      _summaryCache = await loader();
      if (clearDate) _selectedDate = null;
      if (clearRange) _selectedRange = null;
      if (clearRange) _rangeCache = null;
      _emitLoaded();
    } catch (e) {
      emit(current.copyWith(notice: e.toString()));
    }
  }

  Future<AdminWorkStats> _resolveSummaryForCurrentScope() {
    return switch (_scope) {
      AdminWorkHoursScope.today => _fetchTodayStats(),
      AdminWorkHoursScope.daily => _fetchDailyStats(_selectedDate ?? DateTime.now()),
      AdminWorkHoursScope.range => Future.value(
        AdminWorkStats(
          date: _summaryCache?.date ?? '',
          totalHours: _rangeCache?.totalHours ?? 0,
          formattedHours: _rangeCache?.formattedTotal ?? '',
          totalOnlineSeconds: _rangeCache?.totalSeconds ?? 0,
          totalSessions: _rangeCache?.totalSessions ?? 0,
        ),
      ),
    };
  }

  Future<AdminWorkStatus> _fetchStatus() async {
    final response = await http
        .get(Uri.parse(ConstantsService.adminStatusEndpoint), headers: _headers)
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load status (${response.statusCode})');
    }

    return AdminWorkStatus.fromJson(jsonDecode(response.body));
  }

  Future<AdminWorkStats> _fetchTodayStats() async {
    final response = await http
        .get(Uri.parse(ConstantsService.adminStatsTodayEndpoint), headers: _headers)
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load today stats (${response.statusCode})');
    }

    return AdminWorkStats.fromJson(jsonDecode(response.body));
  }

  Future<AdminWorkStats> _fetchDailyStats(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final response = await http
        .get(
          Uri.parse(ConstantsService.adminStatsDailyEndpoint(formatted)),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load daily stats (${response.statusCode})');
    }

    return AdminWorkStats.fromJson(jsonDecode(response.body));
  }

  Future<AdminWorkRangeStats> _fetchRangeStats(DateTimeRange range) async {
    final startDate = DateFormat('yyyy-MM-dd').format(range.start);
    final endDate = DateFormat('yyyy-MM-dd').format(range.end);

    final response = await http
        .get(
          Uri.parse(ConstantsService.adminStatsRangeEndpoint(startDate, endDate)),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load range stats (${response.statusCode})');
    }

    return AdminWorkRangeStats.fromJson(jsonDecode(response.body));
  }

  Future<List<AdminWorkLog>> _fetchLogs(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final response = await http
        .get(Uri.parse(ConstantsService.adminLogsEndpoint(formatted)), headers: _headers)
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load logs (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawLogs = body['logs'];

    if (rawLogs is! List) return <AdminWorkLog>[];

    return rawLogs
        .whereType<Map>()
        .map((e) => AdminWorkLog.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  AdminWorkHoursLoaded? get _currentLoadedState {
    final current = state;
    return current is AdminWorkHoursLoaded ? current : null;
  }

  void _emitLoaded({String? notice}) {
    final status = _statusCache;
    final summary = _summaryCache;
    if (status == null || summary == null) {
      emit(AdminWorkHoursError('Work hours data is incomplete'));
      return;
    }

    emit(
      AdminWorkHoursLoaded(
        status: status,
        summaryStats: summary,
        logs: _logsCache,
        scope: _scope,
        rangeStats: _rangeCache,
        selectedDate: _selectedDate,
        selectedRange: _selectedRange,
        logsDate: _logsDate,
        notice: notice,
      ),
    );
  }
}
