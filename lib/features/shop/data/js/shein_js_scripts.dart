import 'dart:convert';

import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/constants/shein_selectors.dart';

/// JavaScript injected into SHEIN pages.
///
/// The scripts are generic templates; every SHEIN-specific selector/text is
/// injected as a JSON `CONFIG` object built from [SheinSelectors], so updating
/// SHEIN support never requires touching the JavaScript itself.
/// Scripts are written in ES5 style for maximum WebView compatibility.
abstract final class SheinJsScripts {
  /// Hides SHEIN's native add-to-bag buttons and sticky purchase bars.
  /// Idempotent: safe to run on every page load and URL change.
  static final String hideNativeCartButtons = _hideTemplate.replaceFirst(
    '__CONFIG__',
    jsonEncode({
      'selectors': [
        ...SheinSelectors.nativeAddToCart,
        ...SheinSelectors.stickyPurchaseBar,
      ],
      'texts': SheinSelectors.nativeButtonTexts,
      'candidates': SheinSelectors.textMatchCandidates,
      'maxTextLength': SheinSelectors.maxButtonTextLength,
    }),
  );

  /// Reads the current product and posts the result to the Flutter channel as
  /// `{requestId, type: 'product', data: {...}}` or
  /// `{requestId, type: 'error', code: 'SIZE_REQUIRED' | 'EXTRACTION_FAILED'}`.
  static String extractProduct({required String requestId}) =>
      _extractTemplate.replaceFirst(
        '__CONFIG__',
        jsonEncode({
          'requestId': requestId,
          'channel': AppConfig.jsChannelName,
          'productIdPattern': SheinSelectors.productUrlPattern.pattern,
          'title': SheinSelectors.title,
          'price': SheinSelectors.price,
          'mainImage': SheinSelectors.mainImage,
          'sizeOptions': SheinSelectors.sizeOptions,
          'selectedSize': SheinSelectors.selectedSize,
          'selectedColor': SheinSelectors.selectedColor,
          'colorLabel': SheinSelectors.colorLabel,
          'galleryImages': SheinSelectors.galleryImages,
          'sku': SheinSelectors.sku,
        }),
      );

  static String cartPage({required String requestId, bool probe = false}) =>
      _cartTemplate.replaceFirst(
        '__CONFIG__',
        jsonEncode({
          'requestId': requestId,
          'mode': probe ? 'probe' : 'extract',
          'channel': AppConfig.jsChannelName,
          'productIdPattern': SheinSelectors.productUrlPattern.pattern,
          'items': SheinSelectors.cartItem,
          'itemTitle': SheinSelectors.cartItemTitle,
          'itemPrice': SheinSelectors.cartItemPrice,
          'itemAttr': SheinSelectors.cartItemAttr,
          'itemQty': SheinSelectors.cartItemQuantity,
          'excludePattern': SheinSelectors.cartExcludeClassPattern,
        }),
      );

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  static const String _hideTemplate = r'''
(function () {
  var CONFIG = __CONFIG__;
  var STYLE_ID = '__flutter_hide_native_cart__';
  var HIDDEN_ATTR = 'data-flutter-hidden';

  // Already fully installed on this document: just run one more pass.
  if (window.__flutterHideObserver) { window.__flutterHideNativeCart(); return; }

  function normalize(text) {
    return (text || '')
      .replace(/[\u0623\u0625\u0622]/g, '\u0627')
      .replace(/\u0649/g, '\u064A')
      .replace(/\s+/g, ' ')
      .trim()
      .toLowerCase();
  }
  var TARGET_TEXTS = CONFIG.texts.map(normalize);

  // 1) CSS: one rule per selector so one invalid selector can't break the rest.
  function injectCss() {
    if (document.getElementById(STYLE_ID)) return;
    var style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = CONFIG.selectors.map(function (s) {
      return s + '{display:none !important;visibility:hidden !important;pointer-events:none !important;}';
    }).join('\n');
    (document.head || document.documentElement).appendChild(style);
  }

  // 2) Text matching for buttons whose class names we don't know.
  function hideByText() {
    var nodes;
    try { nodes = document.querySelectorAll(CONFIG.candidates.join(',')); } catch (e) { return; }
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.hasAttribute(HIDDEN_ATTR)) continue;
      var text = normalize(el.textContent); // textContent avoids forcing layout
      if (!text || text.length > CONFIG.maxTextLength) continue;
      for (var j = 0; j < TARGET_TEXTS.length; j++) {
        if (text.indexOf(TARGET_TEXTS[j]) !== -1) {
          el.style.setProperty('display', 'none', 'important');
          el.setAttribute(HIDDEN_ATTR, '1');
          break;
        }
      }
    }
  }

  function run() {
    try { injectCss(); hideByText(); } catch (e) { /* never break the page */ }
  }
  window.__flutterHideNativeCart = run;

  // 3) Keep things hidden when SHEIN re-renders (SPA navigation, lazy parts).
  // We observe `document` itself (always a Node) instead of
  // `document.documentElement`, which is still null when this runs very
  // early in a navigation. The "installed" flag is only set once observe()
  // has succeeded, so a failed early attempt is retried on the next call.
  try {
    var scheduled = false;
    var observer = new MutationObserver(function () {
      if (scheduled) return;
      scheduled = true;
      setTimeout(function () { scheduled = false; run(); }, 120);
    });
    observer.observe(document, { childList: true, subtree: true });
    window.__flutterHideObserver = observer;
  } catch (e) { /* retried on the next onPageFinished / onUrlChange */ }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run, { once: true });
  }
  run();
})();
''';

  static const String _extractTemplate = r'''
(function () {
  var CONFIG = __CONFIG__;

  function send(payload) {
    payload.requestId = CONFIG.requestId;
    try { window[CONFIG.channel].postMessage(JSON.stringify(payload)); } catch (e) {}
  }

  // ---------- helpers ----------
  function isEmpty(v) { return v === null || v === undefined || v === '' || (typeof v === 'number' && isNaN(v)); }
  function firstValid(values) {
    for (var i = 0; i < values.length; i++) { if (!isEmpty(values[i])) return values[i]; }
    return null;
  }
  function textOf(el) { return el ? (el.textContent || '').replace(/\s+/g, ' ').trim() : ''; }
  // SHEIN keeps previously opened product pages in the DOM (hidden) after
  // SPA navigation, so the first match may belong to the OLD product.
  // Hidden (display:none) elements have no client rects.
  function isVisible(el) {
    if (!el || !el.getClientRects().length) return false;
    var cs = getComputedStyle(el);
    return cs.visibility !== 'hidden';
  }
  function query(selectors) {
    var fallback = null;
    for (var i = 0; i < selectors.length; i++) {
      try {
        var list = document.querySelectorAll(selectors[i]);
        for (var j = 0; j < list.length; j++) { if (isVisible(list[j])) return list[j]; }
        if (!fallback && list.length) fallback = list[0];
      } catch (e) {}
    }
    return fallback;
  }
  function queryAll(selectors) {
    var fallback = [];
    for (var i = 0; i < selectors.length; i++) {
      try {
        var list = document.querySelectorAll(selectors[i]);
        var visible = [].filter.call(list, isVisible);
        if (visible.length) return visible;
        if (!fallback.length && list.length) fallback = list;
      } catch (e) {}
    }
    return fallback;
  }
  function meta(names) {
    for (var i = 0; i < names.length; i++) {
      var el = document.querySelector('meta[property="' + names[i] + '"],meta[name="' + names[i] + '"]');
      if (el && el.getAttribute('content')) return el.getAttribute('content');
    }
    return null;
  }
  function absUrl(u) {
    if (!u) return null;
    u = String(u).trim();
    if (u.indexOf('//') === 0) return 'https:' + u;
    try { return new URL(u, location.href).href; } catch (e) { return u; }
  }
  // Handles "SAR 45.00", "45٫00 ر.س", Arabic-Indic digits, thousands separators.
  function toNumber(v) {
    if (isEmpty(v)) return null;
    if (typeof v === 'number') return isFinite(v) ? v : null;
    var s = String(v)
      .replace(/[\u0660-\u0669]/g, function (d) { return String(d.charCodeAt(0) - 0x0660); })
      .replace(/[\u06F0-\u06F9]/g, function (d) { return String(d.charCodeAt(0) - 0x06F0); })
      .replace(/\u066B/g, '.')
      .replace(/\u066C/g, ',');
    var m = s.match(/\d[\d,]*(?:\.\d+)?/);
    if (!m) return null;
    var n = parseFloat(m[0].replace(/,/g, ''));
    return isNaN(n) ? null : n;
  }
  // Detects the currency from price text like "SR97.00", "AED 45", "97.00 ر.س".
  var CURRENCIES = [
    [/(^|[^A-Za-z])(SAR|SR)(?![A-Za-z])|\u0631\.?\s?\u0633/, 'SAR'],
    [/(^|[^A-Za-z])AED(?![A-Za-z])|\u062F\.?\s?\u0625/, 'AED'],
    [/(^|[^A-Za-z])(KWD|KD)(?![A-Za-z])|\u062F\.?\s?\u0643/, 'KWD'],
    [/(^|[^A-Za-z])(QAR|QR)(?![A-Za-z])|\u0631\.?\s?\u0642/, 'QAR'],
    [/(^|[^A-Za-z])(BHD|BD)(?![A-Za-z])|\u062F\.?\s?\u0628/, 'BHD'],
    [/(^|[^A-Za-z])(OMR|RO)(?![A-Za-z])|\u0631\.?\s?\u0639/, 'OMR'],
    [/(^|[^A-Za-z])(EGP|LE)(?![A-Za-z])|\u062C\.?\s?\u0645/, 'EGP'],
    [/(^|[^A-Za-z])JOD(?![A-Za-z])/, 'JOD'],
    [/(^|[^A-Za-z])(USD|US\$)(?![A-Za-z])|\$/, 'USD'],
    [/(^|[^A-Za-z])EUR(?![A-Za-z])|\u20AC/, 'EUR'],
    [/(^|[^A-Za-z])GBP(?![A-Za-z])|\u00A3/, 'GBP']
  ];
  function currencyFromText(text) {
    if (!text) return null;
    for (var i = 0; i < CURRENCIES.length; i++) {
      if (CURRENCIES[i][0].test(text)) return CURRENCIES[i][1];
    }
    return null;
  }
  // Fallbacks: SHEIN keeps the selected currency in a cookie / global config.
  function currencyFromSite() {
    var m = document.cookie.match(/(?:^|;\s*)currency=([A-Za-z]{3})/);
    if (m) return m[1].toUpperCase();
    try {
      var g = window.gbCommonInfo || window.gbRawData || {};
      if (typeof g.currency === 'string' && /^[A-Za-z]{3}$/.test(g.currency)) return g.currency.toUpperCase();
    } catch (e) {}
    return null;
  }
  function cleanTitle(t) {
    return t ? String(t).replace(/\s*[|\-\u2013]\s*SHEIN.*$/i, '').trim() : t;
  }
  // The site-wide title ("SHEIN | Women's Fashion ...") is never a product name.
  function productTitle(t) {
    if (!t) return null;
    t = String(t).replace(/\s+/g, ' ').trim();
    if (!t || /^SHEIN\s*[|\-\u2013]/i.test(t)) return null;
    return cleanTitle(t) || null;
  }
  // Real sizes are short tokens (S, XL, 38, EU 40, One-size, 4XL+,
  // "3-6 Months (62cm)"...). Rejects things like "Click to buy" or promo
  // codes such as "222+023".
  function sizeText(v) {
    if (!v) return null;
    v = String(v).replace(/\s+/g, ' ').trim();
    if (!v || v.length > 24 || /\d\s*\+\s*\d/.test(v) || v.split(' ').length > 4) return null;
    return v;
  }
  // The size label of an option. The option often also contains badges
  // ("Only 2 left", "Low stock", local size hints...), so its full text may
  // not look like a size: fall back to attributes and its first leaf text.
  function sizeLabel(el) {
    if (!el) return null;
    var attrs = ['aria-label', 'data-attr-value', 'data-value', 'data-size', 'title'];
    for (var i = 0; i < attrs.length; i++) {
      var a = sizeText(el.getAttribute(attrs[i]));
      if (a) return a;
    }
    var whole = sizeText(textOf(el));
    if (whole) return whole;
    var all = el.querySelectorAll('*');
    for (var j = 0; j < all.length; j++) {
      if (all[j].children.length) continue;
      var t = sizeText(textOf(all[j]));
      if (t) return t;
    }
    return null;
  }
  var SELECTED_CLASS = /(^|[\s_-])(active|selected|checked|current)($|[\s_-])/i;
  function isSelectedOption(el) {
    if (el.getAttribute('aria-checked') === 'true' || el.getAttribute('aria-selected') === 'true' ||
        el.getAttribute('aria-pressed') === 'true') return true;
    var cls = String(el.className || '');
    return SELECTED_CLASS.test(cls) && !/inactive|unactive|in-active/i.test(cls);
  }
  // SHEIN is a single-page app: when you open a product from another page,
  // meta tags / JSON-LD still describe the FIRST page that was loaded.
  // The biggest visible picture on a product page is the main product photo.
  // Flutter can't decode AVIF, and SHEIN serves AVIF through <picture>/currentSrc.
  // Prefer the plain src / data-src (jpg/webp) and convert .avif URLs to .webp.
  function imageSrc(img) {
    var candidates = [img.getAttribute('data-src'), img.getAttribute('src'), img.currentSrc];
    for (var i = 0; i < candidates.length; i++) {
      var c = candidates[i];
      if (c && c.indexOf('data:') !== 0) return c.replace(/\.avif(?=$|[?#])/i, '.webp');
    }
    return null;
  }
    function largestVisibleImageEl() {
    var best = null, bestArea = 0;
    for (var i = 0; i < document.images.length; i++) {
      var img = document.images[i];
      var r = img.getBoundingClientRect();
      if (r.width < 120 || r.height < 120 || r.bottom <= 0 || r.top > innerHeight * 1.5) continue;
      var src = imageSrc(img);
      if (!src || /logo|icon|sprite/i.test(src)) continue;
      var area = r.width * r.height;
      if (area > bestArea) { bestArea = area; best = img; }
    }
    return best;
  }

  // ---------- all gallery images ----------
  function normImg(u) {
    if (!u) return null;
    u = String(u).trim();
    if (!u || u.indexOf('data:') === 0) return null;
    if (u.indexOf('//') === 0) u = 'https:' + u;
    return u.replace(/\.avif(?=$|[?#])/i, '.webp');
  }
  // Same picture in different sizes/formats -> same key (for de-duplication).
  function imgKey(u) {
    return u.replace(/^https?:/, '').replace(/[?#].*$/, '')
      .replace(/_thumbnail_\d+x\d*/i, '').replace(/\.(webp|jpe?g|png|avif)$/i, '');
  }
  // The gallery is the closest ancestor of the main photo that holds several images.
  function galleryContainer(el) {
    for (var i = 0; el && i < 8; i++, el = el.parentElement) {
      var n = el.querySelectorAll('img').length;
      if (n >= 2 && n <= 40 && /swiper|gallery|carousel|picture|image|intro__main|detail-top/i.test(String(el.className))) return el;
    }
    return null;
  }
  function collectImages(ld, mainEl, mainSrc) {
    var list = [], seen = {};
    function add(u) {
      u = normImg(u);
      if (!u || /logo|icon|sprite/i.test(u)) return;
      var k = imgKey(u);
      if (seen[k]) return;
      seen[k] = 1;
      list.push(u);
    }
    add(mainSrc);
    if (ld && ld.image) {
      (Array.isArray(ld.image) ? ld.image : [ld.image]).forEach(function (x) {
        add(x && typeof x === 'object' ? (x.url || x.contentUrl) : x);
      });
    }
    var container = galleryContainer(mainEl);
    var imgs = container ? container.querySelectorAll('img') : queryAll(CONFIG.galleryImages);
    for (var i = 0; i < imgs.length; i++) add(imageSrc(imgs[i]));
    return list.slice(0, 20);
  }

  // ---------- SKU ----------
  var SKU_RE = /SKU\s*[:\uFF1A]?\s*([A-Za-z0-9][A-Za-z0-9_-]{4,})/i;
  function readSku(ld, productId) {
    if (ld && ld.sku && String(ld.sku) !== String(productId)) return String(ld.sku);
    var el = query(CONFIG.sku);
    var txt = textOf(el);
    var m = txt.match(SKU_RE);
    if (m) return m[1];
    if (/^[A-Za-z0-9_-]{6,}$/.test(txt)) return txt;
    // Description section may be collapsed: textContent still contains it.
    // innerText skips hidden (old) pages; textContent also covers collapsed sections.
    m = ((document.body && document.body.innerText) || '').match(SKU_RE) ||
        ((document.body && document.body.textContent) || '').match(SKU_RE);
    if (m) return m[1];
    // Inline JSON of a directly-loaded product page ("goods_sn":"sw22...").
    var scripts = document.querySelectorAll('script:not([src])');
    for (var i = 0; i < scripts.length; i++) {
      var t = scripts[i].textContent || '';
      if (productId && t.indexOf(productId) === -1) continue;
      var mm = t.match(/"goods_sn"\s*:\s*"([^"]+)"/);
      if (mm) return mm[1];
    }
    return null;
  }

  // ---------- structured data (preferred) ----------
  function findLdProduct() {
    var scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (var i = 0; i < scripts.length; i++) {
      try {
        var data = JSON.parse(scripts[i].textContent);
        var stack = Array.isArray(data) ? data.slice() : [data];
        while (stack.length) {
          var node = stack.shift();
          if (!node || typeof node !== 'object') continue;
          var type = node['@type'];
          if (type === 'Product' || (Array.isArray(type) && type.indexOf('Product') !== -1)) return node;
          if (Array.isArray(node['@graph'])) stack = stack.concat(node['@graph']);
        }
      } catch (e) {}
    }
    return null;
  }
  function ldOffer(ld) {
    if (!ld || !ld.offers) return null;
    var o = Array.isArray(ld.offers) ? ld.offers[0] : ld.offers;
    return o || null;
  }
  function ldImage(ld) {
    if (!ld || !ld.image) return null;
    var img = Array.isArray(ld.image) ? ld.image[0] : ld.image;
    if (img && typeof img === 'object') img = img.url || img.contentUrl;
    return img || null;
  }

  // ---------- variants ----------
  // Only visible selected options count: hidden ones belong to a previously
  // opened product (SPA) and would report the wrong size.
  function findSelectedSize(options) {
    for (var i = 0; i < CONFIG.selectedSize.length; i++) {
      var list;
      try { list = document.querySelectorAll(CONFIG.selectedSize[i]); } catch (e) { continue; }
      for (var j = 0; j < list.length; j++) {
        var el = list[j];
        if (!isVisible(el) || /inactive|unactive|in-active/i.test(String(el.className || ''))) continue;
        var v = sizeLabel(el);
        if (v) return v;
      }
    }
    // Class names changed: look for an option marked as selected some other way.
    for (var k = 0; k < options.length; k++) {
      if (isSelectedOption(options[k])) {
        var w = sizeLabel(options[k]);
        if (w) return w;
      }
    }
    return null;
  }
  function readSize() {
    var options = [].filter.call(queryAll(CONFIG.sizeOptions), function (o) { return sizeLabel(o); });
    var value = findSelectedSize(options);
    if (!value && options.length === 1) value = sizeLabel(options[0]); // one-size product
    return {
      value: value,
      required: options.length > 1 && !value,
      debug: {
        options: options.slice(0, 12).map(function (o) { return sizeLabel(o) + ' [' + String(o.className || '').slice(0, 80) + ']'; })
      }
    };
  }
  function readColor(ld) {
    var el = query(CONFIG.selectedColor);
    if (el) {
      var img = el.tagName === 'IMG' ? el : el.querySelector('img');
      var v = el.getAttribute('aria-label') || el.getAttribute('title') ||
              (img && (img.getAttribute('alt') || img.getAttribute('title'))) || textOf(el);
      if (v) return v.trim();
    }
    var label = textOf(query(CONFIG.colorLabel)); // e.g. "اللون: أسود"
    var parts = label.split(/[:\uFF1A]/);
    if (parts.length > 1 && parts.slice(1).join(':').trim()) return parts.slice(1).join(':').trim();
    return (ld && typeof ld.color === 'string' && ld.color) || null;
  }

  // ---------- main ----------
  try {
    var idMatch = location.pathname.match(new RegExp(CONFIG.productIdPattern, 'i'));
    var productId = idMatch && idMatch[1];

    // Structured data is only trusted when it mentions the current product id.
    var ld = findLdProduct();
    if (ld && productId && JSON.stringify(ld).indexOf(productId) === -1) ld = null;
    var ogUrl = meta(['og:url']) || '';
    var ogOk = !!productId && ogUrl.indexOf(productId) !== -1;

    var offer = ldOffer(ld);
    var priceEl = query(CONFIG.price);
    var priceText = textOf(priceEl);
    // The currency symbol is sometimes in a sibling element, so also check the parent.
    var priceContext = priceText + ' ' + textOf(priceEl && priceEl.parentElement);
 var mainEl = largestVisibleImageEl() || query(CONFIG.mainImage);
    var mainSrc = firstValid([
      ldImage(ld),
      ogOk ? meta(['og:image']) : null,
      mainEl && imageSrc(mainEl)
    ]);
    var size = readSize();
    if (size.required) {
      send({ type: 'error', code: 'SIZE_REQUIRED', message: JSON.stringify(size.debug) });
      return;
    }

    send({
      type: 'product',
      data: {
        id: firstValid([productId, ld && (ld.sku || ld.productID)]),
        title: firstValid([
          productTitle(ld && ld.name),
          ogOk ? productTitle(meta(['og:title'])) : null,
          productTitle(textOf(query(CONFIG.title))),
          productTitle(document.title)
        ]),
        price: firstValid([
          toNumber(offer && (isEmpty(offer.price) ? offer.lowPrice : offer.price)),
          ogOk ? toNumber(meta(['product:price:amount', 'og:price:amount'])) : null,
          toNumber(priceText)
        ]),
        currency: firstValid([
          offer && offer.priceCurrency,
          ogOk ? meta(['product:price:currency', 'og:price:currency']) : null,
          currencyFromText(priceContext),
          currencyFromSite()
        ]),
        imageUrl: normImg(absUrl(mainSrc)),
        images: collectImages(ld, mainEl, absUrl(mainSrc)),
        sku: readSku(ld, productId),
        size: size.value,
        color: readColor(ld),
        url: location.href
      }
    });
  } catch (e) {
    send({ type: 'error', code: 'EXTRACTION_FAILED', message: String((e && e.message) || e) });
  }
})();
''';

  static const String _cartTemplate = r'''
(function () {
  var CONFIG = __CONFIG__;
  var PROBE = CONFIG.mode === 'probe';

  function send(payload) {
    payload.requestId = CONFIG.requestId;
    try { window[CONFIG.channel].postMessage(JSON.stringify(payload)); } catch (e) {}
  }
  function textOf(el) { return el ? (el.textContent || '').replace(/\s+/g, ' ').trim() : ''; }
  function spacedText(el) {
    if (!el) return '';
    var out = [], w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false);
    while (w.nextNode()) out.push(w.currentNode.nodeValue);
    return out.join(' ').replace(/\s+/g, ' ').trim();
  }
  function queryIn(root, selectors) {
    for (var i = 0; i < selectors.length; i++) {
      try { var el = root.querySelector(selectors[i]); if (el) return el; } catch (e) {}
    }
    return null;
  }
  function toNumber(v) {
    if (v === null || v === undefined || v === '') return null;
    var s = String(v)
      .replace(/[\u0660-\u0669]/g, function (d) { return String(d.charCodeAt(0) - 0x0660); })
      .replace(/\u066B/g, '.').replace(/\u066C/g, ',');
    var m = s.match(/\d[\d,]*(?:\.\d+)?/);
    if (!m) return null;
    var n = parseFloat(m[0].replace(/,/g, ''));
    return isNaN(n) ? null : n;
  }
  var CURRENCIES = [
    [/(^|[^A-Za-z])(SAR|SR)(?![A-Za-z])|\u0631\.?\s?\u0633/, 'SAR'],
    [/(^|[^A-Za-z])AED(?![A-Za-z])|\u062F\.?\s?\u0625/, 'AED'],
    [/(^|[^A-Za-z])(KWD|KD)(?![A-Za-z])|\u062F\.?\s?\u0643/, 'KWD'],
    [/(^|[^A-Za-z])(QAR|QR)(?![A-Za-z])|\u0631\.?\s?\u0642/, 'QAR'],
    [/(^|[^A-Za-z])(BHD|BD)(?![A-Za-z])|\u062F\.?\s?\u0628/, 'BHD'],
    [/(^|[^A-Za-z])(OMR|RO)(?![A-Za-z])|\u0631\.?\s?\u0639/, 'OMR'],
    [/(^|[^A-Za-z])(EGP|LE)(?![A-Za-z])|\u062C\.?\s?\u0645/, 'EGP'],
    [/(^|[^A-Za-z])(USD|US\$)(?![A-Za-z])|\$/, 'USD'],
    [/(^|[^A-Za-z])EUR(?![A-Za-z])|\u20AC/, 'EUR'],
    [/(^|[^A-Za-z])GBP(?![A-Za-z])|\u00A3/, 'GBP']
  ];
  function currencyFromText(t) {
    if (!t) return null;
    for (var i = 0; i < CURRENCIES.length; i++) if (CURRENCIES[i][0].test(t)) return CURRENCIES[i][1];
    return null;
  }
  function currencyFromSite() {
    var m = document.cookie.match(/(?:^|;\s*)currency=([A-Za-z]{3})/);
    return m ? m[1].toUpperCase() : null;
  }
  function imageSrc(img) {
    var c = [img.getAttribute('data-src'), img.getAttribute('src'), img.currentSrc];
    for (var i = 0; i < c.length; i++) {
      var u = c[i];
      if (!u || u.indexOf('data:') === 0) continue;
      u = String(u).trim();
      if (u.indexOf('//') === 0) u = 'https:' + u;
      return u.replace(/\.avif(?=$|[?#])/i, '.webp');
    }
    return null;
  }
  function absUrl(u) { try { return new URL(u, location.href).href; } catch (e) { return u; } }

  var ID_RE = new RegExp(CONFIG.productIdPattern, 'i');
  var EXCLUDE_RE = new RegExp(CONFIG.excludePattern, 'i');
  var PRICE_RE = /(?:US\$|SAR|SR|AED|KWD|KD|QAR|QR|BHD|BD|OMR|EGP|\$|\u20AC|\u00A3)?\s?\d[\d,]*[.\u066B]\d{1,2}/;
  var ID_ATTRS = ['data-goods-id', 'data-goods_id', 'goods-id', 'data-id'];

  function isExcluded(el) {
    for (var e = el; e && e !== document.body; e = e.parentElement) {
      if (EXCLUDE_RE.test(String(e.className || ''))) return true;
    }
    return false;
  }
  function productLinks(root) {
    var out = [];
    var links = root.tagName === 'A' ? [root] : root.querySelectorAll('a[href]');
    for (var i = 0; i < links.length; i++) {
      if (ID_RE.test(links[i].getAttribute('href') || '')) out.push(links[i]);
    }
    return out;
  }
  function idsIn(card) {
    var ids = {};
    var links = productLinks(card);
    for (var i = 0; i < links.length; i++) ids[(links[i].getAttribute('href') || '').match(ID_RE)[1]] = 1;
    for (var a = 0; a < ID_ATTRS.length; a++) {
      var own = card.getAttribute(ID_ATTRS[a]);
      if (own && /^\d{4,}$/.test(own)) ids[own] = 1;
      var inner = card.querySelectorAll('[' + ID_ATTRS[a] + ']');
      for (var j = 0; j < inner.length; j++) {
        var v = inner[j].getAttribute(ID_ATTRS[a]);
        if (/^\d{4,}$/.test(v || '')) ids[v] = 1;
      }
    }
    if (!Object.keys(ids).length) {
      var nodes = [card].concat([].slice.call(card.querySelectorAll('*'), 0, 200));
      for (var n = 0; n < nodes.length && !Object.keys(ids).length; n++) {
        var at = nodes[n].attributes || [];
        for (var k = 0; k < at.length; k++) {
          if (/goods|product|sku|item/i.test(at[k].name) && /^\d{5,}$/.test(at[k].value)) { ids[at[k].value] = 1; break; }
        }
        var cm = String(nodes[n].className || '').match(/(?:goods|item|product)[-_]?(\d{6,})/i);
        if (cm) ids[cm[1]] = 1;
      }
    }
    return Object.keys(ids);
  }
  function cardsFromSelectors() {
    for (var i = 0; i < CONFIG.items.length; i++) {
      var list;
      try { list = document.querySelectorAll(CONFIG.items[i]); } catch (e) { continue; }
      var cards = [].filter.call(list, function (c) { return !isExcluded(c); });
      if (cards.length) return cards;
    }
    return [];
  }
  function cardsFromLinks() {
    var cards = [];
    var links = productLinks(document.body);
    for (var i = 0; i < links.length; i++) {
      if (isExcluded(links[i])) continue;
      for (var e = links[i], d = 0; e && e !== document.body && d < 8; e = e.parentElement, d++) {
        if (e.querySelector('img') && PRICE_RE.test(textOf(e))) {
          if (idsIn(e).length === 1 && cards.indexOf(e) === -1) cards.push(e);
          break;
        }
      }
    }
    return normalizeCards(cards);
    
  }
  function cardsFromImages() {
    var cards = [];
    var imgs = document.images;
    for (var i = 0; i < imgs.length; i++) {
      var src = imageSrc(imgs[i]);
      if (!src || BAD_IMG.test(src) || isExcluded(imgs[i])) continue;
      var r = imgs[i].getBoundingClientRect();
      if (r.width * r.height > 0 && (r.width < 50 || r.height < 50)) continue;
      for (var e = imgs[i].parentElement, d = 0; e && e !== document.body && d < 7; e = e.parentElement, d++) {
        if (PRICE_RE.test(textOf(e)) && textOf(e).length < 600) {
          if (e.querySelectorAll('img').length <= 4 && cards.indexOf(e) === -1) cards.push(e);
          break;
        }
      }
    }
    return normalizeCards(cards);
  }
  var BAD_IMG = /logo|icon|sprite|badge|label|coupon|promo|activity|discount|\.svg|\.gif/i;
  function pickImage(card) {
    var best = null, bestScore = -1;
    var imgs = card.querySelectorAll('img');
    for (var i = 0; i < imgs.length; i++) {
      var src = imageSrc(imgs[i]);
      if (!src || BAD_IMG.test(src)) continue;
      var r = imgs[i].getBoundingClientRect();
      var area = r.width * r.height;
      if (area > 0 && (r.width < 50 || r.height < 50)) continue;
      var score = area + (/_thumbnail_|goods|images3/i.test(src) ? 1e7 : 0);
      if (score > bestScore) { bestScore = score; best = imgs[i]; }
    }
    return best;
  }
  function normalizeCards(cards) {
    var drop = [];
    cards.forEach(function (c) {
      var inner = cards.filter(function (o) { return o !== c && c.contains(o); });
      if (inner.length === 1) drop.push(inner[0]);
      else if (inner.length > 1) drop.push(c);
    });
    return cards.filter(function (c) { return drop.indexOf(c) === -1; });
  }

  function imgKey(u) {
    return (u || '').replace(/^https?:/, '').replace(/[?#].*$/, '').replace(/_thumbnail_\d+x\d*/i, '').replace(/\.\w+$/, '');
  }
  function guessTitle(card) {
    var best = '';
    var all = card.querySelectorAll('*');
    for (var i = 0; i < all.length; i++) {
      if (all[i].children.length) continue;
      var t = textOf(all[i]);
      if (t.length < 6 || t.length > 200 || PRICE_RE.test(t) || /^(x|\u00D7)\s?\d/i.test(t) || /\s\/\s/.test(t)) continue;
      if (t.length > best.length) best = t;
    }
    return best || null;
  }
  function guessAttr(card) {
    var all = card.querySelectorAll('*');
    for (var i = 0; i < all.length; i++) {
      if (all[i].children.length) continue;
      var t = textOf(all[i]);
      if (t.length <= 40 && /^[^\/]{1,25}\s?\/\s?[^\/]{1,12}$/.test(t) && !PRICE_RE.test(t)) return t;
    }
    return '';
  }
  function parseAttr(text) {
    text = (text || '').replace(/\s+/g, ' ').trim();
    if (!text || text.length > 60) return { size: null, color: null };
    var parts = text.split(/\s*[\/|,\u060C]\s*/).filter(function (p) { return p; });
    if (parts.length >= 2) return { color: parts[0], size: parts[parts.length - 1] };
    var one = parts[0] || '';
    var looksLikeSize = one.length <= 8 && /^(X{0,3}S|M|X{0,4}L|\d?XL|\d{1,3}(\.\d)?|one[\s-]?size)/i.test(one);
    return looksLikeSize ? { size: one, color: null } : { size: null, color: one };
  }
  function parseQty(card) {
    var el = queryIn(card, CONFIG.itemQty);
    var raw = el ? (el.value || textOf(el)) : '';
    var n = parseInt((raw.match(/\d{1,3}/) || [])[0], 10);
    if (!n) {
      var m = spacedText(card).match(/(?:^|\s)(?:x|\u00D7|Qty\s*[:\uFF1A]?|\u0627\u0644\u0643\u0645\u064A\u0629\s*[:\uFF1A]?)\s*(\d{1,3})(?!\d)/i);
      n = m ? parseInt(m[1], 10) : 1;
    }
    return n > 0 && n < 100 ? n : 1;
  }
  function parseCard(card) {
    var ids = idsIn(card);
    var link = productLinks(card)[0];
    var img = pickImage(card);
    var title = textOf(queryIn(card, CONFIG.itemTitle)) ||
      (img && img.getAttribute('alt')) ||
      (link && (link.getAttribute('title') || textOf(link))) ||
      guessTitle(card);
    var priceEl = queryIn(card, CONFIG.itemPrice);
    var priceText = priceEl && PRICE_RE.test(textOf(priceEl))
      ? textOf(priceEl)
      : ((spacedText(card).match(PRICE_RE) || [])[0] || '');
    var attr = parseAttr(textOf(queryIn(card, CONFIG.itemAttr)) || guessAttr(card));
    var sku = (spacedText(card).match(/SKU\s*[:\uFF1A]?\s*([A-Za-z0-9][A-Za-z0-9_-]{4,})/i) || [])[1] || null;
    var imageUrl = img ? imageSrc(img) : null;
    var id = ids[0] || (imageUrl ? 'img' + imgKey(imageUrl).replace(/[^A-Za-z0-9]/g, '').slice(-24) : null);
    return {
      id: id,
      title: title ? String(title).replace(/\s+/g, ' ').trim().slice(0, 200) : null,
      price: toNumber(priceText),
      currency: currencyFromText(priceText),
            imageUrl: imageUrl,
      images: imageUrl ? [imageUrl] : [],
      size: attr.size,
      color: attr.color,
      sku: sku,
      quantity: parseQty(card),
      url: link ? absUrl(link.getAttribute('href')) : (ids[0] ? location.origin + '/product-p-' + ids[0] + '.html' : location.href)
    };
  }
  
  function collect(cards) {
    var items = [], seen = {}, counts = {};
    for (var i = 0; i < cards.length; i++) {
      var it = parseCard(cards[i]);
      if (!it.id || !it.title || !(it.price > 0)) continue;
      var key = [it.id, it.size || '', it.color || ''].join('|');
      var key2 = [it.title, it.size || '', it.color || ''].join('|');
      if (seen[key] || seen[key2]) continue;
      seen[key] = 1;
      seen[key2] = 1;
      if (it.currency) counts[it.currency] = (counts[it.currency] || 0) + 1;
      items.push(it);
    }
    var cartCurrency = null, max = 0;
    for (var c in counts) if (counts[c] > max) { max = counts[c]; cartCurrency = c; }
    cartCurrency = cartCurrency || currencyFromSite();
    for (var j = 0; j < items.length; j++) items[j].currency = cartCurrency || items[j].currency;
    return items;
  }

  try {
    var strategy = 'selectors';
    var cards = cardsFromSelectors();
    var items = collect(cards);
    if (!items.length) { strategy = 'links'; cards = cardsFromLinks(); items = collect(cards); }
    if (!items.length) { strategy = 'images'; cards = cardsFromImages(); items = collect(cards); }
    if (PROBE) return items.length;
    send({
      type: 'cart',
      items: items,
      debug: {
        strategy: strategy,
        cards: cards.length,
        url: location.href,
        images: document.images.length,
        sample: cards[0] ? cards[0].outerHTML.replace(/\s+/g, ' ').slice(0, 800) : null
      }
    });
    return items.length;
  } catch (e) {
    if (PROBE) return 0;
    send({ type: 'error', code: 'CART_EXTRACTION_FAILED', message: String((e && e.message) || e) });
    return 0;
  }
})();
''';

  /// Chrome-style pull-to-refresh detection, posted to
  /// [AppConfig.pullToRefreshChannelName]:
  /// `'pull:<px>'` while pulling, then `'release'` or `'cancel'`.
  ///
  /// A pull only starts if the page (window and every scroll container
  /// around the touched element) is at scrollTop 0 when the finger goes
  /// down, so a drag that begins lower on the page only ever scrolls up.
  /// Idempotent: safe to run on every page load and URL change.
  static final String pullToRefresh = _pullToRefreshTemplate.replaceFirst(
    '__CHANNEL__',
    AppConfig.pullToRefreshChannelName,
  );

  static const String _pullToRefreshTemplate = r'''
(function () {
  if (window.__flutterPullToRefresh) return;
  var channel = window['__CHANNEL__'];
  if (!channel) return;
  window.__flutterPullToRefresh = true;

  var SLOP = 10;
  var startX = 0, startY = 0, armed = false, pulling = false;
  var opts = { capture: true, passive: true };

  function isAtTop(el) {
    var scroller = document.scrollingElement || document.documentElement;
    var root = Math.max(
      window.scrollY || 0,
      window.pageYOffset || 0,
      scroller.scrollTop || 0,
      document.documentElement.scrollTop || 0,
      (document.body && document.body.scrollTop) || 0,
      (window.visualViewport && window.visualViewport.pageTop) || 0
    );
    if (root > 0) return false;
    for (; el && el.nodeType === 1; el = el.parentElement) {
      if (el.scrollTop > 0) return false;
    }
    return true;
  }

  function stop(message) {
    if (pulling) channel.postMessage(message);
    armed = false;
    pulling = false;
  }

  window.addEventListener('touchstart', function (e) {
    pulling = false;
    armed = e.touches.length === 1 && isAtTop(e.target);
    if (armed) {
      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
    }
  }, opts);

  window.addEventListener('touchmove', function (e) {
    if (!armed) return;
    if (e.touches.length !== 1) { stop('cancel'); return; }
    var dx = e.touches[0].clientX - startX;
    var dy = e.touches[0].clientY - startY;
    if (!pulling) {
      if (Math.abs(dx) < SLOP && Math.abs(dy) < SLOP) return;
      // Scrolling the page down or swiping sideways: not a pull.
      if (dy <= Math.abs(dx)) { armed = false; return; }
      pulling = true;
    }
    if (!isAtTop(e.target)) { stop('cancel'); return; }
    channel.postMessage('pull:' + Math.max(0, Math.round(dy - SLOP)));
  }, opts);

  window.addEventListener('touchend', function () { stop('release'); }, opts);
  window.addEventListener('touchcancel', function () { stop('cancel'); }, opts);
})();
''';
}
