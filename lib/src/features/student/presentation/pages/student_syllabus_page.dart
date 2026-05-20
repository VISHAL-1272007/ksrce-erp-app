import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentSyllabusPage extends StatelessWidget {
  const StudentSyllabusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final studentCourses = ds.getStudentCourses(uid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.menu_book, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Syllabus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Course-wise syllabus and completion tracking', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              if (studentCourses.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No courses found', style: TextStyle(color: AppColors.textLight, fontSize: 16)))),
              ...studentCourses.map((course) {
                final courseId = course['courseId'] ?? '';
                final syllabi = ds.getCourseSyllabus(courseId);
                if (syllabi.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: AppCardStyles.elevated,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$courseId - ${course['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Syllabus not yet uploaded', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    ]),
                  );
                }
                final syl = syllabi.first;
                final units = (syl['units'] as List<dynamic>?) ?? [];
                final progress = ds.getSyllabusProgress(syl);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: AppCardStyles.elevated,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('$courseId - ${course['courseName'] ?? syl['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text('${progress.toStringAsFixed(0)}% Complete', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: progress / 100, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                    const SizedBox(height: 16),
                    ...units.map((u) {
                      final totalH = (u['totalHours'] as int?) ?? 1;
                      final compH = (u['completedHours'] as int?) ?? 0;
                      final unitProgress = totalH > 0 ? compH / totalH : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text('Unit ${u['unitNumber'] ?? '-'}: ${u['title'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14))),
                            Text('$compH/$totalH hrs', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                          ]),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: unitProgress, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(unitProgress >= 1 ? Colors.green : AppColors.accent)),
                          const SizedBox(height: 4),
                          Text((u['topics'] as List<dynamic>?)?.join(', ') ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                        ]),
                      );
                    }),
                  ]),
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
