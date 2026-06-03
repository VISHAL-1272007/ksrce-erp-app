import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    // Default to today's tab index (Mon=0 ... Sat=5), fallback to 0
    int todayIdx = DateTime.now().weekday - 1; // 1=Mon -> 0
    if (todayIdx < 0 || todayIdx > 5) todayIdx = 0;
    _tabController = TabController(length: _days.length, vsync: this, initialIndex: todayIdx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Weekly Timetable', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Current Semester Schedule', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: isMobile,
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textLight,
                  tabs: _days.map((d) => Tab(text: d.substring(0, 3).toUpperCase())).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _days.map((day) => _buildDaySchedule(ds, day, isMobile)).toList(),
                ),
              ),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildDaySchedule(DataService ds, String day, bool isMobile) {
    final periods = ds.getTimetableForDay(day);
    if (periods.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.weekend, color: AppColors.textLight.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 12),
          Text('No classes on $day', style: const TextStyle(color: AppColors.textLight, fontSize: 16)),
        ]),
      );
    }
    return ListView.builder(
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final p = periods[index];
        final type = p['type'] as String? ?? 'Lecture';
        final isLab = type == 'Lab';
        final timeStr = '${p['startTime'] ?? ''} - ${p['endTime'] ?? ''}';
        final subject = '${p['courseCode'] ?? ''} - ${p['courseName'] ?? ''}';
        final room = p['room'] as String? ?? '';
        final faculty = p['facultyName'] as String? ?? '';
        final barColor = isLab ? Colors.teal : AppColors.primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isLab ? Colors.teal.withValues(alpha: 0.4) : AppColors.border),
          ),
          child: isMobile
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 4, height: 70, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(timeStr, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: barColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(type, style: TextStyle(color: barColor, fontSize: 11)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(subject, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.room, color: AppColors.textLight, size: 14),
                      const SizedBox(width: 3),
                      Text(room, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.person, color: AppColors.textLight, size: 14),
                      const SizedBox(width: 3),
                      Flexible(child: Text(faculty, style: const TextStyle(color: AppColors.textLight, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ]),
                  ])),
                ])
              : Row(children: [
                  Container(width: 4, height: 50, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 16),
                  SizedBox(width: 130, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(timeStr, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(type, style: TextStyle(color: barColor, fontSize: 12)),
                  ])),
                  const SizedBox(width: 16),
                  Expanded(child: Text(subject, style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w500))),
                  SizedBox(width: 100, child: Row(children: [
                    const Icon(Icons.room, color: AppColors.textLight, size: 16),
                    const SizedBox(width: 4),
                    Text(room, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ])),
                  SizedBox(width: 150, child: Row(children: [
                    const Icon(Icons.person, color: AppColors.textLight, size: 16),
                    const SizedBox(width: 4),
                    Text(faculty, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ])),
                ]),
        );
      },
    );
  }
}
