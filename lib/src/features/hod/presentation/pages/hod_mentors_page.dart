import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class HodMentorsPage extends StatefulWidget {
  const HodMentorsPage({super.key});
  @override
  State<HodMentorsPage> createState() => _HodMentorsPageState();
}

class _HodMentorsPageState extends State<HodMentorsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));

      final deptId = ds.currentFaculty?['departmentId'] as String? ?? '';
      final mentorAssigns = ds.getDepartmentMentorAssignments(deptId);
      final deptFaculty = ds.getDepartmentFaculty(deptId);
      final deptClasses = ds.getDepartmentClasses(deptId);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.group, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Mentor Assignment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Assign Mentor'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showAssignMentorDialog(context, ds, deptFaculty, deptClasses, deptId),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Manage mentor-mentee assignments for ${ds.getDepartmentCode(deptId)} department', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              if (mentorAssigns.isEmpty)
                Container(padding: const EdgeInsets.all(32), decoration: AppCardStyles.elevated,
                  child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.group_off, color: AppColors.textLight, size: 40),
                    SizedBox(height: 12),
                    Text('No mentor assignments yet', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Click "Assign Mentor" to create assignments', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ])))
              else
                ...mentorAssigns.map((m) {
                  final menteeIds = (m['menteeIds'] as List<dynamic>?)?.cast<String>() ?? [];
                  final mentees = menteeIds.map((id) => ds.getStudentById(id)).where((s) => s != null).toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: AppCardStyles.elevated,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: Colors.teal.withValues(alpha: 0.15), child: const Icon(Icons.person, color: Colors.teal, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['mentorName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          Text('Year ${m['year']} Section ${m['section']} | ${mentees.length} mentees', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                        ])),
                      ]),
                      if (mentees.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 24),
                        const Text('Mentees:', style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: mentees.map((s) => Chip(
                          avatar: CircleAvatar(radius: 12, backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: Text((s?['name'] as String? ?? '?')[0], style: const TextStyle(fontSize: 10, color: AppColors.primary))),
                          label: Text(s?['name'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.border),
                        )).toList()),
                      ],
                    ]),
                  );
                }),
            ]),
          );
        }),
      );
    });
  }

  void _showAssignMentorDialog(BuildContext context, DataService ds, List<Map<String, dynamic>> facList, List<Map<String, dynamic>> classList, String deptId) {
    String? selectedFacultyId;
    String? selectedClassId;
    List<String> selectedStudentIds = [];

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setDialogState) {
        final studentsInClass = selectedClassId != null
          ? ds.getStudentsForClass(selectedClassId!)
          : <Map<String, dynamic>>[];
        final selectedClass = selectedClassId != null ? classList.firstWhere((c) => c['classId'] == selectedClassId, orElse: () => <String, dynamic>{}) : null;

        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Assign Mentor', style: TextStyle(color: AppColors.textDark, fontSize: 16)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Select Faculty:', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedFacultyId, isExpanded: true,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: facList.map((f) => DropdownMenuItem(value: f['facultyId'] as String, child: Text(f['name'] as String? ?? '', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setDialogState(() => selectedFacultyId = v),
              ),
              const SizedBox(height: 16),
              const Text('Select Class:', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedClassId, isExpanded: true,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: classList.map((c) => DropdownMenuItem(value: c['classId'] as String, child: Text('Year ${c['year']} - Section ${c['section']}', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setDialogState(() { selectedClassId = v; selectedStudentIds.clear(); }),
              ),
              if (studentsInClass.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Select Mentees:', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(height: 8),
                ...studentsInClass.map((s) {
                  final id = s['studentId'] as String? ?? '';
                  return CheckboxListTile(
                    value: selectedStudentIds.contains(id),
                    title: Text(s['name'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                    dense: true, controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setDialogState(() { if (v == true) selectedStudentIds.add(id); else selectedStudentIds.remove(id); }),
                  );
                }),
              ],
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: selectedFacultyId != null && selectedStudentIds.isNotEmpty ? () {
                ds.assignMentor(selectedFacultyId!, selectedStudentIds, deptId, selectedClass?['year'] as int? ?? 0, selectedClass?['section'] as String? ?? '');
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mentor assigned with ${selectedStudentIds.length} mentees'), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
              } : null,
              child: const Text('Assign'),
            ),
          ],
        );
      });
    });
  }
}
