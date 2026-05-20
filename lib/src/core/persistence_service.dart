import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Optimized persistence layer for KSRCE ERP.
///
/// Optimizations applied:
/// 1. **Local-first loading** — instant startup from localStorage
/// 2. **Per-collection cloud writes** — only changed collections are pushed
/// 3. **Debounced cloud saves** — batches rapid mutations into one write
/// 4. Background cloud sync after local load
class PersistenceService {
  static const String _rtdbUrl =
      'https://ksrce-campus-erp-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const String _localKey = 'ksrce_erp_data';
  static const String _versionKey = 'ksrce_erp_version';
  static const int _currentVersion = 3;

  static SharedPreferences? _prefs;

  // ──────────────────── DEBOUNCE STATE ────────────────────────────────
  static Timer? _debounceTimer;
  static Map<String, dynamic>? _pendingData;
  static final Set<String> _dirtyCollections = {};
  static const Duration _debounceDuration = Duration(seconds: 2);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ──────────────────── CLOUD (Firebase RTDB REST) ────────────────────

  /// Save specific collections to Firebase RTDB (PATCH = merge, not overwrite).
  static Future<bool> saveCollectionsToCloud(
      Map<String, dynamic> collections) async {
    try {
      final resp = await http
          .patch(
            Uri.parse('$_rtdbUrl/erp_data.json'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(collections),
          )
          .timeout(const Duration(seconds: 12));
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Cloud save failed: $e');
      return false;
    }
  }

  /// Save ALL data to Firebase (used only for first-time seed).
  static Future<bool> saveAllToCloud(Map<String, dynamic> data) async {
    try {
      final resp = await http
          .put(
            Uri.parse('$_rtdbUrl/erp_data.json'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Cloud save failed: $e');
      return false;
    }
  }

  /// Load all data from Firebase Realtime Database.
  static Future<Map<String, dynamic>?> loadFromCloud() async {
    try {
      final resp = await http
          .get(Uri.parse('$_rtdbUrl/erp_data.json'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && resp.body != 'null') {
        return Map<String, dynamic>.from(json.decode(resp.body));
      }
    } catch (e) {
      debugPrint('Cloud load failed: $e');
    }
    return null;
  }

  /// Load specific collections from cloud (for role-based lazy load).
  static Future<Map<String, dynamic>> loadCollectionsFromCloud(
      List<String> keys) async {
    final result = <String, dynamic>{};
    try {
      // Parallel fetch of individual collections
      final futures = keys.map((key) async {
        try {
          final resp = await http
              .get(Uri.parse('$_rtdbUrl/erp_data/$key.json'))
              .timeout(const Duration(seconds: 6));
          if (resp.statusCode == 200 && resp.body != 'null') {
            return MapEntry(key, json.decode(resp.body));
          }
        } catch (_) {}
        return MapEntry(key, null);
      });
      final entries = await Future.wait(futures);
      for (final e in entries) {
        if (e.value != null) result[e.key] = e.value;
      }
    } catch (e) {
      debugPrint('Cloud collection load failed: $e');
    }
    return result;
  }

  /// Delete all cloud data (for "Reset Database").
  static Future<void> clearCloud() async {
    try {
      await http
          .delete(Uri.parse('$_rtdbUrl/erp_data.json'))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Cloud clear failed: $e');
    }
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
    final s = _prefs!.getString(_localKey);
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(s));
    } catch (_) {
      return null;
    }
  }

  /// Clear all local + cloud data.
  static Future<void> clearAll() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_localKey);
    await _prefs!.remove(_versionKey);
    _debounceTimer?.cancel();
    _pendingData = null;
    _dirtyCollections.clear();
    await clearCloud();
  }

  // ──────────────────── UNIFIED API (OPTIMIZED) ──────────────────────

  /// Debounced save: saves locally IMMEDIATELY, then batches cloud writes.
  /// [changedKeys] lists which collections were modified (for per-collection cloud PATCH).
  static Future<void> saveAll(Map<String, dynamic> data,
      {List<String>? changedKeys}) async {
    // 1) Save locally right away (instant, ~5ms)
    await saveLocal(data);

    // 2) Track dirty collections for batched cloud push
    if (changedKeys != null && changedKeys.isNotEmpty) {
      _dirtyCollections.addAll(changedKeys);
    } else {
      // If caller doesn't specify, mark everything dirty
      _dirtyCollections.addAll(data.keys);
    }
    _pendingData = data;

    // 3) Debounce cloud save — wait 2 seconds of inactivity, then push
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _flushToCloud();
    });
  }

  /// Flush pending dirty collections to cloud immediately.
  static Future<void> _flushToCloud() async {
    final data = _pendingData;
    final dirty = Set<String>.from(_dirtyCollections);
    _pendingData = null;
    _dirtyCollections.clear();

    if (data == null || dirty.isEmpty) return;

    // Build a map of only the changed collections
    final patch = <String, dynamic>{};
    for (final key in dirty) {
      if (data.containsKey(key)) {
        patch[key] = data[key];
      }
    }

    if (patch.isNotEmpty) {
      await saveCollectionsToCloud(patch);
    }
  }

  /// Force-flush any pending cloud writes (call before app close / reset).
  static Future<void> flush() async {
    _debounceTimer?.cancel();
    await _flushToCloud();
  }

  /// **LOCAL-FIRST LOADING**
  /// Returns local data instantly. Cloud sync happens in background.
  /// [onCloudUpdate] is called if cloud has newer data.
  static Future<Map<String, dynamic>?> loadLocalFirst({
    void Function(Map<String, dynamic> cloudData)? onCloudUpdate,
  }) async {
    // 1) Return local cache instantly
    final local = loadLocal();

    // 2) Fetch cloud in background and merge if available
    _syncFromCloud(local, onCloudUpdate);

    return local;
  }

  /// Background cloud sync — fires onCloudUpdate if cloud has data.
  static Future<void> _syncFromCloud(
    Map<String, dynamic>? localData,
    void Function(Map<String, dynamic>)? onCloudUpdate,
  ) async {
    try {
      final cloud = await loadFromCloud();
      if (cloud != null) {
        // Update local cache with cloud data
        await saveLocal(cloud);
        if (onCloudUpdate != null) {
          onCloudUpdate(cloud);
        }
      }
    } catch (e) {
      debugPrint('Background cloud sync failed: $e');
    }
  }

  /// Full seed save (used only on first run) — writes everything to cloud.
  static Future<void> seedSave(Map<String, dynamic> data) async {
    await saveLocal(data);
    // Fire-and-forget full PUT for seed data
    saveAllToCloud(data);
  }
}
