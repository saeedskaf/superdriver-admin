import 'package:shared_preferences/shared_preferences.dart';
import 'package:superdriver_admin/domain/models/user.dart';

class SharedPreferencesRepository {
  final SharedPreferences _prefs;

  SharedPreferencesRepository(this._prefs);

  // ─── Generic get / save ───────────────────────────────────────────────

  dynamic getData({required String key}) => _prefs.getString(key);

  Future<void> savedata({required String key, required String value}) async {
    await _prefs.setString(key, value);
  }

  // ─── User info ────────────────────────────────────────────────────────

  Future<void> saveUserInfo({required User user}) async {
    if (user.id != null) {
      await _prefs.setString('user_id', user.id.toString());
    }
    if (user.phoneNumber != null) {
      await _prefs.setString('user_phone', user.phoneNumber!);
    }
    if (user.firstName != null) {
      await _prefs.setString('user_first_name', user.firstName!);
    }
    if (user.lastName != null) {
      await _prefs.setString('user_last_name', user.lastName!);
    }
  }

  // ─── Login state ──────────────────────────────────────────────────────

  Future<void> setLoggedIn({required bool isLoggedIn}) async {
    await _prefs.setBool('is_logged_in', isLoggedIn);
  }

  bool get isLoggedIn => _prefs.getBool('is_logged_in') ?? false;

  // ─── Token helpers ────────────────────────────────────────────────────

  String? get accessToken => _prefs.getString('access_token');
  String? get refreshToken => _prefs.getString('refresh_token');

  // ─── Logout ───────────────────────────────────────────────────────────

  /// Clears only auth-related keys instead of wiping all preferences.
  Future<void> logout() async {
    const keysToRemove = [
      'access_token',
      'refresh_token',
      'user_id',
      'user_phone',
      'user_first_name',
      'user_last_name',
      'is_logged_in',
      'device_id',
      'device_token',
    ];

    await Future.wait(keysToRemove.map(_prefs.remove));
  }
}
