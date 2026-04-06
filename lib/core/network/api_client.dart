import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;
  final CookieJar _cookieJar = CookieJar();

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        // LAN / dev servers may be slow to accept connections; 15s often false-positives.
        connectTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Better Auth `getSession()` expects session cookies. Persist them across
    // requests (mobile has no browser cookie jar by default).
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(_OriginForBetterAuthInterceptor());
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_ResponseUnwrapInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final result = await _dio.post(path, data: data, queryParameters: queryParameters);
      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?extraFields,
      });
      return await _dio.post(path, data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Could not reach the server. Check that it is running, '
              'your phone and PC are on the same network, and the API base URL '
              '(${AppConstants.baseUrl}) is correct.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] as String? ?? 'Something went wrong')
            : 'Something went wrong';
        if (statusCode == 401) return UnauthorizedException(message: message);
        if (statusCode == 403) return ForbiddenException(message: message);
        if (statusCode == 404) return NotFoundException(message: message);
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message: message);
        }
        return ApiException(message: message, statusCode: statusCode);
      default:
        return ApiException(message: e.message ?? 'An unexpected error occurred');
    }
  }
}

/// Better Auth may require an Origin that matches backend `FRONTEND_URL`.
/// Express CORS in your backend allows *no* Origin for mobile, but Better Auth's
/// trustedOrigins can still reject missing Origin for `/auth/*` calls.
class _OriginForBetterAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Our ApiClient baseUrl already includes `/api`. Endpoints are like `/auth/...`.
    // final path = options.path;
    // if (path.startsWith('/auth/')) {
    //   options.headers.putIfAbsent('Origin', () => AppConstants.frontendUrl);
    // }
    handler.next(options);
  }
}

/// Attaches the stored session token as a Bearer header.
class _AuthInterceptor extends Interceptor {
  final StorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Do not clear local tokens on 401 blindly:
      // Better Auth session-cookie flows may 401 temporarily (e.g. before cookies
      // are established). Clearing here breaks multi-step onboarding flows.
    }
    handler.next(err);
  }
}

/// Unwraps the backend's standard `{ success, data, message }` envelope.
/// Better Auth endpoints don't use this envelope so they pass through unchanged.
class _ResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('success')) {
      if (data['success'] == true) {
        response.data = data['data'];
      } else {
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: Response(
              requestOptions: response.requestOptions,
              statusCode: response.statusCode,
              data: data,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }
    }
    handler.next(response);
  }
}
