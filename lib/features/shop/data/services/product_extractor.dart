import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/features/shop/data/js/shein_js_scripts.dart';
import 'package:shein_cart_app/features/shop/data/models/product_model.dart';
import 'package:shein_cart_app/features/shop/domain/failures/shop_failures.dart';

/// Turns the asynchronous "run JS → wait for a JavaScriptChannel message"
/// round-trip into a single `Future<Either<Failure, ProductModel>>`.
///
/// Flow:
/// 1. [extract] injects the extraction script with a unique requestId.
/// 2. The page posts JSON to the channel; the WebView owner forwards it to
///    [handleMessage].
/// 3. The matching pending request completes (or times out).
class ProductExtractor {
  Completer<Either<Failure, ProductModel>>? _pending;
  String? _pendingRequestId;

  Future<Either<Failure, ProductModel>> extract(WebViewController webView) async {
    // A request is already running: share its result instead of starting another.
    final running = _pending;
    if (running != null && !running.isCompleted) return running.future;

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<Either<Failure, ProductModel>>();
    _pending = completer;
    _pendingRequestId = requestId;

    try {
      await webView.runJavaScript(SheinJsScripts.extractProduct(requestId: requestId));
    } catch (error) {
      _log('runJavaScript failed: $error');
      _complete(requestId, _failure(const ProductExtractionFailure()));
    }

    return completer.future.timeout(
      AppConfig.productExtractionTimeout,
      onTimeout: () {
        _log('Extraction timed out');
        final timeout = _failure(const ProductExtractionFailure());
        _complete(requestId, timeout);
        return timeout;
      },
    );
  }

  /// Entry point for every message received on the JavaScriptChannel.
  void handleMessage(String rawMessage) {
    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) return;
      payload = decoded;
    } on FormatException {
      _log('Ignoring non-JSON message: $rawMessage');
      return;
    }

    final requestId = payload['requestId']?.toString();
    if (requestId == null || requestId != _pendingRequestId) return; // stale

    switch (payload['type']) {
      case 'product':
        final data = payload['data'];
        if (data is! Map<String, dynamic>) {
          _complete(requestId, _failure(const ProductExtractionFailure()));
          return;
        }
        final product = ProductModel.fromJson(data);
        _log('Extracted: ${product.toJson()}');
        _complete(
          requestId,
          product.isValid
              ? Right<Failure, ProductModel>(product)
              : _failure(const ProductExtractionFailure()),
        );
      case 'error':
        _log('Extraction error: ${payload['code']} ${payload['message'] ?? ''}');
        _complete(
          requestId,
          _failure(payload['code'] == 'SIZE_REQUIRED'
              ? const SizeNotSelectedFailure()
              : const ProductExtractionFailure()),
        );
      default:
        _complete(requestId, _failure(const ProductExtractionFailure()));
    }
  }

  /// Completes any pending request (call when the WebView is disposed).
  void dispose() {
    final id = _pendingRequestId;
    if (id != null) _complete(id, _failure(const ProductExtractionFailure()));
  }

  void _complete(String requestId, Either<Failure, ProductModel> result) {
    if (requestId != _pendingRequestId) return;
    final completer = _pending;
    _pending = null;
    _pendingRequestId = null;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  Either<Failure, ProductModel> _failure(Failure failure) => Left(failure);

  void _log(String message) {
    if (kDebugMode) debugPrint('[ProductExtractor] $message');
  }
}
