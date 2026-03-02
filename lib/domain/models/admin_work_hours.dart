class AdminActiveSession {
  final String startedAt;
  final String duration;

  AdminActiveSession({required this.startedAt, required this.duration});

  factory AdminActiveSession.fromJson(Map<String, dynamic> json) {
    return AdminActiveSession(
      startedAt: (json['started_at'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
    );
  }
}

class AdminWorkStatus {
  final bool isOnline;
  final String? lastOnline;
  final AdminActiveSession? activeSession;
  final String? message;

  AdminWorkStatus({
    required this.isOnline,
    this.lastOnline,
    this.activeSession,
    this.message,
  });

  factory AdminWorkStatus.fromJson(Map<String, dynamic> json) {
    final activeSessionJson = json['active_session'];

    return AdminWorkStatus(
      isOnline: json['is_online'] == true,
      lastOnline: json['last_online']?.toString(),
      activeSession: activeSessionJson is Map<String, dynamic>
          ? AdminActiveSession.fromJson(activeSessionJson)
          : null,
      message: json['message']?.toString(),
    );
  }
}

class AdminWorkStats {
  final String date;
  final double totalHours;
  final String formattedHours;
  final int totalOnlineSeconds;
  final int totalSessions;
  final String? firstOnline;
  final String? lastOffline;
  final bool? isCurrentlyOnline;

  AdminWorkStats({
    required this.date,
    required this.totalHours,
    required this.formattedHours,
    required this.totalOnlineSeconds,
    required this.totalSessions,
    this.firstOnline,
    this.lastOffline,
    this.isCurrentlyOnline,
  });

  factory AdminWorkStats.fromJson(Map<String, dynamic> json) {
    return AdminWorkStats(
      date: (json['date'] ?? '').toString(),
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
      formattedHours: (json['formatted_hours'] ?? '').toString(),
      totalOnlineSeconds: json['total_online_seconds'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      firstOnline: json['first_online']?.toString(),
      lastOffline: json['last_offline']?.toString(),
      isCurrentlyOnline: json['is_currently_online'] is bool
          ? json['is_currently_online'] as bool
          : null,
    );
  }
}

class AdminWorkDailyStat {
  final String date;
  final double totalHours;
  final String formattedHours;
  final int totalOnlineSeconds;
  final int totalSessions;
  final String? firstOnline;
  final String? lastOffline;

  AdminWorkDailyStat({
    required this.date,
    required this.totalHours,
    required this.formattedHours,
    required this.totalOnlineSeconds,
    required this.totalSessions,
    this.firstOnline,
    this.lastOffline,
  });

  factory AdminWorkDailyStat.fromJson(Map<String, dynamic> json) {
    return AdminWorkDailyStat(
      date: (json['date'] ?? '').toString(),
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
      formattedHours: (json['formatted_hours'] ?? '').toString(),
      totalOnlineSeconds: json['total_online_seconds'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      firstOnline: json['first_online']?.toString(),
      lastOffline: json['last_offline']?.toString(),
    );
  }
}

class AdminWorkRangeStats {
  final String startDate;
  final String endDate;
  final double totalHours;
  final String formattedTotal;
  final int totalSeconds;
  final int totalSessions;
  final int daysCount;
  final List<AdminWorkDailyStat> dailyStats;

  AdminWorkRangeStats({
    required this.startDate,
    required this.endDate,
    required this.totalHours,
    required this.formattedTotal,
    required this.totalSeconds,
    required this.totalSessions,
    required this.daysCount,
    required this.dailyStats,
  });

  factory AdminWorkRangeStats.fromJson(Map<String, dynamic> json) {
    final rawStats = json['daily_stats'];

    return AdminWorkRangeStats(
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
      formattedTotal: (json['formatted_total'] ?? '').toString(),
      totalSeconds: json['total_seconds'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      daysCount: json['days_count'] as int? ?? 0,
      dailyStats: rawStats is List
          ? rawStats
                .whereType<Map>()
                .map((e) => AdminWorkDailyStat.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <AdminWorkDailyStat>[],
    );
  }
}

class AdminWorkLog {
  final int id;
  final String status;
  final String timestamp;

  AdminWorkLog({
    required this.id,
    required this.status,
    required this.timestamp,
  });

  factory AdminWorkLog.fromJson(Map<String, dynamic> json) {
    return AdminWorkLog(
      id: json['id'] as int? ?? 0,
      status: (json['status'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? '').toString(),
    );
  }
}
