import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/constants/storage_keys.dart';
import 'package:shein_cart_app/core/errors/error_mapper.dart';
import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/core/storage/local_storage_service.dart';

/// Converts the decoded JSON body (Map, List, String or null) into [T].
typedef ResponseDecoder<T> = T Function(dynamic json);

enum _HttpMethod { get, post, put, delete }

/// The only class that talks HTTP. Every call returns `Either<Failure, T>`,
/// so callers never need try/catch.
///
/// ```dart
/// final result = await apiClient.get<List<OrderModel>>(
///   ApiEndpoints.orders,
///   decoder: (json) => (json as List).map((e) => OrderModel.fromJson(e)).toList(),
/// );
/// ```
class ApiClient {
  ApiClient({
    required LocalStorageService storage,
    http.Client? httpClient,
    String? baseUrl,
    Duration? timeout,
  })  : _storage = storage,
        _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _timeout = timeout ?? AppConfig.apiTimeout;

  final LocalStorageService _storage;
  final http.Client _http;
  final String _baseUrl;
  final Duration _timeout;

  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ResponseDecoder<T>? decoder,
  }) =>
      _request<T>(_HttpMethod.get, path, query: query, headers: headers, decoder: decoder);

  Future<Either<Failure, T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ResponseDecoder<T>? decoder,
  }) =>
      _request<T>(_HttpMethod.post, path,
          body: body, query: query, headers: headers, decoder: decoder);

  Future<Either<Failure, T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ResponseDecoder<T>? decoder,
  }) =>
      _request<T>(_HttpMethod.put, path,
          body: body, query: query, headers: headers, decoder: decoder);

  Future<Either<Failure, T>> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ResponseDecoder<T>? decoder,
  }) =>
      _request<T>(_HttpMethod.delete, path,
          body: body, query: query, headers: headers, decoder: decoder);

  void dispose() => _http.close();

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<Either<Failure, T>> _request<T>(
    _HttpMethod method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ResponseDecoder<T>? decoder,
  }) async {
    final uri = _buildUri(path, query);
    try {
      final encodedBody = body == null ? null : (body is String ? body : jsonEncode(body));
      _log('→ ${method.name.toUpperCase()} $uri');

      final response =
          await _send(method, uri, _buildHeaders(headers), encodedBody).timeout(_timeout);

      _log('← ${response.statusCode} $uri');
      return _handleResponse<T>(response, decoder);
    } catch (error) {
      _log('✕ $uri → $error');
      return Left(ErrorMapper.fromException(error));
    }
  }

  Future<http.Response> _send(
    _HttpMethod method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    return switch (method) {
      _HttpMethod.get => _http.get(uri, headers: headers),
      _HttpMethod.post => _http.post(uri, headers: headers, body: body),
      _HttpMethod.put => _http.put(uri, headers: headers, body: body),
      _HttpMethod.delete => _http.delete(uri, headers: headers, body: body),
    };
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    // Absolute URLs are allowed (e.g. pre-signed links).
    final isAbsolute = path.startsWith('http://') || path.startsWith('https://');
    final base = Uri.parse(isAbsolute ? path : _baseUrl);
    final fullPath = isAbsolute
        ? base.path
        : '${base.path}/$path'.replaceAll(RegExp(r'/{2,}'), '/');

    return base.replace(
      path: fullPath,
      queryParameters: query == null || query.isEmpty
          ? (base.queryParameters.isEmpty ? null : base.queryParameters)
          : query.map((key, value) => MapEntry(key, '$value')),
    );
  }

  /// Default headers + bearer token from storage + per-request overrides.
  Map<String, String> _buildHeaders(Map<String, String>? extra) {
    final headers = <String, String>{..._defaultHeaders};
    final token = _storage.getString(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Either<Failure, T> _handleResponse<T>(http.Response response, ResponseDecoder<T>? decoder) {
    final data = _decodeBody(response);
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      try {
        return Right(decoder != null ? decoder(data) : data as T);
      } catch (error) {
        _log('Decoding failed: $error');
        return Left(const ServerFailure());
      }
    }

    return Left(ErrorMapper.fromStatusCode(
      status,
      serverMessage: ErrorMapper.extractServerMessage(data),
    ));
  }

  /// UTF-8 safe decoding (Arabic text) with graceful fallback to raw text.
  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ApiClient] $message');
  }
}
