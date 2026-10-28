import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/features/cart/data/models/cart_item_model.dart';
import 'package:shein_cart_app/features/shop/data/js/shein_js_scripts.dart';
import 'package:shein_cart_app/features/shop/data/models/product_model.dart';
import 'package:shein_cart_app/features/shop/domain/failures/shop_failures.dart';

class CartPageExtractor {
  Completer<Either<Failure, List<CartItemModel>>>? _pending;
  String? _pendingRequestId;

  Future<int> countItems(WebViewController webView) async {
    try {
      final result = await webView.runJavaScriptReturningResult(
        SheinJsScripts.cartPage(requestId: 'probe', probe: true),
      );
      return num.tryParse(result.toString().replaceAll('"', ''))?.toInt() ?? 0;
    } catch (error) {
      _log('probe failed: $error');
      return 0;
    }
  }

  Future<Either<Failure, List<CartItemModel>>> extract(
      WebViewController webView) async {
    final running = _pending;
    if (running != null && !running.isCompleted) return running.future;

    final requestId = 'cart-${DateTime.now().microsecondsSinceEpoch}';
    final completer = Completer<Either<Failure, List<CartItemModel>>>();
    _pending = completer;
    _pendingRequestId = requestId;

    try {
      await webView
          .runJavaScript(SheinJsScripts.cartPage(requestId: requestId));
    } catch (error) {
      _log('runJavaScript failed: $error');
      _complete(requestId, _failure());
    }

    return completer.future.timeout(
      AppConfig.productExtractionTimeout,
      onTimeout: () {
        final timeout = _failure();
        _complete(requestId, timeout);
        return timeout;
      },
    );
  }

  void handleMessage(String rawMessage) {
    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) return;
      payload = decoded;
    } on FormatException {
      return;
    }

    final requestId = payload['requestId']?.toString();
    if (requestId == null || requestId != _pendingRequestId) return;

    if (payload['type'] != 'cart' || payload['items'] is! List) {
      _log(
          'Cart extraction error: ${payload['code']} ${payload['message'] ?? ''}');
      _complete(requestId, _failure());
      return;
    }

    _log('Cart page: ${payload['debug']}');
    if ((payload['items'] as List).isEmpty)
      _log('No items found. Send this log line to tune selectors.');
    final now = DateTime.now();
    final items = <CartItemModel>[];
    for (final raw in payload['items'] as List) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      final product = ProductModel.fromJson(json);
      if (!product.isValid) continue;
      final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
      items.add(CartItemModel(
        product: product,
        quantity: quantity.clamp(1, AppConfig.maxQuantityPerItem).toInt(),
        addedAt: now,
      ));
      _log('  • ${product.title} | ${product.price} ${product.currency ?? ''} '
          '| ${product.size ?? '-'} | x$quantity');
    }

    _complete(
      requestId,
      items.isEmpty ? _failure() : Right<Failure, List<CartItemModel>>(items),
    );
  }

  void dispose() {
    final id = _pendingRequestId;
    if (id != null) _complete(id, _failure());
  }

  void _complete(
      String requestId, Either<Failure, List<CartItemModel>> result) {
    if (requestId != _pendingRequestId) return;
    final completer = _pending;
    _pending = null;
    _pendingRequestId = null;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  Either<Failure, List<CartItemModel>> _failure() =>
      const Left(CartImportFailure());

  void _log(String message) {
    if (kDebugMode) debugPrint('[CartPageExtractor] $message');
  }
}
