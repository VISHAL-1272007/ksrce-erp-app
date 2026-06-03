import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminCourseManagementPage extends StatefulWidget {
  const AdminCourseManagementPage({super.key});
  @override
  State<AdminCourseManagementPage> createState() => _AdminCourseManagementPageState();
}

class _AdminCourseManagementPageState extends State<AdminCourseManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final allCourses = ds.courses;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.menu_book, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Course Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18), label: const Text('Add Course'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showAddCourseDialog(context, ds),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${allCourses.length} courses', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              ...allCourses.map((c) {
                final enrolled = ds.getCourseStudents(c['courseId'] as String? ?? '').length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(c['courseCode'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['courseName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                      Text('Faculty: ${c['facultyName'] ?? 'N/A'} | ${c['credits']} credits | Dept: ${ds.getDepartmentCode(c['departmentId'] as String? ?? '')} | $enrolled enrolled', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ])),
                  ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  void _showAddCourseDialog(BuildContext context, DataService ds) {
    final codeC = TextEditingController();
    final nameC = TextEditingController();
    final creditsC = TextEditingController();
    final semC = TextEditingController();
    final roomC = TextEditingController();
    final schedC = TextEditingController();
    String? selectedDeptId;
    String? selectedFacultyId;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
      final filteredFaculty = selectedDeptId != null ? ds.getDepartmentFaculty(selectedDeptId!) : <Map<String, dynamic>>[];
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Course', style: TextStyle(color: AppColors.textDark)),
        content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeC, decoration: const InputDecoration(labelText: 'Course Code', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Course Name', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: selectedDeptId, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
            items: ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text('${d['departmentCode']}', style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setS(() { selectedDeptId = v; selectedFacultyId = null; })),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: selectedFacultyId, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Faculty', border: OutlineInputBorder()),
            items: filteredFaculty.map((f) => DropdownMenuItem(value: f['facultyId'] as String, child: Text(f['name'] as String? ?? '', style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => selectedFacultyId = v)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: creditsC, decoration: const InputDecoration(labelText: 'Credits', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: semC, decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          TextField(controller: roomC, decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: schedC, decoration: const InputDecoration(labelText: 'Schedule', hintText: 'Mon, Wed 10:00-11:00', border: OutlineInputBorder())),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (codeC.text.isNotEmpty && nameC.text.isNotEmpty && selectedDeptId != null) {
                ds.addCourse({'courseCode': codeC.text.toUpperCase(), 'courseName': nameC.text, 'departmentId': selectedDeptId, 'department': ds.getDepartmentName(selectedDeptId!), 'facultyId': selectedFacultyId ?? '', 'credits': int.tryParse(creditsC.text) ?? 3, 'semester': int.tryParse(semC.text) ?? 1, 'sections': <String>[], 'room': roomC.text, 'schedule': schedC.text});
                Navigator.pop(ctx); setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameC.text} course created'), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
              }
            },
            child: const Text('Create'),
          ),
        ],
      );
    }));
  }
}
