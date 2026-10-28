import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:shein_cart_app/core/errors/exceptions.dart';
import 'package:shein_cart_app/core/errors/failures.dart';

/// Single place that converts HTTP status codes and exceptions to [Failure]s.
abstract final class ErrorMapper {
  static Failure fromStatusCode(int statusCode, {String? serverMessage}) {
    switch (statusCode) {
      case 401:
      case 403:
        return UnauthorizedFailure(statusCode: statusCode);
      case 408:
      case 504:
        return TimeoutFailure(statusCode: statusCode);
    }
    if (statusCode >= 500) return ServerFailure(statusCode: statusCode);
    // 4xx: the backend message (validation errors…) is usually user-readable.
    return ServerFailure(customMessage: serverMessage, statusCode: statusCode);
  }

  static Failure fromException(Object error) {
    if (error is Failure) return error;
    if (error is TimeoutException) return const TimeoutFailure();
    if (error is SocketException ||
        error is HandshakeException ||
        error is http.ClientException) {
      return const NetworkFailure();
    }
    if (error is CacheException) return const CacheFailure();
    if (error is ServerException) {
      return fromStatusCode(error.statusCode ?? 500, serverMessage: error.message);
    }
    if (error is FormatException) return const ServerFailure();
    return UnknownFailure(error: error);
  }

  /// Reads a human message from common backend error shapes:
  /// `{"message": "..."}`, `{"error": "..."}`, `{"errors": ["..."]}`.
  static String? extractServerMessage(dynamic body) {
    if (body is! Map) return null;
    for (final key in const ['message', 'error', 'msg', 'detail']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) return errors.first.toString();
    return null;
  }
}
