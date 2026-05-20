import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class HodNotificationsPage extends StatelessWidget {
  const HodNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final notifs = ds.notifications;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            Expanded(child: notifs.isEmpty
              ? const Center(child: Text('No notifications', style: TextStyle(color: AppColors.textLight)))
              : ListView.builder(itemCount: notifs.length, itemBuilder: (ctx, i) {
                  final n = notifs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                    decoration: AppCardStyles.raised,
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.notifications, color: AppColors.primary, size: 18)),
                      title: Text(n['title'] as String? ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(n['message'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ),
                  );
                })),
          ]),
        ),
      );
    });
  }
}
