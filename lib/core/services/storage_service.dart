import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _convexJwtKey = 'convex_jwt';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _passengerIdKey = 'passenger_id';
  static const String _driverIdKey = 'driver_id';
  static const String _cachedUserJsonKey = 'cached_user_json';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _localeKey = 'locale';

  // Session token (Better Auth session token used as Bearer)
  Future<void> saveAccessToken(String token) =>
      _secureStorage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() =>
      _secureStorage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _secureStorage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: _refreshTokenKey);

  // Convex JWT for real-time auth
  Future<void> saveConvexJwt(String jwt) =>
      _secureStorage.write(key: _convexJwtKey, value: jwt);

  Future<String?> getConvexJwt() =>
      _secureStorage.read(key: _convexJwtKey);

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _convexJwtKey);
  }

  // SharedPreferences for non-sensitive data
  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, id);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> savePassengerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passengerIdKey, id);
  }

  Future<String?> getPassengerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passengerIdKey);
  }

  Future<void> clearPassengerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passengerIdKey);
  }

  Future<void> saveDriverId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverIdKey, id);
  }

  Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_driverIdKey);
  }

  Future<void> clearDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverIdKey);
  }

  Future<void> clearProfileIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_passengerIdKey);
    await prefs.remove(_driverIdKey);
  }

  Future<void> saveCachedUserJson(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserJsonKey, userJson);
  }

  Future<String?> getCachedUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedUserJsonKey);
  }

  Future<void> clearCachedUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserJsonKey);
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
