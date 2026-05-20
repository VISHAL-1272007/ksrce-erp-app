import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminClassManagementPage extends StatefulWidget {
  const AdminClassManagementPage({super.key});
  @override
  State<AdminClassManagementPage> createState() => _AdminClassManagementPageState();
}

class _AdminClassManagementPageState extends State<AdminClassManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final allClasses = ds.classes;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.class_, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Class Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18), label: const Text('Add Class'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showAddClassDialog(context, ds),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${allClasses.length} classes', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              ...allClasses.map((c) {
                final deptCode = ds.getDepartmentCode(c['departmentId'] as String? ?? '');
                final adviserId = c['classAdviserId'] as String? ?? '';
                final adviserName = adviserId.isNotEmpty ? ds.getFacultyName(adviserId) : 'Not Assigned';
                final studentCount = (c['studentIds'] as List<dynamic>?)?.length ?? 0;
                final courseCount = (c['courseIds'] as List<dynamic>?)?.length ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text('$deptCode Y${c['year']} ${c['section']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))),
                      const Spacer(),
                      Text('$studentCount students | $courseCount courses', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ]),
                    const SizedBox(height: 10),
                    Text('Adviser: $adviserName', style: TextStyle(color: adviserId.isNotEmpty ? AppColors.textDark : Colors.orange, fontSize: 13)),
                  ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  void _showAddClassDialog(BuildContext context, DataService ds) {
    String? selectedDeptId;
    final yearC = TextEditingController();
    final sectionC = TextEditingController();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Class', style: TextStyle(color: AppColors.textDark)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: selectedDeptId, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
          items: ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text('${d['departmentCode']}', style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setS(() => selectedDeptId = v)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: yearC, decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: sectionC, decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            if (selectedDeptId != null && yearC.text.isNotEmpty && sectionC.text.isNotEmpty) {
              final code = ds.getDepartmentCode(selectedDeptId!);
              final classId = '${code}_${yearC.text}_${sectionC.text.toUpperCase()}';
              ds.addClass({'classId': classId, 'departmentId': selectedDeptId, 'year': int.tryParse(yearC.text) ?? 1, 'section': sectionC.text.toUpperCase(), 'classAdviserId': '', 'studentIds': <String>[], 'courseIds': <String>[]});
              Navigator.pop(ctx); setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class $classId created'), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
            }
          },
          child: const Text('Create'),
        ),
      ],
    )));
  }
}
