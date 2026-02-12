class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
      : super(message: message ?? 'Unauthorized', statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
      : super(message: message ?? 'Forbidden', statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException({String? message})
      : super(message: message ?? 'Not found', statusCode: 404);
}

class ServerException extends ApiException {
  ServerException({String? message})
      : super(message: message ?? 'Internal server error', statusCode: 500);
}

class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(message: message ?? 'No internet connection');
}
