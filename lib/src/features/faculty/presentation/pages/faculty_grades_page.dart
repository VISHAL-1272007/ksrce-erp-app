import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyGradesPage extends StatefulWidget {
  const FacultyGradesPage({super.key});

  @override
  State<FacultyGradesPage> createState() => _FacultyGradesPageState();
}

class _FacultyGradesPageState extends State<FacultyGradesPage> {
  String? _selectedCourse;
  String _examType = 'Internal 1';

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid, masterKey: ds.activeMasterKey);
      if (_selectedCourse == null || !courses.any((c) => c['courseId'] == _selectedCourse)) {
        _selectedCourse = courses.first['courseId'] as String?;
      }
        final results = _selectedCourse != null
          ? ds.results.where((r) => r['courseId'] == _selectedCourse && (r['examType'] ?? '') == _examType).toList()
          : <Map<String, dynamic>>[];
      final students = _selectedCourse != null
          ? ds.getCourseStudents(_selectedCourse!)
          : <Map<String, dynamic>>[];

      final gradeMap = <String, int>{};
      for (final r in results) {
        final grade = r['grade'] ?? 'N/A';
        gradeMap[grade] = (gradeMap[grade] ?? 0) + 1;
      }
      final graded = results.where((r) => r['grade'] != null && r['grade'] != '-').length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.grading_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('Grade Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3))),
              ]),
              const SizedBox(height: 24),
              // Stats row
              if (isMobile)
                Column(children: [
                  Row(children: [
                    Expanded(child: _statCard('Students', '${students.length}', Icons.people_rounded, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Graded', '$graded', Icons.check_circle_rounded, const Color(0xFF10B981))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('Pending', '${students.length - graded}', Icons.pending_rounded, const Color(0xFFF97316))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Results', '${results.length}', Icons.assessment_rounded, const Color(0xFF8B5CF6))),
                  ]),
                ])
              else
                Row(children: [
                  Expanded(child: _statCard('Students', '${students.length}', Icons.people_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Graded', '$graded', Icons.check_circle_rounded, const Color(0xFF10B981))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Pending', '${students.length - graded}', Icons.pending_rounded, const Color(0xFFF97316))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Results', '${results.length}', Icons.assessment_rounded, const Color(0xFF8B5CF6))),
                ]),
              const SizedBox(height: 24),
              // Course + exam type selectors
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppCardStyles.elevated,
                child: Wrap(spacing: 16, runSpacing: 12, children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 300,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCourse,
                      decoration: _inputDeco('Course'),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      items: courses.map((c) => DropdownMenuItem(value: c['courseId'] as String?,
                        child: Text('${c['courseId']} - ${c['courseName'] ?? ''}'))).toList(),
                      onChanged: (v) => setState(() => _selectedCourse = v),
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: _examType,
                      decoration: _inputDeco('Exam Type'),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      items: ['Internal 1', 'Internal 2', 'Internal 3', 'Model', 'University', 'Assignment', 'Lab']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _examType = v!),
                    ),
                  ),
                  // Publish button
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.publish, size: 16),
                      label: const Text('Publish Results'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: (_selectedCourse == null)
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Publish Results'),
                                  content: Text('Publish all entered results for the selected course and exam ("$_examType")? This will notify students.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ds.publishResults(_selectedCourse!, _examType, publishedBy: ds.currentUserId);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Results published')));
                                setState(() {});
                              }
                            },
                    ),
                  ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.description_outlined, size: 16),
                            label: const Text('Question Paper Pattern'),
                            onPressed: _selectedCourse == null
                                ? null
                                : () => _showPaperPatternDialog(context, ds),
                          ),
                        ),
                ]),
              ),
                    const SizedBox(height: 16),
                    if (_selectedCourse != null) _buildPatternSummary(ds),
              const SizedBox(height: 24),
              _buildGradeDistribution(gradeMap),
              const SizedBox(height: 24),
              _buildStudentGrades(students, results, ds),
            ]),
          );
        }),
      );
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.statCard(color),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildGradeDistribution(Map<String, int> gradeMap) {
    final grades = ['O', 'A+', 'A', 'B+', 'B', 'C', 'F'];
    final maxCount = gradeMap.values.fold(0, (max, v) => v > max ? v : max);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.textMedium),
          const SizedBox(width: 8),
          const Text('Grade Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: grades.map((g) {
          final count = gradeMap[g] ?? 0;
          final height = maxCount > 0 ? (count / maxCount * 100) : 0.0;
          final color = g == 'O' || g == 'A+' ? const Color(0xFF10B981)
              : g == 'A' || g == 'B+' ? const Color(0xFF3B82F6)
              : g == 'F' ? const Color(0xFFF43F5E) : const Color(0xFFF97316);
          return Column(children: [
            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Container(width: 30, height: height.clamp(4.0, 100.0),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 4),
            Text(g, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
          ]);
        }).toList()),
      ]),
    );
  }

  Widget _buildStudentGrades(List<Map<String, dynamic>> students, List<Map<String, dynamic>> results, DataService ds) {
    final tableRows = students.map((s) {
      final sid = s['studentId'] ?? '';
      final matchingResults = results.where((r) => r['studentId'] == sid).toList();
      final hasResult = matchingResults.isNotEmpty;
      final result = hasResult ? matchingResults.first : <String, dynamic>{};
      final grade = hasResult ? (result['grade'] ?? '-') : '-';
      final marks = hasResult ? (result['obtainedMarks'] ?? result['marks'] ?? '-') : '-';
      final total = hasResult ? (result['maxMarks'] ?? result['totalMarks'] ?? '100') : '100';
      final published = hasResult && result['published'] == true;
      final gradeColor = grade == 'O' || grade == 'A+'
          ? const Color(0xFF10B981)
          : grade == 'A' || grade == 'B+'
              ? const Color(0xFF3B82F6)
              : grade == 'F'
                  ? const Color(0xFFF43F5E)
                  : const Color(0xFFF97316);

      return DataRow(
        selected: published,
        onSelectChanged: (_) => _showGradeEntry(context, ds, s, result),
        cells: [
          DataCell(Text(sid, style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
          DataCell(Text(s['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14))),
          DataCell(Text('$_selectedCourse', style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
          DataCell(Text(_examType, style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
          DataCell(Text('$marks/$total', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600))),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: gradeColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(grade, textAlign: TextAlign.center, style: TextStyle(color: gradeColor, fontWeight: FontWeight.w700, fontSize: 13)),
          )),
          DataCell(Text(published ? 'Published' : 'Draft', style: TextStyle(color: published ? const Color(0xFF10B981) : const Color(0xFFF97316), fontSize: 12, fontWeight: FontWeight.w600))),
          const DataCell(Icon(Icons.edit_rounded, size: 16, color: AppColors.textMuted)),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.textMedium),
          const SizedBox(width: 8),
          const Expanded(child: Text('Student Grades', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        ]),
        const SizedBox(height: 4),
        Text('Tap any row to enter or edit marks. Use Publish Results to lock what students can see.', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 16),
        if (students.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('No students enrolled', style: TextStyle(color: AppColors.textLight))),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 12,
              headingRowColor: const MaterialStatePropertyAll(Color(0xFFF3F6FB)),
              dataRowMinHeight: 30,
              dataRowMaxHeight: 34,
              border: TableBorder.all(color: const Color(0xFF9AA7BB), width: 1),
              headingTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF123A78), height: 1.0),
              dataTextStyle: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600, height: 1.0),
              columns: const [
                DataColumn(label: Text('Roll No', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Name', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Course', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Exam', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Marks', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Grade', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('State', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Action', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w700))),
              ],
              rows: tableRows,
            ),
          ),
      ]),
    );
  }

  void _showGradeEntry(BuildContext context, DataService ds, Map<String, dynamic> student, Map<String, dynamic>? existing) {
    final sid = student['studentId'] ?? '';
    final name = student['name'] ?? '';
    final isInternal = _examType.toLowerCase().contains('internal');
    final marksCtrl = TextEditingController(text: existing?['marks']?.toString() ?? '');
    final totalCtrl = TextEditingController(text: existing?['totalMarks']?.toString() ?? (isInternal ? '50' : '100'));
    String selectedGrade = existing?['grade']?.toString() ?? 'O';
    final grades = ['O', 'A+', 'A', 'B+', 'B', 'C', 'F', 'AB'];

    final breakdown = (existing?['paperBreakdown'] as Map<String, dynamic>?) ?? {};
    final partAExisting = ((breakdown['partA'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final partBExisting = (breakdown['partB'] as Map<String, dynamic>?) ?? {};

    final partACtrls = List.generate(5, (i) => TextEditingController(text: i < partAExisting.length ? partAExisting[i]['marks']?.toString() ?? '' : ''));
    final q6A = TextEditingController(text: partBExisting['q6A']?.toString() ?? '');
    final q6B = TextEditingController(text: partBExisting['q6B']?.toString() ?? '');
    final q7A = TextEditingController(text: partBExisting['q7A']?.toString() ?? '');
    final q7B = TextEditingController(text: partBExisting['q7B']?.toString() ?? '');
    final q7C = TextEditingController(text: partBExisting['q7C']?.toString() ?? '');
    final q8A = TextEditingController(text: partBExisting['q8A']?.toString() ?? '');
    final q8B = TextEditingController(text: partBExisting['q8B']?.toString() ?? '');
    final q8C = TextEditingController(text: partBExisting['q8C']?.toString() ?? '');
    String q6Selected = partBExisting['q6Selected']?.toString() ?? 'A';
    final q7Selected = <String>{...(partBExisting['q7Selected'] as List<dynamic>?)?.map((e) => e.toString()) ?? {'A', 'B'}};
    final q8Selected = <String>{...(partBExisting['q8Selected'] as List<dynamic>?)?.map((e) => e.toString()) ?? {'A', 'B'}};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.grading_rounded, color: Color(0xFF10B981), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(existing != null ? 'Edit Grade' : 'Enter Grade', style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('$sid — $name', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ])),
          ]),
          content: SizedBox(
            width: 920,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.class_rounded, size: 16, color: AppColors.textMedium),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$_selectedCourse • $_examType', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
                  ]),
                ),
                const SizedBox(height: 16),
                if (isInternal) ...[
                  _buildMarksPatternHeader(),
                  const SizedBox(height: 12),
                  _buildPartAGrid(partACtrls),
                  const SizedBox(height: 12),
                  _buildPartBGrid(q6Selected, q7Selected, q8Selected, q6A, q6B, q7A, q7B, q7C, q8A, q8B, q8C, setDlgState, (v) => q6Selected = v),
                ] else ...[
                  Row(children: [
                    Expanded(child: TextField(controller: marksCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center, decoration: _inputDeco('Marks'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: totalCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center, decoration: _inputDeco('Total'))),
                  ]),
                ],
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Grade', style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: grades.map((g) {
                  final isSelected = selectedGrade == g;
                  final color = g == 'O' || g == 'A+' ? const Color(0xFF10B981) : g == 'A' || g == 'B+' ? const Color(0xFF3B82F6) : g == 'F' ? const Color(0xFFF43F5E) : const Color(0xFFF97316);
                  return InkWell(
                    onTap: () => setDlgState(() => selectedGrade = g),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: isSelected ? color.withValues(alpha: 0.12) : AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1)),
                      child: Text(g, style: TextStyle(color: isSelected ? color : AppColors.textMedium, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                    ),
                  );
                }).toList()),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (isInternal) {
                  final breakdownResult = _collectInternalBreakdown(
                    context,
                    partACtrls,
                    q6Selected,
                    q6A,
                    q6B,
                    q7Selected,
                    q7A,
                    q7B,
                    q7C,
                    q8Selected,
                    q8A,
                    q8B,
                    q8C,
                  );
                  if (breakdownResult == null) return;
                  final marks = breakdownResult['total'] as int;
                  if (existing != null && existing['resultId'] != null) {
                    ds.updateResult(existing['resultId'] as String, {
                      'marks': marks,
                      'totalMarks': 50,
                      'obtainedMarks': marks,
                      'paperBreakdown': breakdownResult['breakdown'],
                      'grade': selectedGrade,
                      'examType': _examType,
                      'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
                      'gradedBy': ds.currentUserId ?? '',
                    });
                  } else {
                    ds.addResult({
                      'studentId': sid,
                      'courseId': _selectedCourse,
                      'marks': marks,
                      'totalMarks': 50,
                      'obtainedMarks': marks,
                      'paperBreakdown': breakdownResult['breakdown'],
                      'grade': selectedGrade,
                      'examType': _examType,
                      'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
                      'gradedBy': ds.currentUserId ?? '',
                    });
                  }
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name — $selectedGrade ($marks/50)'), backgroundColor: const Color(0xFF10B981)));
                  return;
                }

                final marks = int.tryParse(marksCtrl.text);
                final total = int.tryParse(totalCtrl.text) ?? 100;
                if (marks == null || marks < 0 || marks > total) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid marks (0–$total)'), backgroundColor: const Color(0xFFF43F5E)));
                  return;
                }
                if (existing != null && existing['resultId'] != null) {
                  ds.updateResult(existing['resultId'] as String, {'marks': marks, 'totalMarks': total, 'obtainedMarks': marks, 'grade': selectedGrade, 'examType': _examType, 'gradedDate': DateTime.now().toIso8601String().substring(0, 10), 'gradedBy': ds.currentUserId ?? ''});
                } else {
                  ds.addResult({'studentId': sid, 'courseId': _selectedCourse, 'marks': marks, 'totalMarks': total, 'obtainedMarks': marks, 'grade': selectedGrade, 'examType': _examType, 'gradedDate': DateTime.now().toIso8601String().substring(0, 10), 'gradedBy': ds.currentUserId ?? ''});
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name — $selectedGrade ($marks/$total)'), backgroundColor: const Color(0xFF10B981)));
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(existing != null ? 'Update' : 'Save Grade'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMarksPatternHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF3F6FB), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Internal Assessment 50 Marks Pattern', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        SizedBox(height: 6),
        Text('Part-A: 5 questions × 2 = 10 marks', style: TextStyle(color: AppColors.textMedium)),
        Text('Part-B: 5 questions × 8 = 40 marks', style: TextStyle(color: AppColors.textMedium)),
        Text('Q6: choose 1 of 2 | Q7: any 2 of 3 | Q8: any 2 of 3', style: TextStyle(color: AppColors.textMedium)),
      ]),
    );
  }

  Widget _buildPartAGrid(List<TextEditingController> ctrls) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Part-A (0–2 each)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: List.generate(5, (i) => SizedBox(width: 120, child: TextField(controller: ctrls[i], keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDeco('A${i + 1}'))))),
    ]);
  }

  Widget _buildPartBGrid(
    String q6Selected,
    Set<String> q7Selected,
    Set<String> q8Selected,
    TextEditingController q6A,
    TextEditingController q6B,
    TextEditingController q7A,
    TextEditingController q7B,
    TextEditingController q7C,
    TextEditingController q8A,
    TextEditingController q8B,
    TextEditingController q8C,
    void Function(void Function()) setDlgState,
    void Function(String) setQ6Selected,
  ) {
    Widget row(String label, List<String> opts, List<TextEditingController> ctrls, {required bool single}) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...List.generate(opts.length, (i) {
          final opt = opts[i];
          final ctrl = ctrls[i];
          final isChecked = single ? q6Selected == opt : (label.startsWith('Q7') ? q7Selected.contains(opt) : q8Selected.contains(opt));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              if (single)
                Radio<String>(value: opt, groupValue: q6Selected, onChanged: (v) => setDlgState(() { if (v != null) setQ6Selected(v); }))
              else
                Checkbox(value: isChecked, onChanged: (v) => setDlgState(() {
                      if (label.startsWith('Q7')) {
                        if (v == true) { q7Selected.add(opt); } else { q7Selected.remove(opt); }
                      } else {
                        if (v == true) { q8Selected.add(opt); } else { q8Selected.remove(opt); }
                      }
                    })),
              SizedBox(width: 120, child: Text(opt, style: const TextStyle(color: AppColors.textDark))),
              Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: _inputDeco('0-8'))),
            ]),
          );
        }),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Part-B (choices + marks)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 12),
      row('Q6: choose one', ['A', 'B'], [q6A, q6B], single: true),
      const SizedBox(height: 12),
      row('Q7: any two of three', ['A', 'B', 'C'], [q7A, q7B, q7C], single: false),
      const SizedBox(height: 12),
      row('Q8: any two of three', ['A', 'B', 'C'], [q8A, q8B, q8C], single: false),
    ]);
  }

  Map<String, dynamic>? _collectInternalBreakdown(
    BuildContext context,
    List<TextEditingController> partACtrls,
    String q6Selected,
    TextEditingController q6A,
    TextEditingController q6B,
    Set<String> q7Selected,
    TextEditingController q7A,
    TextEditingController q7B,
    TextEditingController q7C,
    Set<String> q8Selected,
    TextEditingController q8A,
    TextEditingController q8B,
    TextEditingController q8C,
  ) {
    int? parse2(String t) {
      final n = int.tryParse(t.trim());
      if (n == null || n < 0 || n > 2) return null;
      return n;
    }
    int? parse8(String t) {
      final n = int.tryParse(t.trim());
      if (n == null || n < 0 || n > 8) return null;
      return n;
    }

    void showErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFF43F5E)));

    final partA = <Map<String, dynamic>>[];
    var total = 0;
    for (var i = 0; i < partACtrls.length; i++) {
      final mark = parse2(partACtrls[i].text);
      if (mark == null) { showErr('Part-A marks must be between 0 and 2.'); return null; }
      partA.add({'question': 'A${i + 1}', 'marks': mark});
      total += mark;
    }

    if (q6Selected != 'A' && q6Selected != 'B') { showErr('Q6: choose exactly one option.'); return null; }
    final q6Mark = q6Selected == 'A' ? parse8(q6A.text) : parse8(q6B.text);
    if (q6Mark == null) { showErr('Enter valid marks (0–8) for Q6.'); return null; }
    total += q6Mark;

    if (q7Selected.length != 2) { showErr('Q7: choose exactly 2 of 3 options.'); return null; }
    final q7Map = {'A': parse8(q7A.text), 'B': parse8(q7B.text), 'C': parse8(q7C.text)};
    if (q7Map.values.any((v) => v == null)) { showErr('Enter valid marks (0–8) for Q7 options.'); return null; }
    total += q7Selected.fold<int>(0, (sum, key) => sum + (q7Map[key] ?? 0));

    if (q8Selected.length != 2) { showErr('Q8: choose exactly 2 of 3 options.'); return null; }
    final q8Map = {'A': parse8(q8A.text), 'B': parse8(q8B.text), 'C': parse8(q8C.text)};
    if (q8Map.values.any((v) => v == null)) { showErr('Enter valid marks (0–8) for Q8 options.'); return null; }
    total += q8Selected.fold<int>(0, (sum, key) => sum + (q8Map[key] ?? 0));

    if (total > 50) { showErr('Total cannot exceed 50 marks.'); return null; }

    return {
      'total': total,
      'breakdown': {
        'type': 'internal_50',
        'partA': partA,
        'partB': {
          'q6Selected': q6Selected,
          'q6A': parse8(q6A.text) ?? 0,
          'q6B': parse8(q6B.text) ?? 0,
          'q7Selected': q7Selected.toList(),
          'q7A': q7Map['A'] ?? 0,
          'q7B': q7Map['B'] ?? 0,
          'q7C': q7Map['C'] ?? 0,
          'q8Selected': q8Selected.toList(),
          'q8A': q8Map['A'] ?? 0,
          'q8B': q8Map['B'] ?? 0,
          'q8C': q8Map['C'] ?? 0,
        },
        'total': total,
        'maximum': 50,
      },
    };
  }

  Widget _buildPatternSummary(DataService ds) {
    if (_selectedCourse == null) return const SizedBox.shrink();
    final pattern = ds.getQuestionPaperPattern(_selectedCourse!, _examType);
    if (pattern == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppCardStyles.elevated,
        child: const Text(
          'No question paper pattern saved yet. Use the button above to set the 50-mark Part-A / Part-B pattern.',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }

    final partA = pattern['partA'] as Map<String, dynamic>? ?? {};
    final partB = pattern['partB'] as Map<String, dynamic>? ?? {};
    // Build tabular view for Part-A and Part-B ranges
    final partADetails = (partA['questionsDetail'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final partBq6 = (partB['q6Detail'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final partBq7 = (partB['q7Detail'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final partBq8 = (partB['q8Detail'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    Widget buildPartATable() {
      final rows = List<DataRow>.generate(
        partADetails.isNotEmpty ? partADetails.length : (partA['questions'] ?? 5),
        (i) {
          final d = i < partADetails.length ? partADetails[i] : null;
          final q = d != null ? d['question']?.toString() ?? 'A${i + 1}' : 'A${i + 1}';
          final min = d != null ? (d['min']?.toString() ?? '-') : (partA['minPerQuestion']?.toString() ?? '-');
          final max = d != null ? (d['max']?.toString() ?? '-') : (partA['maxPerQuestion']?.toString() ?? (partA['marksPerQuestion']?.toString() ?? '-'));
          return DataRow(cells: [DataCell(Text(q)), DataCell(Text(min)), DataCell(Text(max))]);
        },
      );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const MaterialStatePropertyAll(Color(0xFFF3F6FB)),
          columns: const [
            DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Min', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Max', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: rows,
        ),
      );
    }

    Widget buildPartBTable() {
      final items = <Map<String, dynamic>>[];
      for (var i = 0; i < partBq6.length; i++) items.add({'group': 'Q6', 'option': partBq6[i]['option'] ?? '6${String.fromCharCode(65 + i)}', 'min': partBq6[i]['min'] ?? '-', 'max': partBq6[i]['max'] ?? '-'});
      for (var i = 0; i < partBq7.length; i++) items.add({'group': 'Q7', 'option': partBq7[i]['option'] ?? '7${String.fromCharCode(65 + i)}', 'min': partBq7[i]['min'] ?? '-', 'max': partBq7[i]['max'] ?? '-'});
      for (var i = 0; i < partBq8.length; i++) items.add({'group': 'Q8', 'option': partBq8[i]['option'] ?? '8${String.fromCharCode(65 + i)}', 'min': partBq8[i]['min'] ?? '-', 'max': partBq8[i]['max'] ?? '-'});

      final rows = items.map((it) => DataRow(cells: [DataCell(Text(it['group'])), DataCell(Text(it['option'])), DataCell(Text(it['min'].toString())), DataCell(Text(it['max'].toString()))])).toList();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const MaterialStatePropertyAll(Color(0xFFF3F6FB)),
          columns: const [
            DataColumn(label: Text('Group', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Option', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Min', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Max', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: rows,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Question Paper Pattern', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 10),
          Text('Title: ${pattern['title'] ?? '50 Marks Pattern'}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Total Marks: ${pattern['totalMarks'] ?? 50}', style: const TextStyle(color: AppColors.textMedium)),
          const SizedBox(height: 12),
          const Text('Part-A Ranges', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          buildPartATable(),
          const SizedBox(height: 12),
          const Text('Part-B Ranges', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          buildPartBTable(),
          const SizedBox(height: 12),
          Text('Rules: Q6: ${partB['q6Rule'] ?? 'Choose 1 of 2'} | Q7: ${partB['q7Rule'] ?? 'Any 2 of 3'} | Q8: ${partB['q8Rule'] ?? 'Any 2 of 3'}', style: const TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }

  void _showPaperPatternDialog(BuildContext context, DataService ds) {
    if (_selectedCourse == null) return;
    final paperTitleCtrl = TextEditingController(text: '50 Marks Pattern');
    final noteCtrl = TextEditingController(text: 'Part-A: 5 x 2 = 10 marks; Part-B: 5 x 8 = 40 marks');
    final q6Ctrl = TextEditingController(text: '6(A) or 6(B) — choose one');
    final q7Ctrl = TextEditingController(text: '7(A) / 7(B) / 7(C) — any two');
    final q8Ctrl = TextEditingController(text: '8(A) / 8(B) / 8(C) — any two');

    // Per-question min/max controllers for Part A (5 questions)
    final partAMinCtrls = List.generate(5, (i) => TextEditingController());
    final partAMaxCtrls = List.generate(5, (i) => TextEditingController());
    // Part B options: Q6 (A,B), Q7 (A,B,C), Q8 (A,B,C)
    final q6Min = [TextEditingController(), TextEditingController()];
    final q6Max = [TextEditingController(), TextEditingController()];
    final q7Min = [TextEditingController(), TextEditingController(), TextEditingController()];
    final q7Max = [TextEditingController(), TextEditingController(), TextEditingController()];
    final q8Min = [TextEditingController(), TextEditingController(), TextEditingController()];
    final q8Max = [TextEditingController(), TextEditingController(), TextEditingController()];

    final existing = ds.getQuestionPaperPattern(_selectedCourse!, _examType);
    if (existing != null) {
      paperTitleCtrl.text = existing['title']?.toString() ?? paperTitleCtrl.text;
      noteCtrl.text = existing['notes']?.toString() ?? noteCtrl.text;
      final partB = existing['partB'] as Map<String, dynamic>?;
      if (partB != null) {
        q6Ctrl.text = partB['q6Rule']?.toString() ?? q6Ctrl.text;
        q7Ctrl.text = partB['q7Rule']?.toString() ?? q7Ctrl.text;
        q8Ctrl.text = partB['q8Rule']?.toString() ?? q8Ctrl.text;
      }
      final partAexisting = existing['partA'] as Map<String, dynamic>?;
      if (partAexisting != null) {
        final details = (partAexisting['questionsDetail'] as List<dynamic>?) ?? [];
        for (var i = 0; i < partAMinCtrls.length; i++) {
          if (i < details.length) {
            partAMinCtrls[i].text = (details[i]['min'] ?? partAexisting['minPerQuestion'] ?? 0).toString();
            partAMaxCtrls[i].text = (details[i]['max'] ?? partAexisting['maxPerQuestion'] ?? partAexisting['marksPerQuestion'] ?? 2).toString();
          } else {
            partAMinCtrls[i].text = (partAexisting['minPerQuestion'] ?? 0).toString();
            partAMaxCtrls[i].text = (partAexisting['maxPerQuestion'] ?? partAexisting['marksPerQuestion'] ?? 2).toString();
          }
        }
      }
      final partBexisting = existing['partB'] as Map<String, dynamic>?;
      if (partBexisting != null) {
        final q6details = (partBexisting['q6Detail'] as List<dynamic>?) ?? [];
        if (q6details.isNotEmpty) {
          for (var i = 0; i < q6details.length && i < 2; i++) {
            q6Min[i].text = (q6details[i]['min'] ?? 0).toString();
            q6Max[i].text = (q6details[i]['max'] ?? partBexisting['marksPerQuestion'] ?? 5).toString();
          }
        }
        final q7details = (partBexisting['q7Detail'] as List<dynamic>?) ?? [];
        for (var i = 0; i < 3; i++) {
          if (i < q7details.length) {
            q7Min[i].text = (q7details[i]['min'] ?? 0).toString();
            q7Max[i].text = (q7details[i]['max'] ?? partBexisting['marksPerQuestion'] ?? 5).toString();
          }
        }
        final q8details = (partBexisting['q8Detail'] as List<dynamic>?) ?? [];
        for (var i = 0; i < 3; i++) {
          if (i < q8details.length) {
            q8Min[i].text = (q8details[i]['min'] ?? 0).toString();
            q8Max[i].text = (q8details[i]['max'] ?? partBexisting['marksPerQuestion'] ?? 5).toString();
          }
        }
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Question Paper Pattern (50 Marks)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: paperTitleCtrl, decoration: const InputDecoration(labelText: 'Pattern Title')),
              const SizedBox(height: 8),
              TextField(controller: noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Pattern Notes')),
              const SizedBox(height: 12),
              TextField(controller: q6Ctrl, decoration: const InputDecoration(labelText: 'Q6 Rule')),
              const SizedBox(height: 8),
              TextField(controller: q7Ctrl, decoration: const InputDecoration(labelText: 'Q7 Rule')),
              const SizedBox(height: 8),
              TextField(controller: q8Ctrl, decoration: const InputDecoration(labelText: 'Q8 Rule')),
              const SizedBox(height: 12),
              _buildPatternTableIntro(),
              const SizedBox(height: 12),
              _buildPatternRangeTable(
                title: 'Part-A ranges',
                columns: const ['Question', 'Min', 'Max'],
                rows: List.generate(5, (i) => [
                  _tableText('A${i + 1}'),
                  _rangeField(partAMinCtrls[i], hint: '0'),
                  _rangeField(partAMaxCtrls[i], hint: '2'),
                ]),
              ),
              const SizedBox(height: 12),
              _buildPatternRangeTable(
                title: 'Part-B ranges',
                columns: const ['Group', 'Option', 'Min', 'Max'],
                rows: [
                  [_tableText('Q6'), _tableText('6A'), _rangeField(q6Min[0], hint: '0'), _rangeField(q6Max[0], hint: '5')],
                  [_tableText('Q6'), _tableText('6B'), _rangeField(q6Min[1], hint: '0'), _rangeField(q6Max[1], hint: '5')],
                  [_tableText('Q7'), _tableText('7A'), _rangeField(q7Min[0], hint: '0'), _rangeField(q7Max[0], hint: '5')],
                  [_tableText('Q7'), _tableText('7B'), _rangeField(q7Min[1], hint: '0'), _rangeField(q7Max[1], hint: '5')],
                  [_tableText('Q7'), _tableText('7C'), _rangeField(q7Min[2], hint: '0'), _rangeField(q7Max[2], hint: '5')],
                  [_tableText('Q8'), _tableText('8A'), _rangeField(q8Min[0], hint: '0'), _rangeField(q8Max[0], hint: '5')],
                  [_tableText('Q8'), _tableText('8B'), _rangeField(q8Min[1], hint: '0'), _rangeField(q8Max[1], hint: '5')],
                  [_tableText('Q8'), _tableText('8C'), _rangeField(q8Min[2], hint: '0'), _rangeField(q8Max[2], hint: '5')],
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Build detailed partA questions detail
              final partADetails = <Map<String, dynamic>>[];
              for (var i = 0; i < 5; i++) {
                final min = int.tryParse(partAMinCtrls[i].text.trim()) ?? 0;
                final max = int.tryParse(partAMaxCtrls[i].text.trim()) ?? 2;
                partADetails.add({'question': 'A${i + 1}', 'min': min, 'max': max});
              }

              final q6Detail = [
                {'option': 'A', 'min': int.tryParse(q6Min[0].text.trim()) ?? 0, 'max': int.tryParse(q6Max[0].text.trim()) ?? 8},
                {'option': 'B', 'min': int.tryParse(q6Min[1].text.trim()) ?? 0, 'max': int.tryParse(q6Max[1].text.trim()) ?? 8},
              ];
              final q7Detail = List.generate(3, (i) => {'option': String.fromCharCode(65 + i), 'min': int.tryParse(q7Min[i].text.trim()) ?? 0, 'max': int.tryParse(q7Max[i].text.trim()) ?? 8});
              final q8Detail = List.generate(3, (i) => {'option': String.fromCharCode(65 + i), 'min': int.tryParse(q8Min[i].text.trim()) ?? 0, 'max': int.tryParse(q8Max[i].text.trim()) ?? 8});

              ds.saveQuestionPaperPattern(_selectedCourse!, _examType, {
                'title': paperTitleCtrl.text.trim(),
                'notes': noteCtrl.text.trim(),
                'totalMarks': 50,
                'partA': {
                  'questions': 5,
                  'marksPerQuestion': 2,
                  'total': 10,
                  'questionsDetail': partADetails,
                },
                'partB': {
                  'questions': 8,
                  'marksPerQuestion': 8,
                  'total': 40,
                  'q6Rule': q6Ctrl.text.trim(),
                  'q7Rule': q7Ctrl.text.trim(),
                  'q8Rule': q8Ctrl.text.trim(),
                  'q6Detail': q6Detail,
                  'q7Detail': q7Detail,
                  'q8Detail': q8Detail,
                },
                'updatedBy': ds.currentUserId ?? '',
                'updatedAt': DateTime.now().toIso8601String(),
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question paper pattern saved')),
              );
              setState(() {});
            },
            child: const Text('Save Pattern'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternTableIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Internal IA 50-mark pattern: Part-A = 5 × 2 marks; Part-B = 8 × 5 marks; Q6 choose 1 of 2; Q7 any 2 of 3; Q8 any 2 of 3.',
        style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildPatternRangeTable({
    required String title,
    required List<String> columns,
    required List<List<Widget>> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const MaterialStatePropertyAll(Color(0xFFF3F6FB)),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              columnSpacing: 18,
              border: TableBorder.all(color: const Color(0xFFD7DFEA), width: 1),
              columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)))).toList(),
              rows: rows.map((cells) {
                return DataRow(cells: cells.map((w) => DataCell(w)).toList());
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
    );
  }

  Widget _rangeField(TextEditingController controller, {required String hint}) {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.6)),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}
