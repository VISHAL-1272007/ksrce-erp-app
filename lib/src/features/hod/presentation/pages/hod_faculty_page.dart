import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class HodFacultyPage extends StatelessWidget {
  const HodFacultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));

      final deptId = ds.currentFaculty?['departmentId'] as String? ?? '';
      final facultyList = ds.getDepartmentFaculty(deptId);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.people, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Department Faculty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              Text('${ds.getDepartmentCode(deptId)} Department - ${facultyList.length} faculty members', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              ...facultyList.map((f) {
                final courses = ds.getFacultyCourses(f['facultyId'] as String? ?? '');
                final mentees = ds.getMentees(f['facultyId'] as String? ?? '');
                final isHOD = f['isHOD'] == true;
                final isAdviser = f['isClassAdviser'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isHOD ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(radius: 22, backgroundColor: isHOD ? AppColors.accent.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15),
                        child: Text((f['name'] as String? ?? '?').split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase(),
                          style: TextStyle(color: isHOD ? AppColors.accent : AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(f['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          if (isHOD) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: const Text('HOD', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)))],
                          if (isAdviser) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: const Text('Adviser', style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)))],
                        ]),
                        const SizedBox(height: 4),
                        Text('${f['designation'] ?? ''} | ${f['qualification'] ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ])),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _infoBadge(Icons.menu_book, '${courses.length} courses', AppColors.primary),
                      const SizedBox(width: 8),
                      _infoBadge(Icons.people, '${mentees.length} mentees', Colors.teal),
                      const SizedBox(width: 8),
                      _infoBadge(Icons.email, f['email'] as String? ?? '', AppColors.textLight),
                    ]),
                  ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(color: color, fontSize: 11), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
