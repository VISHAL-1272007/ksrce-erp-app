import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class HodCoursesPage extends StatelessWidget {
  const HodCoursesPage({super.key});

  static void _showPaperPatternDialog(
      BuildContext context, DataService ds, Map<String, dynamic> course) {
    final courseId = course['courseId'] as String? ?? '';
    final courseName = course['courseName'] as String? ?? '';
    const examType = 'Internal 1';
    final existing = ds.getQuestionPaperPattern(courseId, examType);

    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '50 Marks Pattern');
    final notesCtrl = TextEditingController(text: existing?['notes']?.toString() ?? 'Part-A: 5 x 2 = 10 marks; Part-B: 8 x 5 = 40 marks');
    final q6Ctrl = TextEditingController(text: existing?['partB']?['q6Rule']?.toString() ?? '6(A) or 6(B) — choose one');
    final q7Ctrl = TextEditingController(text: existing?['partB']?['q7Rule']?.toString() ?? '7(A) / 7(B) / 7(C) — any two');
    final q8Ctrl = TextEditingController(text: existing?['partB']?['q8Rule']?.toString() ?? '8(A) / 8(B) / 8(C) — any two');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Paper Pattern • $courseId'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(courseName, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Pattern Title')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Pattern Notes')),
              const SizedBox(height: 12),
              const Text(
                'Part-A: 5 questions × 2 marks each = 10 marks\n'
                'Part-B: 8 questions × 5 marks each = 40 marks\n'
                'Q6: choose 1 of 2 (6A / 6B)\n'
                'Q7: any 2 of 3 (7A / 7B / 7C)\n'
                'Q8: any 2 of 3 (8A / 8B / 8C)',
                style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(controller: q6Ctrl, decoration: const InputDecoration(labelText: 'Q6 Rule')),
              const SizedBox(height: 8),
              TextField(controller: q7Ctrl, decoration: const InputDecoration(labelText: 'Q7 Rule')),
              const SizedBox(height: 8),
              TextField(controller: q8Ctrl, decoration: const InputDecoration(labelText: 'Q8 Rule')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ds.saveQuestionPaperPattern(courseId, examType, {
                'title': titleCtrl.text.trim(),
                'notes': notesCtrl.text.trim(),
                'totalMarks': 50,
                'partA': {
                  'questions': 5,
                  'marksPerQuestion': 2,
                  'total': 10,
                  'minPerQuestion': 0,
                  'maxPerQuestion': 2,
                },
                'partB': {
                  'questions': 8,
                  'marksPerQuestion': 5,
                  'total': 40,
                  'q6Rule': q6Ctrl.text.trim(),
                  'q7Rule': q7Ctrl.text.trim(),
                  'q8Rule': q8Ctrl.text.trim(),
                },
                'updatedBy': ds.currentUserId ?? '',
                'updatedAt': DateTime.now().toIso8601String(),
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper pattern saved')));
            },
            child: const Text('Save Pattern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded)
        return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()));

      final deptId = ds.currentFaculty?['departmentId'] as String? ?? '';
      final deptCourses = ds.getDepartmentCourses(deptId);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.menu_book, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Department Courses',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              Text(
                  '${ds.getDepartmentCode(deptId)} Department - ${deptCourses.length} courses',
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(
                    onPressed: () =>
                        _showCourseDialog(context, ds, deptId, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Course')),
                const SizedBox(width: 12),
                const Text('Manage department courses',
                    style: TextStyle(color: AppColors.textLight))
              ]),
              const SizedBox(height: 16),
              ...deptCourses.map((c) {
                final enrolledCount =
                    ds.getCourseStudents(c['courseId'] as String? ?? '').length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: AppCardStyles.elevated,
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(c['courseCode'] as String? ?? '',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(c['courseName'] as String? ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(
                              'Faculty: ${c['facultyName'] ?? 'N/A'} | ${c['credits']} credits | $enrolledCount enrolled | Sem ${c['semester'] ?? ''}',
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 12)),
                        ])),
                    const SizedBox(width: 12),
                    Column(children: [
                      IconButton(
                        onPressed: () => _showPaperPatternDialog(context, ds, c),
                        icon: const Icon(Icons.description_outlined, size: 20)),
                      IconButton(
                          onPressed: () =>
                              _showCourseDialog(context, ds, deptId, c),
                          icon: const Icon(Icons.edit, size: 20)),
                      IconButton(
                          onPressed: () => _confirmDeleteCourse(
                              context, ds, c['courseId'] as String? ?? ''),
                          icon: const Icon(Icons.delete, size: 20))
                    ])
                  ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  static void _saveCOPOFromText(DataService ds, String courseId, String courseName, String? facultyId, String cosText, String posText) {
    final coLines = cosText
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final poLines = posText
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (coLines.isEmpty && poLines.isEmpty) return;

    final cos = <Map<String, dynamic>>[];
    for (var i = 0; i < coLines.length; i++) {
      cos.add({
        'coId': 'CO${i + 1}',
        'description': coLines[i],
        'bloomsLevel': '',
        'bloomsCode': '',
        'poMapping': <String>[]
      });
    }

    final pos = <Map<String, dynamic>>[];
    for (var i = 0; i < poLines.length; i++) {
      pos.add({'poId': 'PO${i + 1}', 'description': poLines[i]});
    }

    ds.addCourseOutcomeEntry({
      'courseId': courseId,
      'courseName': courseName,
      'facultyId': facultyId ?? '',
      'departmentId': ds.getCourseById(courseId)?['departmentId'] ?? '',
      'regulation': 'R2021',
      'courseType': 'core',
      'totalCredits': ds.getCourseById(courseId)?['credits'] ?? 3,
      'lectureHours': 3,
      'tutorialHours': 0,
      'practicalHours': 0,
      'courseObjectives': <String>[],
      'courseOutcomes': cos,
      'poList': pos,
      'unitCOMapping': <Map<String, dynamic>>[],
      'textbooks': <Map<String, dynamic>>[],
      'references': <Map<String, dynamic>>[],
      'onlineResources': <String>[],
      'lastUpdated': DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  static void _confirmDeleteCourse(
      BuildContext context, DataService ds, String courseId) {
    showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
              title: const Text('Delete course'),
              content: const Text(
                  'Are you sure you want to delete this course? This will unenroll students.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      ds.deleteCourse(courseId);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Delete'))
              ]);
        });
  }

  static void _showCourseDialog(BuildContext context, DataService ds,
      String departmentId, Map<String, dynamic>? existing) {
    final codeC =
        TextEditingController(text: existing?['courseCode'] as String? ?? '');
    final nameC =
        TextEditingController(text: existing?['courseName'] as String? ?? '');
    final creditsC =
        TextEditingController(text: (existing?['credits']?.toString()) ?? '3');
    final semC =
        TextEditingController(text: (existing?['semester']?.toString()) ?? '1');
    final cosC = TextEditingController();
    final posC = TextEditingController();
    String? selectedFaculty = existing?['facultyId'] as String?;

    final deptFaculty = ds.getDepartmentFaculty(departmentId);

    showDialog<void>(
        context: context,
        builder: (ctx) {
          // Prefill COs/POs if course outcome details exist
          if (existing != null && existing['courseId'] != null) {
            final details = ds.getCourseOutcomeDetails(existing['courseId']);
            if (details != null) {
              final coList = ((details['courseOutcomes'] as List<dynamic>?) ?? [])
                  .map((c) => c['description']?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
              final poList = ((details['poList'] as List<dynamic>?) ?? [])
                  .map((p) => p['description']?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
              cosC.text = coList.join('\n');
              posC.text = poList.join('\n');
            }
          }
          return AlertDialog(
              title: Text(existing == null ? 'Add Course' : 'Edit Course'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: codeC,
                    decoration:
                        const InputDecoration(labelText: 'Course Code')),
                TextField(
                    controller: nameC,
                    decoration:
                        const InputDecoration(labelText: 'Course Name')),
                TextField(
                    controller: creditsC,
                    decoration: const InputDecoration(labelText: 'Credits'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: semC,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(
                  controller: cosC,
                  decoration: const InputDecoration(
                    labelText: 'Course Outcomes (one per line)',
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: posC,
                  decoration: const InputDecoration(
                    labelText: 'Program Outcomes (one per line)',
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                    builder: (ctx2, setS) => DropdownButtonFormField<String?>(
                        initialValue: selectedFaculty,
                        decoration: const InputDecoration(
                            labelText: 'Assign Faculty (optional)'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Unassigned')),
                          ...deptFaculty.map((f) => DropdownMenuItem(
                              value: f['facultyId'] as String?,
                              child: Text(f['name'] as String? ?? '')))
                        ],
                        onChanged: (v) => setS(() => selectedFaculty = v))),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      final payload = {
                        'courseCode': codeC.text.toUpperCase(),
                        'courseName': nameC.text,
                        'departmentId': departmentId,
                        'department': ds.getDepartmentName(departmentId),
                        'facultyId': selectedFaculty ?? '',
                        'facultyName': selectedFaculty != null
                            ? (ds.faculty.firstWhere(
                                    (f) => f['facultyId'] == selectedFaculty,
                                    orElse: () => {})['name'] ??
                                '')
                            : '',
                        'credits': int.tryParse(creditsC.text) ?? 3,
                        'semester': int.tryParse(semC.text) ?? 1,
                        'sections': <String>[],
                        'room': '',
                        'schedule': ''
                      };

                      if (existing == null) {
                        ds.addCourse(payload);
                        // create course outcome details if COs/POs provided
                        final newCourseId = payload['courseId'];
                        _saveCOPOFromText(ds, newCourseId, nameC.text, selectedFaculty, cosC.text, posC.text);
                      } else {
                        ds.updateCourse(
                            existing['courseId'] as String, payload);
                        _saveCOPOFromText(ds, existing['courseId'], nameC.text, selectedFaculty, cosC.text, posC.text);
                      }

                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Save'))
              ]);
        });
  }
}
