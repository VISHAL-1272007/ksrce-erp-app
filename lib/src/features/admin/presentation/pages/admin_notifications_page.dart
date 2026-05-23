import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../shared/presentation/pages/realtime_notifications_dashboard.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});
  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _targetAudience = 'All';
  bool _isSending = false;

  Future<void> _sendNotification(DataService ds) async {
    if (_titleCtrl.text.isEmpty) return;
    
    setState(() => _isSending = true);
    
    try {
      // In a real app, you would fetch user IDs based on _targetAudience.
      // For now, we'll simulate sending to the current mock user so it shows up.
      // E.g. ds.currentUserId
      final targetUserId = ds.currentUserId ?? 'ADM001';
      
      await NotificationService().createNotification(
        userId: targetUserId,
        title: _titleCtrl.text,
        message: _messageCtrl.text,
        type: 'alert',
        sender: 'Admin',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Color(0xFF4CAF50))
        );
        _titleCtrl.clear();
        _messageCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DataService>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Notifications Management', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Send announcements and alerts', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                const SizedBox(height: 24),
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
                      onPressed: _isSending ? null : () => _sendNotification(ds),
                      icon: _isSending 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                      label: Text(_isSending ? 'Sending...' : 'Send Notification'),
                    ),
                  ]),
                ),
              ]),
            ),
            // Embed RealtimeNotificationsDashboard in the rest of the space
            const Expanded(
              child: RealtimeNotificationsDashboard(),
            ),
          ],
        );
      },
    );
  }
}
