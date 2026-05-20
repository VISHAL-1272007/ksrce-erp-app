import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final studentId = ds.currentUserId ?? '';
      final coursesList = ds.getStudentCourses(studentId);
      final totalCredits = coursesList.fold<int>(0, (sum, c) => sum + ((c['credits'] as int?) ?? 0));

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.menu_book, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('My Courses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Current Semester Courses', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildCourseSummary(coursesList.length, totalCredits),
              const SizedBox(height: 24),
              ...coursesList.map((c) => _buildCourseCard(c, isMobile)),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildCourseSummary(int count, int credits) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _summaryItem('Total Courses', '$count', Icons.book),
        _summaryItem('Total Credits', '$credits', Icons.stars),
      ]),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: AppColors.primary, size: 24),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
    ]);
  }

  Widget _buildCourseCard(Map<String, dynamic> c, bool isMobile) {
    final code = c['courseCode'] as String? ?? '';
    final name = c['courseName'] as String? ?? '';
    final faculty = c['facultyName'] as String? ?? '';
    final credits = c['credits']?.toString() ?? '0';
    final dept = c['department'] as String? ?? '';
    final room = c['room'] as String? ?? '';
    final schedule = c['schedule'] as String? ?? '';
    final total = c['totalClasses'] ?? 0;
    final attended = c['attendedClasses'] ?? 0;
    final attPct = total > 0 ? (attended / total * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(code, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('$attPct% att.', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 12),
        isMobile
            ? Wrap(spacing: 12, runSpacing: 8, children: [
                _iconText(Icons.person, faculty),
                _iconText(Icons.stars, '$credits Credits'),
                _iconText(Icons.room, room),
                _iconText(Icons.business, dept),
                if (schedule.isNotEmpty) _iconText(Icons.schedule, schedule),
              ])
            : Row(children: [
                const Icon(Icons.person, color: AppColors.textLight, size: 16), const SizedBox(width: 6),
                Text(faculty, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(width: 24),
                const Icon(Icons.stars, color: AppColors.textLight, size: 16), const SizedBox(width: 6),
                Text('$credits Credits', style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(width: 24),
                const Icon(Icons.room, color: AppColors.textLight, size: 16), const SizedBox(width: 6),
                Text(room, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(width: 24),
                const Icon(Icons.business, color: AppColors.textLight, size: 16), const SizedBox(width: 6),
                Text(dept, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
              ]),
      ]),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textLight, size: 16),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
    ]);
  }
}
