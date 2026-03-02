class ConstantsService {
  static const String baseUrl = 'https://dashboard.superdriverapp.com';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String loginEndpoint = '$baseUrl/api/auth/login/';
  static const String adminGoOnlineEndpoint =
      '$baseUrl/api/auth/admin/go-online/';
  static const String adminGoOfflineEndpoint =
      '$baseUrl/api/auth/admin/go-offline/';
  static const String adminStatusEndpoint = '$baseUrl/api/auth/admin/status/';
  static const String adminStatsTodayEndpoint =
      '$baseUrl/api/auth/admin/stats/today/';

  static String adminStatsDailyEndpoint(String date) =>
      '$baseUrl/api/auth/admin/stats/daily/?date=$date';

  static String adminStatsRangeEndpoint(String startDate, String endDate) =>
      '$baseUrl/api/auth/admin/stats/range/?start_date=$startDate&end_date=$endDate';

  static String adminLogsEndpoint(String date) =>
      '$baseUrl/api/auth/admin/logs/?date=$date';

  // ── Admin Orders ──────────────────────────────────────────────────────────
  static const String newOrdersEndpoint =
      '$baseUrl/api/orders/admin/orders/new/';

  static String orderDetailEndpoint(int id) =>
      '$baseUrl/api/orders/admin/orders/new/$id/';

  static String updateOrderStatusEndpoint(int id) =>
      '$baseUrl/api/orders/admin/orders/new/$id/update-status/';

  static const String createManualOrderEndpoint =
      '$baseUrl/api/orders/admin/orders/manual/create/';

  static const String restaurantChoicesEndpoint =
      '$baseUrl/api/restaurants/restaurants/choices/';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notificationsEndpoint = '$baseUrl/api/notifications/';

  static String notificationDetailEndpoint(int id) =>
      '$baseUrl/api/notifications/$id/';

  static String notificationReadEndpoint(int id) =>
      '$baseUrl/api/notifications/$id/read/';

  static const String notificationsReadAllEndpoint =
      '$baseUrl/api/notifications/read-all/';

  static const String notificationsUnreadCountEndpoint =
      '$baseUrl/api/notifications/unread-count/';

  // ── Device Registration ───────────────────────────────────────────────────
  static const String registerDeviceEndpoint =
      '$baseUrl/api/notifications/devices/register/';

  static const String unregisterDeviceEndpoint =
      '$baseUrl/api/notifications/devices/unregister/';
}
