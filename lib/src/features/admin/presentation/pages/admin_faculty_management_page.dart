import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/delete_confirmation.dart';
import '../../../../core/theme/app_colors.dart';

class AdminFacultyManagementPage extends StatefulWidget {
  const AdminFacultyManagementPage({super.key});
  @override
  State<AdminFacultyManagementPage> createState() => _AdminFacultyManagementPageState();
}

class _AdminFacultyManagementPageState extends State<AdminFacultyManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final allFaculty = ds.faculty;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.person_add, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Faculty Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18), label: const Text('Add Faculty'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showAddFacultyDialog(context, ds),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${allFaculty.length} faculty members', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              ...allFaculty.map((f) {
                final deptCode = ds.getDepartmentCode(f['departmentId'] as String? ?? '');
                final fid = f['facultyId'] as String? ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text((f['name'] as String? ?? '?')[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(f['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                        if (f['isHOD'] == true) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: const Text('HOD', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)))],
                      ]),
                      Text('$fid | $deptCode | ${f['designation'] ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ])),
                    if (!isMobile) Text(f['email'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      tooltip: 'Edit Faculty',
                      onPressed: () => _showEditFacultyDialog(context, ds, f),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Delete Faculty',
                      onPressed: () => _confirmDeleteFaculty(context, ds, fid, f['name'] as String? ?? ''),
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

  void _showAddFacultyDialog(BuildContext context, DataService ds) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final desigC = TextEditingController();
    final qualC = TextEditingController();
    String? selectedDeptId;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Faculty', style: TextStyle(color: AppColors.textDark)),
      content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: selectedDeptId, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
          items: ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text('${d['departmentCode']} - ${d['departmentName']}', style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setS(() => selectedDeptId = v)),
        const SizedBox(height: 10),
        TextField(controller: desigC, decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: qualC, decoration: const InputDecoration(labelText: 'Qualification', border: OutlineInputBorder())),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            if (nameC.text.isNotEmpty && selectedDeptId != null) {
              ds.addFaculty({'name': nameC.text, 'email': emailC.text, 'phone': phoneC.text, 'departmentId': selectedDeptId, 'designation': desigC.text, 'qualification': qualC.text, 'specialization': '', 'dateOfJoining': DateTime.now().toIso8601String().substring(0, 10)});
              Navigator.pop(ctx); setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameC.text} added as faculty'), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
            }
          },
          child: const Text('Create'),
        ),
      ],
    )));
  }

  void _showEditFacultyDialog(BuildContext context, DataService ds, Map<String, dynamic> fac) {
    final nameC = TextEditingController(text: fac['name'] as String? ?? '');
    final emailC = TextEditingController(text: fac['email'] as String? ?? '');
    final phoneC = TextEditingController(text: fac['phone'] as String? ?? '');
    final desigC = TextEditingController(text: fac['designation'] as String? ?? '');
    final qualC = TextEditingController(text: fac['qualification'] as String? ?? '');
    final specC = TextEditingController(text: fac['specialization'] as String? ?? '');
    final expC = TextEditingController(text: '${fac['experience'] ?? ''}');
    final dojC = TextEditingController(text: fac['dateOfJoining'] as String? ?? '');
    String? selectedDeptId = fac['departmentId'] as String?;
    final fid = fac['facultyId'] as String? ?? '';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(children: [
        const Icon(Icons.edit, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text('Edit Faculty — $fid', style: const TextStyle(color: AppColors.textDark, fontSize: 18)),
      ]),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: selectedDeptId, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined), border: OutlineInputBorder()),
          items: ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text('${d['departmentCode']} - ${d['departmentName']}', style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setS(() => selectedDeptId = v)),
        const SizedBox(height: 10),
        TextField(controller: desigC, decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.work_outline), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: qualC, decoration: const InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: specC, decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.science_outlined), border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: expC, decoration: const InputDecoration(labelText: 'Experience (yrs)', prefixIcon: Icon(Icons.timeline), border: OutlineInputBorder()), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        TextField(controller: dojC, decoration: const InputDecoration(labelText: 'Date of Joining (YYYY-MM-DD)', prefixIcon: Icon(Icons.date_range), border: OutlineInputBorder())),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () {
            if (nameC.text.isNotEmpty) {
              ds.updateFaculty(fid, {
                'name': nameC.text,
                'email': emailC.text,
                'phone': phoneC.text,
                'departmentId': selectedDeptId,
                'designation': desigC.text,
                'qualification': qualC.text,
                'specialization': specC.text,
                'experience': int.tryParse(expC.text) ?? expC.text,
                'dateOfJoining': dojC.text,
              });
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${nameC.text} updated successfully'),
                backgroundColor: AppColors.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            }
          },
          label: const Text('Save Changes'),
        ),
      ],
    )));
  }

  void _confirmDeleteFaculty(BuildContext context, DataService ds, String fid, String name) {
    final confirmC = TextEditingController();
    final expectedText = buildDeleteConfirmationText(name);
    bool isValid = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text('Delete Faculty', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(style: const TextStyle(color: AppColors.textMedium, fontSize: 14), children: [
            const TextSpan(text: 'You are about to permanently delete '),
            TextSpan(text: '$name ($fid)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
            onChanged: (v) => setS(() => isValid = isDeleteConfirmationValid(entityName: name, userInput: v)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isValid ? Colors.red : Colors.grey, foregroundColor: Colors.white),
            onPressed: isValid ? () {
              ds.deleteFaculty(fid);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$name deleted permanently'), backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
            } : null,
            child: const Text('Delete Permanently'),
          ),
        ],
      );
    }));
  }
}
