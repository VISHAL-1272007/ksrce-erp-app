import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});
  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _targetAudience = 'All';

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DataService>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Send and manage notifications', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
            const SizedBox(height: 32),
            // Send notification
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Send New Notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),
                TextField(controller: _titleCtrl, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Title', labelStyle: const TextStyle(color: AppColors.textLight),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: _messageCtrl, style: const TextStyle(color: Colors.white), maxLines: 3,
                  decoration: InputDecoration(labelText: 'Message', labelStyle: const TextStyle(color: AppColors.textLight),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target: ', style: TextStyle(color: AppColors.textMedium)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['All', 'Students', 'Faculty'].map((t) => ChoiceChip(
                              label: Text(t), selected: _targetAudience == t,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(color: _targetAudience == t ? Colors.white : Colors.white54),
                              backgroundColor: AppColors.background,
                              onSelected: (v) => setState(() => _targetAudience = t),
                            )).toList(),
                          ),
                        ],
                      )
                    : Row(children: [
                        const Text('Target: ', style: TextStyle(color: AppColors.textMedium)),
                        const SizedBox(width: 8),
                        ...['All', 'Students', 'Faculty'].map((t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t), selected: _targetAudience == t,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: _targetAudience == t ? Colors.white : Colors.white54),
                            backgroundColor: AppColors.background,
                            onSelected: (v) => setState(() => _targetAudience = t),
                          ),
                        )),
                      ]),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  onPressed: () {
                    if (_titleCtrl.text.isEmpty) return;
                    ds.notifications.insert(0, {
                      'id': 'N${ds.notifications.length + 1}',
                      'title': _titleCtrl.text,
                      'message': _messageCtrl.text,
                      'date': DateTime.now().toString().substring(0, 10),
                      'read': false,
                      'type': 'announcement',
                    });
                    ds.notifyListeners();
                    _titleCtrl.clear(); _messageCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent!'), backgroundColor: Color(0xFF4CAF50)));
                    setState(() {});
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send Notification'),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // Existing notifications
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('All Notifications (${ds.notifications.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),
                ...ds.notifications.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(n['read'] == true ? Icons.mark_email_read : Icons.email, color: n['read'] == true ? Colors.white38 : const Color(0xFF42A5F5), size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n['title'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(n['message'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                    Text(n['date'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                  ]),
                )),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
