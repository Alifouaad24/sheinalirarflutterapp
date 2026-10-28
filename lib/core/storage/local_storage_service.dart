import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around [SharedPreferences].
///
/// Registered once as a permanent GetX service in `main()` before `runApp`,
/// then injected wherever local persistence is needed. Keys come from
/// `StorageKeys`.
class LocalStorageService extends GetxService {
  late final SharedPreferences _prefs;

  Future<LocalStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // --- String ---------------------------------------------------------------
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  // --- bool -----------------------------------------------------------------
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  // --- int ------------------------------------------------------------------
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  // --- JSON object ----------------------------------------------------------
  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  /// Returns null when the key is missing or the stored value is not a JSON object.
  Map<String, dynamic>? getJson(String key) {
    final decoded = _decode(key);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  // --- JSON list ------------------------------------------------------------
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));

  /// Returns null when the key is missing or the stored value is not a JSON list.
  List<Map<String, dynamic>>? getJsonList(String key) {
    final decoded = _decode(key);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // --- Housekeeping ---------------------------------------------------------
  bool containsKey(String key) => _prefs.containsKey(key);
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();

  dynamic _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null; // Corrupted value: behave as if nothing was stored.
    }
  }
}
