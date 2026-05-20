import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminHodAssignmentPage extends StatefulWidget {
  const AdminHodAssignmentPage({super.key});
  @override
  State<AdminHodAssignmentPage> createState() => _AdminHodAssignmentPageState();
}

class _AdminHodAssignmentPageState extends State<AdminHodAssignmentPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final depts = ds.departments;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.supervisor_account, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('HOD Assignment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Assign Head of Department for each department', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              ...depts.map((d) {
                final deptId = d['departmentId'] as String;
                final hodId = d['hodId'] as String? ?? '';
                final hodName = hodId.isNotEmpty ? ds.getFacultyName(hodId) : 'Not Assigned';
                final deptFaculty = ds.getDepartmentFaculty(deptId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(d['departmentCode'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['departmentName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('Current HOD: $hodName', style: TextStyle(color: hodId.isNotEmpty ? AppColors.textMedium : Colors.orange, fontSize: 13)),
                    ])),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => _showAssignDialog(context, ds, deptId, deptFaculty, hodId),
                      child: Text(hodId.isNotEmpty ? 'Change' : 'Assign'),
                    ),
                  ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  void _showAssignDialog(BuildContext context, DataService ds, String deptId, List<Map<String, dynamic>> facList, String currentHodId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Assign HOD - ${ds.getDepartmentCode(deptId)}', style: const TextStyle(color: AppColors.textDark, fontSize: 16)),
      content: SizedBox(width: 350, child: ListView(shrinkWrap: true, children: facList.map((f) {
        final isCurrent = f['facultyId'] == currentHodId;
        return ListTile(
          leading: CircleAvatar(radius: 18, backgroundColor: isCurrent ? AppColors.accent.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
            child: Text((f['name'] as String? ?? '?')[0], style: TextStyle(color: isCurrent ? AppColors.accent : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))),
          title: Text(f['name'] as String? ?? '', style: TextStyle(color: AppColors.textDark, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          subtitle: Text(f['designation'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          trailing: isCurrent ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20) : null,
          onTap: () {
            ds.assignHOD(deptId, f['facultyId'] as String);
            Navigator.pop(ctx); setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f['name']} assigned as HOD'), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
          },
        );
      }).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
    ));
  }
}
