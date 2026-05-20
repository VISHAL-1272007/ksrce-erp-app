import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyStudentsPage extends StatelessWidget {
  const FacultyStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid);
      final mentees = ds.getMentees(fid);
      final allStudentIds = <String>{};
      final allStudents = <Map<String, dynamic>>[];
      for (final c in courses) {
        for (final s in ds.getCourseStudents(c['courseId'] as String? ?? '')) {
          if (allStudentIds.add(s['studentId'] as String? ?? '')) allStudents.add(s);
        }
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.people, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text('My Students', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              _stat('Total Students', '${allStudents.length}', AppColors.primary, Icons.people),
              const SizedBox(width: 16),
              _stat('Mentees', '${mentees.length}', Colors.green, Icons.person_pin),
              const SizedBox(width: 16),
              _stat('Courses', '${courses.length}', Colors.orange, Icons.class_),
            ]),
            const SizedBox(height: 24),
            if (mentees.isNotEmpty) _buildSection('Mentees', mentees),
            if (mentees.isNotEmpty) const SizedBox(height: 24),
            _buildSection('All Course Students', allStudents),
          ]),
        ),
      );
    });
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

  Widget _buildSection(String title, List<Map<String, dynamic>> students) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        ...students.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.15), radius: 18,
              child: Text((s['name'] ?? '?')[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
              Text('${s['studentId'] ?? ''} | ${s['departmentId'] ?? ''} | Year ${s['year'] ?? '-'}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ])),
            Text('CGPA: ${s['cgpa'] ?? '-'}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        )),
      ]),
    );
  }
}
