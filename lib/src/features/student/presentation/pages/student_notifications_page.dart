import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class StudentNotificationsPage extends StatelessWidget {
  const StudentNotificationsPage({super.key});

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final allNotifs = ds.notifications;
      final unread = allNotifs.where((n) => n['isRead'] == false).length;

      final Map<String, IconData> typeIcons = {
        'assignment': Icons.assignment, 'exam': Icons.event_note, 'attendance': Icons.fact_check,
        'event': Icons.celebration, 'alert': Icons.warning_amber,
      };
      final Map<String, Color> typeColors = {
        'assignment': Colors.blue, 'exam': Colors.orange, 'attendance': AppColors.error,
        'event': AppColors.secondary, 'alert': Colors.orange,
      };

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.notifications, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(width: 12),
              if (unread > 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                child: Text('$unread new', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  for (var n in allNotifs) {
                    if (n['isRead'] == false) {
                      ds.markNotificationRead(n['notificationId'] as String? ?? '');
                    }
                  }
                },
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Mark all as read'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('Stay updated with academic and college activities', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
            const SizedBox(height: 20),
            Expanded(
              child: allNotifs.isEmpty
                  ? const Center(child: Text('No notifications', style: TextStyle(color: AppColors.textLight)))
                  : ListView.builder(
                      itemCount: allNotifs.length,
                      itemBuilder: (context, index) {
                        final n = allNotifs[index];
                        final isRead = n['isRead'] == true;
                        final type = (n['type'] as String?) ?? 'alert';
                        final icon = typeIcons[type] ?? Icons.notifications;
                        final color = typeColors[type] ?? AppColors.primary;
                        final timeStr = _formatTime(n['timestamp'] as String?);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isRead ? AppColors.border : color.withValues(alpha: 0.3)),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                if (!isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                                Expanded(child: Text(n['title'] as String? ?? '', style: TextStyle(color: AppColors.textDark, fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(type, style: TextStyle(color: color, fontSize: 11)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(n['message'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text(timeStr, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                                if (n['sender'] != null) ...[
                                  const SizedBox(width: 12),
                                  Text('From: ${n['sender']}', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                                ],
                              ]),
                            ])),
                          ]),
                        );
                      },
                    ),
            ),
          ]),
        ),
      );
    });
  }
}
