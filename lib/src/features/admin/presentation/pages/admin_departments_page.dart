import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/delete_confirmation.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDepartmentsPage extends StatefulWidget {
  const AdminDepartmentsPage({super.key});
  @override
  State<AdminDepartmentsPage> createState() => _AdminDepartmentsPageState();
}

class _AdminDepartmentsPageState extends State<AdminDepartmentsPage> {
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
              Row(children: [
                const Icon(Icons.business, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Department Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18), label: const Text('Add Department'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showDeptFormDialog(context, ds, null),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${depts.length} departments', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              if (depts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: const Center(child: Column(children: [
                    Icon(Icons.business_outlined, size: 48, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('No departments yet', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Click "Add Department" to create your first department.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ])),
                ),
              ...depts.map((d) {
                final deptId = d['departmentId'] as String? ?? '';
                final hodId = d['hodId'] as String? ?? '';
                final hodName = hodId.isNotEmpty ? ds.getFacultyName(hodId) : 'Not Assigned';
                final facCount = ds.getDepartmentFaculty(deptId).length;
                final stuCount = ds.getDepartmentStudents(deptId).length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(d['departmentCode'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(d['departmentName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark))),
                      IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.primary), tooltip: 'Edit Department',
                        onPressed: () => _showDeptFormDialog(context, ds, d)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), tooltip: 'Delete Department',
                        onPressed: () => _confirmDeleteDepartment(context, ds, deptId, d['departmentName'] as String? ?? '')),
                    ]),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _badge(Icons.supervisor_account, 'HOD: $hodName', hodId.isNotEmpty ? AppColors.secondary : Colors.orange),
                      _badge(Icons.people, '$facCount faculty', AppColors.primary),
                      _badge(Icons.school, '$stuCount students', Colors.teal),
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

  Widget _badge(IconData icon, String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Flexible(child: Text(text, style: TextStyle(color: color, fontSize: 11), overflow: TextOverflow.ellipsis))]));
  }

  void _showDeptFormDialog(BuildContext context, DataService ds, Map<String, dynamic>? dept) {
    final isEdit = dept != null;
    final nameC = TextEditingController(text: isEdit ? dept['departmentName'] as String? ?? '' : '');
    final codeC = TextEditingController(text: isEdit ? dept['departmentCode'] as String? ?? '' : '');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(isEdit ? Icons.edit : Icons.add_business, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(isEdit ? 'Edit Department' : 'Add Department', style: const TextStyle(color: AppColors.textDark)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: InputDecoration(labelText: 'Department Name *', prefixIcon: const Icon(Icons.business_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        TextField(controller: codeC, enabled: !isEdit, decoration: InputDecoration(labelText: 'Department Code (e.g. CSE) *', prefixIcon: const Icon(Icons.code, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          helperText: isEdit ? 'Code cannot be changed' : null)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            if (nameC.text.trim().isEmpty || (!isEdit && codeC.text.trim().isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating));
              return;
            }
            if (isEdit) {
              ds.updateDepartment(dept['departmentId'] as String, {'departmentName': nameC.text.trim()});
            } else {
              ds.addDepartment({'departmentName': nameC.text.trim(), 'departmentCode': codeC.text.trim().toUpperCase(), 'hodId': ''});
            }
            Navigator.pop(ctx);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isEdit ? '${nameC.text.trim()} updated' : '${nameC.text.trim()} department created'),
              backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
          },
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    ));
  }

  void _confirmDeleteDepartment(BuildContext context, DataService ds, String deptId, String deptName) {
    final confirmC = TextEditingController();
    final expectedText = buildDeleteConfirmationText(deptName);
    bool isValid = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text('Delete Department', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(style: const TextStyle(color: AppColors.textMedium, fontSize: 14), children: [
            const TextSpan(text: 'You are about to permanently delete '),
            TextSpan(text: deptName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const TextSpan(text: '. This action cannot be undone.\n\n'),
            const TextSpan(text: 'To confirm, type: ', style: TextStyle(fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Text(expectedText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmC,
            decoration: InputDecoration(
              labelText: 'Type confirmation text',
              prefixIcon: const Icon(Icons.keyboard, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isValid ? Colors.green : AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isValid ? Colors.green : AppColors.primary, width: 2)),
            ),
            onChanged: (v) => setS(() => isValid = isDeleteConfirmationValid(entityName: deptName, userInput: v)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isValid ? Colors.red : Colors.grey, foregroundColor: Colors.white),
            onPressed: isValid ? () {
              ds.deleteDepartment(deptId);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$deptName deleted permanently'), backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
            } : null,
            child: const Text('Delete Permanently'),
          ),
        ],
      );
    }));
  }
}
