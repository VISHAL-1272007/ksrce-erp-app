import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optimized persistence layer for KSRCE ERP.
///
/// Optimizations applied:
/// 1. **Local-first loading** — instant startup from localStorage
class PersistenceService {
  static const String _localKey = 'ksrce_erp_data';
  static const String _versionKey = 'ksrce_erp_version';
  static const int _currentVersion = 4;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ──────────────────── LOCAL CACHE (SharedPreferences) ───────────────

  /// Returns true if localStorage has cached data.
  static bool hasLocalData() {
    return _prefs?.containsKey(_localKey) ?? false;
  }

  /// Save to local cache (fast).
  static Future<void> saveLocal(Map<String, dynamic> data) async {
    if (_prefs == null) await init();
    await _prefs!.setString(_localKey, json.encode(data));
    await _prefs!.setInt(_versionKey, _currentVersion);
  }

  /// Load from local cache (synchronous, instant).
  static Map<String, dynamic>? loadLocal() {
    if (_prefs == null) return null;
    final version = _prefs!.getInt(_versionKey) ?? 0;
    if (version < _currentVersion) {
      return null;
    }
    final s = _prefs!.getString(_localKey);
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(s));
    } catch (_) {
      return null;
    }
  }

  /// Clear all local data.
  static Future<void> clearAll() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_localKey);
    await _prefs!.remove(_versionKey);
  }

  // ──────────────────── UNIFIED API (OPTIMIZED) ──────────────────────

  /// Saves locally IMMEDIATELY. Cloud syncing is handled by FastAPI.
  static Future<void> saveAll(Map<String, dynamic> data,
      {List<String>? changedKeys}) async {
    // Save locally right away (instant, ~5ms)
    await saveLocal(data);
  }

  /// Kept for compatibility.
  static Future<void> flush() async {
    // No-op for now. Cloud syncing is handled by FastAPI.
  }

  /// **LOCAL-FIRST LOADING**
  /// Returns local data instantly.
  static Future<Map<String, dynamic>?> loadLocalFirst({
    void Function(Map<String, dynamic> cloudData)? onCloudUpdate,
  }) async {
    // 1) Return local cache instantly
    final local = loadLocal();
    return local;
  }

  /// Full seed save (used only on first run).
  static Future<void> seedSave(Map<String, dynamic> data) async {
    await saveLocal(data);
  }
}
