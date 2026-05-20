import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class FacultyNotificationsPage extends StatelessWidget {
  const FacultyNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final notifs = ds.notifications;
      final unread = ds.getUnreadNotifications();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.notifications, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const Spacer(),
              if (unread.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Text('${unread.length} unread', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 24),
            if (notifs.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No notifications', style: TextStyle(color: AppColors.textLight, fontSize: 16)))),
            ...notifs.map((n) {
              final isRead = n['isRead'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(isRead ? Icons.notifications_none : Icons.notifications_active, color: isRead ? AppColors.textLight : AppColors.primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['title'] ?? '', style: TextStyle(color: AppColors.textDark, fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(n['message'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(n['date'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                  ])),
                  if (!isRead) IconButton(
                    icon: const Icon(Icons.done, color: AppColors.primary, size: 20),
                    onPressed: () => ds.markNotificationRead(n['notificationId'] ?? ''),
                  ),
                ]),
              );
            }),
          ]),
        ),
      );
    });
  }
}
