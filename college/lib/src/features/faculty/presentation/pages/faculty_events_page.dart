import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyEventsPage extends StatefulWidget {
  const FacultyEventsPage({super.key});

  @override
  State<FacultyEventsPage> createState() => _FacultyEventsPageState();
}

class _FacultyEventsPageState extends State<FacultyEventsPage> {

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final upcoming = ds.getUpcomingEvents();
      final past = ds.getCompletedEvents();

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateEvent(context, ds),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('Events & Activities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3))),
              ]),
              const SizedBox(height: 24),
              if (isMobile)
                Row(children: [
                  Expanded(child: _statCard('Upcoming', '${upcoming.length}', Icons.upcoming_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Past', '${past.length}', Icons.history_rounded, const Color(0xFF8B5CF6))),
                ])
              else
                Row(children: [
                  Expanded(child: _statCard('Upcoming', '${upcoming.length}', Icons.upcoming_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Past', '${past.length}', Icons.history_rounded, const Color(0xFF8B5CF6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Total', '${upcoming.length + past.length}', Icons.event_note_rounded, const Color(0xFF10B981))),
                ]),
              const SizedBox(height: 28),
              _buildSection('Upcoming Events', upcoming, const Color(0xFF3B82F6), ds),
              const SizedBox(height: 24),
              _buildSection('Past Events', past, const Color(0xFF8B5CF6), ds),
            ]),
          );
        }),
      );
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.statCard(color),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> events, Color accent, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(title.contains('Upcoming') ? Icons.upcoming_rounded : Icons.history_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('No ${title.toLowerCase()}', style: const TextStyle(color: AppColors.textLight))),
          ),
        ...events.map((e) {
          final type = (e['type'] ?? '').toString();
          final eventId = e['eventId'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.1)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.event_rounded, color: accent, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(e['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(type, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 6),
                Text(e['description'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.calendar_today, color: AppColors.textLight, size: 14),
                  const SizedBox(width: 4),
                  Text(e['date'] ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, color: AppColors.textLight, size: 14),
                  const SizedBox(width: 4),
                  Text(e['venue'] ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                ]),
              ])),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    ds.deleteEvent(eventId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Event deleted'), backgroundColor: Color(0xFFF43F5E),
                    ));
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                  ])),
                ],
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  void _showCreateEvent(BuildContext context, DataService ds) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    String eventType = 'Workshop';
    final types = ['Workshop', 'Seminar', 'Guest Lecture', 'Conference', 'Hackathon', 'Cultural', 'Sports', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Create Event', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Event Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, style: const TextStyle(color: AppColors.textDark), maxLines: 3, decoration: _inputDeco('Description')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: eventType,
                decoration: _inputDeco('Type'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDlgState(() => eventType = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: dateCtrl, style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDeco('Date'), readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: venueCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Venue'))),
              ]),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (nameCtrl.text.isEmpty || dateCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Name and date are required'), backgroundColor: Color(0xFFF43F5E),
                  ));
                  return;
                }
                ds.addEvent({
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'type': eventType,
                  'date': dateCtrl.text,
                  'venue': venueCtrl.text.isNotEmpty ? venueCtrl.text : 'TBD',
                  'organizer': ds.currentUserId ?? '',
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Event "${nameCtrl.text}" created!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}
