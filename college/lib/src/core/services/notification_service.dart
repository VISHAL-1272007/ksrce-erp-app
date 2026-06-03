import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

/// Notification Service — FastAPI backend-backed.
///
/// Replaces the previous Firebase Realtime Database implementation.
/// Uses periodic HTTP polling (every 30 s) and exposes the same
/// Stream-based API so the existing UI ([RealtimeNotificationsDashboard],
/// [DashboardShell] badge) works without any changes.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── Auth token ──────────────────────────────────────────────────────────
  String? _token;

  /// Call this after login so the service can authenticate its requests.
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Stream controllers (one per userId) ─────────────────────────────────
  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers =
      {};
  final Map<String, Timer> _timers = {};

  // ── Public API ───────────────────────────────────────────────────────────

  /// Starts (or returns existing) stream of notifications for [userId].
  /// Polls the backend every 30 seconds automatically.
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    if (!_controllers.containsKey(userId) ||
        _controllers[userId]!.isClosed) {
      final ctrl =
          StreamController<List<Map<String, dynamic>>>.broadcast();
      _controllers[userId] = ctrl;
      _startPolling(userId, ctrl);
    }
    return _controllers[userId]!.stream;
  }

  /// Stream that emits the count of unread notifications for [userId].
  Stream<int> getUnreadCountStream(String userId) {
    return getUserNotificationsStream(userId)
        .map((notifs) => notifs.where((n) => n['isRead'] != true).length);
  }

  /// Mark a single notification as read.
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      final resp = await http
          .put(
            Uri.parse(
                '${ApiConfig.baseUrl}/notifications/$notificationId/read'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) _refreshStream(userId);
    } catch (e) {
      debugPrint('[NotificationService] markRead error: $e');
    }
  }

  /// Mark all supplied notification IDs as read.
  Future<void> markAllNotificationsAsRead(
      String userId, List<String> notificationIds) async {
    for (final id in notificationIds) {
      await markNotificationAsRead(userId, id);
    }
  }

  /// Create a notification for a specific user.
  /// Only admin / faculty / HOD may call this successfully.
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? sender,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/notifications'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'message': message,
              'type': type,
              'sender': sender,
              'metadata':
                  metadata != null ? jsonEncode(metadata) : null,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 201) _refreshStream(userId);
    } catch (e) {
      debugPrint('[NotificationService] createNotification error: $e');
    }
  }

  /// Delete a notification owned by [userId].
  Future<void> deleteNotification(
      String userId, String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      final resp = await http
          .delete(
            Uri.parse(
                '${ApiConfig.baseUrl}/notifications/$notificationId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 204) _refreshStream(userId);
    } catch (e) {
      debugPrint('[NotificationService] deleteNotification error: $e');
    }
  }

  /// Broadcast a notification to multiple users.
  Future<void> createBatchNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    String? sender,
    Map<String, dynamic>? metadata,
  }) async {
    for (final uid in userIds) {
      await createNotification(
        userId: uid,
        title: title,
        message: message,
        type: type,
        sender: sender,
        metadata: metadata,
      );
    }
  }

  /// Returns default notification preferences (backend persistence TBD).
  Future<Map<String, dynamic>> getNotificationPreferences(
      String userId) async {
    return {
      'enableAssignments': true,
      'enableExams': true,
      'enableAttendance': true,
      'enableEvents': true,
      'enableGrades': true,
      'enableFees': true,
    };
  }

  /// Placeholder — will hit a preferences endpoint once added to backend.
  Future<void> updateNotificationPreferences(
      String userId, Map<String, dynamic> preferences) async {
    debugPrint(
        '[NotificationService] Preferences update not yet wired to backend.');
  }

  /// Stop polling and close the stream for [userId].
  void dispose(String userId) {
    _timers[userId]?.cancel();
    _timers.remove(userId);
    _controllers[userId]?.close();
    _controllers.remove(userId);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  void _startPolling(
      String userId,
      StreamController<List<Map<String, dynamic>>> ctrl) {
    _fetchAndEmit(userId, ctrl);
    _timers[userId]?.cancel();
    _timers[userId] = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ctrl.isClosed) {
        _timers[userId]?.cancel();
      } else {
        _fetchAndEmit(userId, ctrl);
      }
    });
  }

  Future<void> _fetchAndEmit(
      String userId,
      StreamController<List<Map<String, dynamic>>> ctrl) async {
    if (ctrl.isClosed) return;
    try {
      final resp = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final List<dynamic> raw = jsonDecode(resp.body);
        // Normalise backend snake_case → camelCase expected by the UI.
        final notifications = raw.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return {
            ...m,
            // UI reads 'notificationId' and 'isRead'
            'notificationId': m['id'],
            'isRead': (m['is_read'] == true || m['is_read'] == 1),
            'timestamp': m['timestamp'] ?? '',
          };
        }).toList()
          ..sort((a, b) {
            final ta =
                DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
            final tb =
                DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
            return tb.compareTo(ta);
          });

        if (!ctrl.isClosed) ctrl.add(notifications);
      }
    } catch (e) {
      debugPrint('[NotificationService] Polling error: $e');
    }
  }

  /// Re-fetch immediately after a mutation so the UI updates right away.
  void _refreshStream(String userId) {
    Future.delayed(const Duration(milliseconds: 400), () {
      final ctrl = _controllers[userId];
      if (ctrl != null && !ctrl.isClosed) _fetchAndEmit(userId, ctrl);
    });
  }
}
