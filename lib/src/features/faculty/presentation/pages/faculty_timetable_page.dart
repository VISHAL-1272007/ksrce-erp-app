import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyTimetablePage extends StatelessWidget {
  const FacultyTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final days = ds.getFacultyTimetableDays(fid);
      final weeklyHours = ds.getFacultyWeeklyHours(fid);
      final allDays = days.isNotEmpty ? days : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

      return DefaultTabController(
        length: allDays.length,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.calendar_view_week, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Text('Timetable', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text('$weeklyHours hrs/week', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 16),
                TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textLight,
                  indicatorColor: AppColors.primary,
                  tabs: allDays.map((d) => Tab(text: d)).toList(),
                ),
              ]),
            ),
            Expanded(child: TabBarView(
              children: allDays.map((day) {
                final slots = ds.getFacultyTimetableForDay(fid, day);
                if (slots.isEmpty) {
                  return const Center(child: Text('No classes scheduled', style: TextStyle(color: AppColors.textLight, fontSize: 16)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: slots.length,
                  itemBuilder: (context, i) {
                    final s = slots[i];
                    final type = (s['type'] ?? 'Theory').toString();
                    final color = type == 'Lab' ? Colors.green : type == 'Break' ? Colors.grey : AppColors.primary;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: AppCardStyles.elevated,
                      child: Row(children: [
                        Container(width: 4, height: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['time'] ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(type, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(width: 20),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['courseId'] ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(s['courseName'] ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                        ])),
                        Text(s['room'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ]),
                    );
                  },
                );
              }).toList(),
            )),
          ]),
        ),
      );
    });
  }
}
