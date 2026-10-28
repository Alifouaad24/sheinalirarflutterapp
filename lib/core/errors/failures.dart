import 'package:get/get.dart';

import 'package:shein_cart_app/core/localization/locale_keys.dart';

/// Base type returned on the Left side of every `Either<Failure, T>`.
///
/// [message] is always user-friendly and translated (Arabic by default).
/// When the backend sends its own readable message it is passed through
/// [customMessage] and takes priority.
abstract class Failure {
  const Failure({this.customMessage, this.statusCode});

  final String? customMessage;
  final int? statusCode;

  /// Translation key of the default message for this failure type.
  String get messageKey;

  String get message {
    final custom = customMessage?.trim();
    return (custom != null && custom.isNotEmpty) ? custom : messageKey.tr;
  }

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

/// 5xx or unexpected 4xx responses / unreadable payloads.
class ServerFailure extends Failure {
  const ServerFailure({super.customMessage, super.statusCode});
  @override
  String get messageKey => LocaleKeys.failureServer;
}

/// No connection, DNS failure, TLS handshake failure…
class NetworkFailure extends Failure {
  const NetworkFailure({super.customMessage});
  @override
  String get messageKey => LocaleKeys.failureNetwork;
}

/// Request exceeded the configured timeout (or 408 / 504).
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.customMessage, super.statusCode});
  @override
  String get messageKey => LocaleKeys.failureTimeout;
}

/// 401 / 403 — the session must be refreshed or the user must sign in.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.customMessage, super.statusCode});
  @override
  String get messageKey => LocaleKeys.failureUnauthorized;
}

/// Local storage read/write problems.
class CacheFailure extends Failure {
  const CacheFailure({super.customMessage});
  @override
  String get messageKey => LocaleKeys.failureCache;
}

/// Anything we did not anticipate. [error] is kept for logging only.
class UnknownFailure extends Failure {
  const UnknownFailure({super.customMessage, this.error});
  final Object? error;
  @override
  String get messageKey => LocaleKeys.failureUnknown;
}
