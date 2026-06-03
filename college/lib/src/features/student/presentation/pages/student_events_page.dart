import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentEventsPage extends StatelessWidget {
  const StudentEventsPage({super.key});

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'technical': return Colors.purple;
      case 'sports': return Colors.green;
      case 'academic': return Colors.blue;
      case 'cultural': return Colors.orange;
      case 'workshop': return Colors.cyan;
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'technical': return Icons.code;
      case 'sports': return Icons.sports;
      case 'academic': return Icons.school;
      case 'cultural': return Icons.music_note;
      case 'workshop': return Icons.computer;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final upcoming = ds.getUpcomingEvents();
      final registered = ds.getStudentRegisteredEvents(uid);
      final past = ds.getCompletedEvents();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.event, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('College events, workshops, and activities', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildUpcomingEvents(upcoming, ds, uid),
              const SizedBox(height: 24),
              _buildRegisteredEvents(registered),
              const SizedBox(height: 24),
              _buildPastEvents(past),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUpcomingEvents(List<Map<String, dynamic>> events, DataService ds, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.upcoming, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 16),
          if (events.isEmpty) const Center(child: Text('No upcoming events', style: TextStyle(color: AppColors.textLight))),
          ...events.map((e) {
            final type = (e['type'] ?? '').toString();
            final color = _typeColor(type);
            final isReg = ds.isStudentRegisteredForEvent(uid, e['eventId'] ?? '');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_typeIcon(type), color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text(type, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(e['description'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text(e['date'] ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text(e['venue'] ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isReg ? null : () => ds.registerForEvent(uid, e['eventId'] ?? ''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReg ? Colors.grey : color.withValues(alpha: 0.2),
                        foregroundColor: isReg ? Colors.white : color,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(isReg ? 'Registered' : 'Register'),
                    ),
                  ]),
                ])),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRegisteredEvents(List<Map<String, dynamic>> registered) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.how_to_reg, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('My Registered Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 16),
          if (registered.isEmpty) const Center(child: Text('No registered events', style: TextStyle(color: AppColors.textLight))),
          ...registered.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                Text('${r['date'] ?? ''} | ${r['venue'] ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Text('Confirmed', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildPastEvents(List<Map<String, dynamic>> past) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.history, color: AppColors.textLight, size: 20),
            SizedBox(width: 8),
            Text('Past Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 16),
          if (past.isEmpty) const Center(child: Text('No past events', style: TextStyle(color: AppColors.textLight))),
          ...past.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                Text(p['date'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
              Text(p['type'] ?? '', style: const TextStyle(color: AppColors.accent, fontSize: 12)),
            ]),
          )),
        ],
      ),
    );
  }
}
