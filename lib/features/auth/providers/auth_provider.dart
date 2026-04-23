import 'package:convex_flutter/convex_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/enums.dart';
import '../models/user_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class   AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;
  final ConvexClient? _convex;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider(this._apiClient, this._storage, {ConvexClient? convex})
      : _convex = convex;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get userId => _user?.id;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isDriver => _user?.role == UserRole.driver;
  bool get isPassenger => _user?.role == UserRole.passenger;

  Future<bool> requestSignInOtp(String email) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();
      await _apiClient.post(
        ApiEndpoints.sendVerificationOtp,
        data: {'email': email, 'type': 'email-verification'},
      );
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtpAndLogin({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();
      await _apiClient.post(
        ApiEndpoints.verifyEmailOtp,
        data: {'email': email, 'otp': otp},
      );
      return await login(email, password);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  /// Check if we have a valid session (stored token).
  Future<void> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      _state = AuthState.unauthenticated;
      await _syncConvexAuth();
      notifyListeners();
      return;
    }

    try {
      _state = AuthState.loading;
      notifyListeners();

      final response = await _apiClient.get(ApiEndpoints.getSession);
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _hydrateUserFromMe();
        await _persistUserIds(_user!);
        _state = AuthState.authenticated;
      } else {
        await _storage.clearTokens();
        _state = AuthState.unauthenticated;
      }
    } on UnauthorizedException {
      await _storage.clearTokens();
      _state = AuthState.unauthenticated;
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
      _state = AuthState.unauthenticated;
    }
    await _syncConvexAuth();
    notifyListeners();
  }

  /// Sign in via Better Auth.
  Future<bool> login(String email, String password) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiClient.post(
        ApiEndpoints.signIn,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final sessionToken = data['session']?['token'] as String? ??
          data['token'] as String?;

      if (sessionToken == null) {
        _errorMessage = 'Invalid response from server';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }

      await _storage.saveAccessToken(sessionToken);
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
      await _hydrateUserFromMe();
      if (_user != null) {
        await _persistUserIds(_user!);
      }

      _state = AuthState.authenticated;
      await _syncConvexAuth();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  /// Sign up via Better Auth, then complete profile, optionally become driver.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? nationalId,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      // POST /api/auth/sign-up/email
      final signUpResponse = await _apiClient.post(
        ApiEndpoints.signUp,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone
        },
      );

      // Extract session token from sign-up response
      final signUpData = signUpResponse.data as Map<String, dynamic>;
      final sessionToken = signUpData['session']?['token'] as String? ??
          signUpData['token'] as String?;

      if (sessionToken != null) {
        await _storage.saveAccessToken(sessionToken);
      }

      if (role == UserRole.driver && sessionToken != null) {

        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      }

      // Optional: national ID (not part of sign-up body)
      if (nationalId != null && nationalId.isNotEmpty) {
        try {
          await _apiClient.patch(
            ApiEndpoints.completeProfile,
            data: {'nationalId': nationalId},
          );
        } catch (e) {
          debugPrint('Complete profile step: $e');
        }
      }

      // Fetch full user data
      if (sessionToken != null) {
        try {
          final sessionResp = await _apiClient.get(ApiEndpoints.getSession);
          final sessionData = sessionResp.data as Map<String, dynamic>?;
          if (sessionData?['user'] != null) {
            _user = UserModel.fromJson(
                sessionData!['user'] as Map<String, dynamic>);
            await _persistUserIds(_user!);
            _state = AuthState.authenticated;
            await _syncConvexAuth();
            notifyListeners();
            return true;
          }
        } catch (e) {
          debugPrint('Post-register session fetch: $e');
        }
      }

      // If sign-up succeeded and token exists but user fetch failed,
      // keep the session token for follow-up setup steps.
      if (sessionToken != null) {
        await _storage.saveAccessToken(sessionToken);
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
      if (role != UserRole.driver) {
        await _syncConvexAuth();
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();
      await _apiClient.post(
        ApiEndpoints.verifyEmailOtp,
        data: {'email': email, 'otp': otp},
      );
      await checkAuthStatus();
      return _state == AuthState.authenticated;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordResetOtp(String email) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();
      await _apiClient.post(
        ApiEndpoints.requestPasswordResetOtp,
        data: {'email': email},
      );
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();
      await _apiClient.post(
        ApiEndpoints.resetPasswordOtp,
        data: {'email': email, 'otp': otp, 'password': newPassword},
      );
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  /// Complete driver-specific profile after base account sign up.
  Future<bool> becomeDriver({
    required String licenseNumber,
    required String vehicleModel,
    required String vehiclePlate,
    required int vehicleSeats,
    required String licenseDocumentId,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      await _apiClient.post(
        ApiEndpoints.becomeDriver,
        data: {
          'licenseNumber': licenseNumber,
          'vehicleModel': vehicleModel,
          'vehiclePlate': vehiclePlate,
          'vehicleSeats': vehicleSeats,
          'licenseDocumentId': licenseDocumentId,
        },
      );

      final sessionResp = await _apiClient.get(ApiEndpoints.getSession);
      final sessionData = sessionResp.data as Map<String, dynamic>?;
      if (sessionData?['user'] != null) {
        _user = UserModel.fromJson(sessionData!['user'] as Map<String, dynamic>);
        await _hydrateUserFromMe();
        await _persistUserIds(_user!);
      }

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to complete driver profile';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  /// Demo mode login without backend.
  Future<bool> loginAsDemo(UserRole role) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _user = UserModel(
      id: 'demo-user-001',
      name: role == UserRole.driver ? 'Abebe Kebede' : 'Tigist Hailu',
      email: role == UserRole.driver ? 'abebe@demo.com' : 'tigist@demo.com',
      phone: '+251912345678',
      status: UserStatus.active,
      role: role,
      rating: 4.7,
      passengerId: role == UserRole.passenger ? 'demo-passenger-001' : null,
      driverId: role == UserRole.driver ? 'demo-driver-001' : null,
      vehicleModel: role == UserRole.driver ? 'Toyota Yaris 2020' : null,
      vehiclePlate: role == UserRole.driver ? 'AA 3-12345' : null,
      vehicleSeats: role == UserRole.driver ? 4 : null,
    );

    await _storage.saveUserRole(role.name);
    await _storage.saveUserId('demo-user-001');
    if (role == UserRole.passenger) {
      await _storage.savePassengerId('demo-passenger-001');
    } else {
      await _storage.saveDriverId('demo-driver-001');
    }

    _state = AuthState.authenticated;
    await _syncConvexAuth();
    notifyListeners();
    return true;
  }

  /// Refreshes the Convex JWT from your backend and applies it to [ConvexClient].
  /// Call before Convex subscriptions that use `requireAuth` (e.g. live tracking).
  Future<void> syncConvexAuth() => _syncConvexAuth();

  /// Pushes the backend-issued Convex JWT into [ConvexClient] so queries that
  /// call `requireAuth` succeed (chat, tracking, notifications).
  Future<void> _syncConvexAuth() async {
    final convex = _convex;
    if (convex == null) return;
    try {
      if (_state != AuthState.authenticated) {
        await convex.setAuth(token: null);
        return;
      }
      final jwt = await fetchConvexToken();
      if (jwt != null) {
        await convex.setAuth(token: jwt);
        return;
      }
      final stored = await _storage.getConvexJwt();
      if (stored != null) {
        await convex.setAuth(token: stored);
      } else {
        await convex.setAuth(token: null);
      }
    } catch (e) {
      debugPrint('Convex auth sync: $e');
      final stored = await _storage.getConvexJwt();
      if (stored != null && _state == AuthState.authenticated) {
        try {
          await convex.setAuth(token: stored);
        } catch (_) {}
      }
    }
  }

  /// Fetch a JWT for Convex real-time auth.
  Future<String?> fetchConvexToken() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getToken);
      final data = response.data;
      String? jwt;
      if (data is Map<String, dynamic>) {
        jwt = data['token'] as String?;
      } else if (data is String) {
        jwt = data;
      }
      if (jwt != null) {
        await _storage.saveConvexJwt(jwt);
      }
      return jwt;
    } catch (e) {
      debugPrint('Failed to fetch Convex token: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.signOut);
    } catch (_) {}
    _user = null;
    _state = AuthState.unauthenticated;
    await _storage.clearTokens();
    await _storage.clearProfileIds();
    await _storage.clearCachedUserJson();
    await _syncConvexAuth();
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiClient.patch(ApiEndpoints.completeProfile, data: data);
      // Re-fetch session to get updated user
      final response = await _apiClient.get(ApiEndpoints.getSession);
      final sessionData = response.data as Map<String, dynamic>?;
      if (sessionData?['user'] != null) {
        _user =
            UserModel.fromJson(sessionData!['user'] as Map<String, dynamic>);
        await _persistUserIds(_user!);
      }
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persistUserIds(UserModel user) async {
    await _storage.saveUserRole(user.role.name);
    await _storage.saveUserId(user.id);
    if (user.passengerId != null && user.passengerId!.isNotEmpty) {
      await _storage.savePassengerId(user.passengerId!);
    } else {
      await _storage.clearPassengerId();
    }
    if (user.driverId != null && user.driverId!.isNotEmpty) {
      await _storage.saveDriverId(user.driverId!);
    } else {
      await _storage.clearDriverId();
    }
    await _storage.saveCachedUserJson(jsonEncode(user.toJson()));
  }

  Future<void> _hydrateUserFromMe() async {
    try {
      final meResponse = await _apiClient.get(ApiEndpoints.me);
      final meData = meResponse.data as Map<String, dynamic>?;
      final meUser = meData?['user'] as Map<String, dynamic>?;
      if (meUser != null) {
        _user = UserModel.fromJson(meUser);
      }
    } catch (e) {
      debugPrint('/users/me fetch failed: $e');
    }
  }
}
