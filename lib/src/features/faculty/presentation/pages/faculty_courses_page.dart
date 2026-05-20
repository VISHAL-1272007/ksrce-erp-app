import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyCoursesPage extends StatelessWidget {
  const FacultyCoursesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.class_, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text('My Courses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 8),
            Text('${courses.length} courses assigned this semester', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
            const SizedBox(height: 24),
            _buildStats(courses, ds),
            const SizedBox(height: 24),
            _buildCourseCards(courses, ds),
          ]),
        ),
      );
    });
  }

  Widget _buildStats(List<Map<String, dynamic>> courses, DataService ds) {
    int totalStudents = 0;
    for (final c in courses) {
      totalStudents += ds.getCourseStudents(c['courseId'] as String? ?? '').length;
    }
    return Row(children: [
      _stat('Total Courses', '${courses.length}', AppColors.primary, Icons.class_),
      const SizedBox(width: 16),
      _stat('Total Students', '$totalStudents', Colors.green, Icons.people),
      const SizedBox(width: 16),
      _stat('Weekly Hours', '${courses.fold(0, (sum, c) => sum + ((c['hoursPerWeek'] as int?) ?? 3))}', Colors.orange, Icons.schedule),
    ]);
  }

  Widget _stat(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
      ]),
    ));
  }

  Widget _buildCourseCards(List<Map<String, dynamic>> courses, DataService ds) {
    if (courses.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No courses assigned', style: TextStyle(color: AppColors.textLight, fontSize: 16))));
    }
    return Wrap(spacing: 16, runSpacing: 16, children: courses.map((c) {
      final cid = c['courseId'] as String? ?? '';
      final studentCount = ds.getCourseStudents(cid).length;
      final syllabi = ds.getCourseSyllabus(cid);
      final progress = syllabi.isNotEmpty ? ds.getSyllabusProgress(syllabi.first) : 0.0;
      return SizedBox(width: 380, child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.class_, color: AppColors.primary, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cid, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(c['courseName'] ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
            ])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _info(Icons.people, '$studentCount students'),
            const SizedBox(width: 16),
            _info(Icons.schedule, '${c['hoursPerWeek'] ?? 3} hrs/week'),
            const SizedBox(width: 16),
            _info(Icons.credit_score, '${c['credits'] ?? '-'} credits'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Syllabus Progress', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
            const Spacer(),
            Text('${progress.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress / 100, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
        ]),
      ));
    }).toList());
  }

  Widget _info(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: AppColors.textLight, size: 14),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
    ]);
  }
}
