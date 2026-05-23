import 'package:firebase_database/firebase_database.dart';

/// Real-Time Notification Service
/// Handles Firebase Cloud Messaging and real-time notifications via Realtime Database
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Get real-time stream of notifications for a user
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _db
        .ref('notifications/$userId')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return [];
          
          return data.entries
              .map((e) => {
                'notificationId': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              })
              .toList()
              ..sort((a, b) {
                final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
                final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
                return timeB.compareTo(timeA);
              });
        });
  }

  /// Get unread notifications count stream
  Stream<int> getUnreadCountStream(String userId) {
    return getUserNotificationsStream(userId).map((notifs) =>
        notifs.where((n) => n['isRead'] != true).length);
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _db
        .ref('notifications/$userId/$notificationId')
        .update({'isRead': true, 'readAt': DateTime.now().toIso8601String()});
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId, List<String> notificationIds) async {
    for (final notifId in notificationIds) {
      await markNotificationAsRead(userId, notifId);
    }
  }

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'assignment', 'exam', 'attendance', 'event', 'alert', 'grade'
    String? sender,
    Map<String, dynamic>? metadata,
  }) async {
    final notificationId = _db.ref('notifications/$userId').push().key!;
    
    await _db.ref('notifications/$userId/$notificationId').set({
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'sender': sender,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      'metadata': metadata ?? {},
    });
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _db.ref('notifications/$userId/$notificationId').remove();
  }

  /// Batch create notifications for multiple users
  Future<void> createBatchNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    String? sender,
    Map<String, dynamic>? metadata,
  }) async {
    for (final userId in userIds) {
      await createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        sender: sender,
        metadata: metadata,
      );
    }
  }

  /// Get notification preferences for a user
  Future<Map<String, dynamic>> getNotificationPreferences(String userId) async {
    final snapshot = await _db.ref('users/$userId/notificationPreferences').get();
    if (!snapshot.exists) {
      return {
        'enableAssignments': true,
        'enableExams': true,
        'enableAttendance': true,
        'enableEvents': true,
        'enableGrades': true,
        'enableFees': true,
      };
    }
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    await _db
        .ref('users/$userId/notificationPreferences')
        .update(preferences);
  }
}
