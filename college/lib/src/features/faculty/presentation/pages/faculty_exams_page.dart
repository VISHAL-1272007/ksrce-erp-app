import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyExamsPage extends StatefulWidget {
  const FacultyExamsPage({super.key});

  @override
  State<FacultyExamsPage> createState() => _FacultyExamsPageState();
}

class _FacultyExamsPageState extends State<FacultyExamsPage> {

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final masterKey = ds.activeMasterKey;
      final exams = ds.getFacultyExams(fid, masterKey: masterKey);
      final courses = ds.getFacultyCourses(fid, masterKey: masterKey);
      final upcoming = exams.where((e) {
        final d = e['date'] as String? ?? '';
        return d.compareTo(DateTime.now().toIso8601String().substring(0, 10)) >= 0;
      }).length;

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showScheduleExam(context, ds, courses),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Schedule Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildModernHeader(context),
              const SizedBox(height: 16),
              _buildPatternBanner(),
              const SizedBox(height: 16),
              _buildCOPOSummary(courses, ds),
              const SizedBox(height: 24),
              if (isMobile)
                Column(children: [
                  Row(children: [
                    Expanded(child: _statCard('Total', '${exams.length}', Icons.event_note_rounded, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Upcoming', '$upcoming', Icons.upcoming_rounded, const Color(0xFF10B981))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('Courses', '${courses.length}', Icons.class_rounded, const Color(0xFF8B5CF6))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Completed', '${exams.length - upcoming}', Icons.check_circle_rounded, const Color(0xFFF97316))),
                  ]),
                ])
              else
                Row(children: [
                  Expanded(child: _statCard('Total', '${exams.length}', Icons.event_note_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Upcoming', '$upcoming', Icons.upcoming_rounded, const Color(0xFF10B981))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Courses', '${courses.length}', Icons.class_rounded, const Color(0xFF8B5CF6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Completed', '${exams.length - upcoming}', Icons.check_circle_rounded, const Color(0xFFF97316))),
                ]),
              const SizedBox(height: 28),
              _buildExamScheduleTables(exams, ds),
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

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Exam Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
          SizedBox(height: 4),
          Text('Table-based exam schedule, internal pattern, and CO/PO visibility for faculty and HOD.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
          child: const Text('Enabled', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildPatternBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.18)),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFFF97316), size: 18),
          SizedBox(width: 8),
          Text('Internal IA 50-Mark Pattern', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        SizedBox(height: 8),
        Text('Part-A: 5 × 2 = 10 marks | Part-B: 8 × 5 = 40 marks', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
        Text('Q6: choose 1 of 2 | Q7: any 2 of 3 | Q8: any 2 of 3', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
      ]),
    );
  }

  Widget _buildCOPOSummary(List<Map<String, dynamic>> courses, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text('CO/PO Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          const Text('No assigned courses found.', style: TextStyle(color: AppColors.textLight))
        else
          Wrap(spacing: 10, runSpacing: 10, children: courses.map((c) {
            final cos = ds.getCourseOutcomeCOs(c['courseId'] as String? ?? '');
            final count = cos.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
              child: Text('${c['courseCode'] ?? ''}: $count COs', style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }).toList()),
      ]),
    );
  }

  Widget _buildExamScheduleTables(List<Map<String, dynamic>> exams, DataService ds) {
    if (exams.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: AppCardStyles.elevated,
        child: Center(child: Column(children: [
          Icon(Icons.quiz_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('No exams scheduled', style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Tap + to schedule one', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ])),
      );
    }
    final internal = exams.where((e) => (e['type'] ?? '').toString().toLowerCase().contains('internal')).toList();
    final external = exams.where((e) => !(e['type'] ?? '').toString().toLowerCase().contains('internal')).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTable(
          title: 'Internal Assessments',
          accent: const Color(0xFF2563EB),
          exams: internal,
          ds: ds,
          isStudentView: false,
        ),
        const SizedBox(height: 18),
        _buildSectionTable(
          title: 'End Semester / External Examinations',
          accent: const Color(0xFF10B981),
          exams: external,
          ds: ds,
          isStudentView: false,
        ),
      ],
    );
  }

  Widget _buildSectionTable({
    required String title,
    required Color accent,
    required List<Map<String, dynamic>> exams,
    required DataService ds,
    required bool isStudentView,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isStudentView ? 1240 : 1320),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(color: const Color(0xFF9AA7BB), width: 1),
                  columnWidths: {
                    0: const FixedColumnWidth(54),
                    1: const FixedColumnWidth(116),
                    2: const FixedColumnWidth(300),
                    3: const FixedColumnWidth(120),
                    4: const FixedColumnWidth(110),
                    5: const FixedColumnWidth(108),
                    6: const FixedColumnWidth(108),
                    7: const FixedColumnWidth(120),
                    8: const FixedColumnWidth(110), // Pattern
                    if (!isStudentView) 9: const FixedColumnWidth(96), // Action
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF3F6FB)),
                      children: [
                        _headerCell('S.No'),
                        _headerCell('Course Code'),
                        _headerCell('Course Title'),
                        _headerCell('Exam Name'),
                        _headerCell('Type'),
                        _headerCell('Date'),
                        _headerCell('Time'),
                        _headerCell('Venue'),
                        _headerCell('Pattern'),
                        if (!isStudentView) _headerCell('Action'),
                      ],
                    ),
                    ...List.generate(exams.length, (index) {
                      final e = exams[index];
                      final type = (e['type'] ?? '').toString();
                      final isInternal = type.toLowerCase().contains('internal');
                      final examId = e['examId'] as String? ?? '';
                      final courseId = e['courseId'] as String? ?? '';
                      final course = ds.getCourseById(courseId);
                      final courseTitle = course?['courseName']?.toString() ?? e['courseTitle']?.toString() ?? '';
                      final pattern = isInternal
                          ? (ds.getQuestionPaperPattern(courseId, type)?['title']?.toString() ?? '50-mark IA')
                          : 'External';
                      final cells = <Widget>[
                        _bodyCell('${index + 1}'),
                        _bodyCell(courseId),
                        _bodyCell(courseTitle),
                        _bodyCell('${e['examName'] ?? ''}'),
                        _statusCell(type, isInternal ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                        _bodyCell('${e['date'] ?? ''}'),
                        _bodyCell('${e['time'] ?? ''}'),
                        _bodyCell('${e['venue'] ?? ''}'),
                        _bodyCell(pattern),
                      ];
                      if (!isStudentView) {
                        cells.add(
                          SizedBox(
                            height: 32,
                            child: Center(
                              child: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'delete') {
                                    ds.deleteExam(examId);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam deleted'), backgroundColor: Color(0xFFF43F5E)));
                                  } else if (v == 'enter_marks') {
                                    _showEnterMarksDialog(context, e, ds);
                                  } else if (v == 'view_summary') {
                                    _showMarksSummaryDialog(context, e, ds);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  if (isInternal) ...[
                                    const PopupMenuItem(
                                      value: 'enter_marks',
                                      child: Row(children: [
                                        Icon(Icons.edit_note, size: 16, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Enter/Edit Marks', style: TextStyle(fontSize: 13, color: AppColors.textDark)),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'view_summary',
                                      child: Row(children: [
                                        Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF10B981)),
                                        SizedBox(width: 8),
                                        Text('View Marks Summary', style: TextStyle(fontSize: 13, color: AppColors.textDark)),
                                      ]),
                                    ),
                                  ],
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                                    ]),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        );
                      }
                      return TableRow(children: cells);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return SizedBox(
      height: 32,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF123A78),
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bodyCell(String value) {
    return SizedBox(
      height: 32,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600, height: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _statusCell(String text, Color color) {
    return SizedBox(
      height: 32,
      child: Center(child: _pill(text, color)),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  void _showScheduleExam(BuildContext context, DataService ds, List<Map<String, dynamic>> courses) {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final venueCtrl = TextEditingController(text: 'Exam Hall');
    String? selectedCourseId = courses.isNotEmpty ? courses.first['courseId'] as String : null;
    String examType = 'Internal';
    final types = ['Internal', 'Model', 'University', 'Lab', 'Practical', 'Viva'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Schedule Exam', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCourseId,
                decoration: _inputDeco('Course'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                items: courses.map((c) => DropdownMenuItem(value: c['courseId'] as String,
                  child: Text('${c['courseId']} - ${c['courseName']}'))).toList(),
                onChanged: (v) => setDlgState(() => selectedCourseId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Exam Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: examType,
                decoration: _inputDeco('Type'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDlgState(() => examType = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: dateCtrl, style: const TextStyle(color: AppColors.textDark),
                  decoration: _inputDeco('Date'), readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: timeCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Time (e.g. 10:00 AM)'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: venueCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Venue')),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (nameCtrl.text.isEmpty || selectedCourseId == null || dateCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Course, name, and date are required'),
                    backgroundColor: Color(0xFFF43F5E),
                  ));
                  return;
                }
                ds.addExam({
                  'courseId': selectedCourseId,
                  'examName': nameCtrl.text,
                  'type': examType,
                  'date': dateCtrl.text,
                  'time': timeCtrl.text.isNotEmpty ? timeCtrl.text : 'TBD',
                  'venue': venueCtrl.text.isNotEmpty ? venueCtrl.text : 'TBD',
                  'createdBy': ds.currentUserId ?? '',
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Exam "${nameCtrl.text}" scheduled!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Schedule'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      }),
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

  void _showEnterMarksDialog(BuildContext context, Map<String, dynamic> exam, DataService ds) {
    final courseId = exam['courseId'] as String? ?? '';
    final examName = exam['examName'] as String? ?? '';
    final students = ds.getCourseStudents(courseId);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Enter Marks — $examName', style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('Course: $courseId', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ])),
          ]),
          content: SizedBox(
            width: 750,
            height: 500,
            child: students.isEmpty
                ? const Center(child: Text('No students enrolled in this course.', style: TextStyle(color: AppColors.textLight)))
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Click "Enter Marks" next to a student to enter question-wise internal assessment marks (50-mark pattern).',
                              style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: students.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (c, index) {
                            final s = students[index];
                            final sid = s['studentId'] ?? '';
                            final sname = s['name'] ?? '';
                            
                            // find student result
                            final results = ds.getStudentResults();
                            final existing = results.firstWhere(
                              (r) => r['studentId'] == sid &&
                                     r['courseId'] == courseId &&
                                     (r['examType'] == examName || r['examType'] == exam['type'] || (examName.toLowerCase().contains(r['examType']?.toString().toLowerCase() ?? 'xxx'))),
                              orElse: () => <String, dynamic>{},
                            );

                            final hasMarks = existing.isNotEmpty;
                            final marksText = hasMarks ? '${existing['obtainedMarks'] ?? existing['marks'] ?? 0} / 50' : 'Not Entered';
                            final grade = hasMarks ? (existing['grade'] ?? '-') : '-';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sname, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(sid, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: hasMarks ? Colors.green.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          marksText,
                                          style: TextStyle(
                                            color: hasMarks ? Colors.green : AppColors.textLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        grade,
                                        style: TextStyle(
                                          color: hasMarks ? AppColors.primary : AppColors.textLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _showStudentMarksEntryDialog(context, s, exam, existing.isNotEmpty ? existing : null, ds, () {
                                            setDlgState(() {});
                                          });
                                        },
                                        icon: Icon(hasMarks ? Icons.edit : Icons.add, size: 14),
                                        label: Text(hasMarks ? 'Edit' : 'Enter'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          backgroundColor: hasMarks ? AppColors.background : AppColors.primary,
                                          foregroundColor: hasMarks ? AppColors.textDark : Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: hasMarks ? const BorderSide(color: AppColors.border) : BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      }),
    );
  }

  void _showStudentMarksEntryDialog(
    BuildContext context,
    Map<String, dynamic> student,
    Map<String, dynamic> exam,
    Map<String, dynamic>? existing,
    DataService ds,
    VoidCallback onSave,
  ) {
    final sid = student['studentId'] ?? '';
    final name = student['name'] ?? '';
    final courseId = exam['courseId'] as String? ?? '';
    final examName = exam['examName'] as String? ?? '';

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

    String selectedGrade = existing?['grade']?.toString() ?? 'O';
    final grades = ['O', 'A+', 'A', 'B+', 'B', 'C', 'F', 'AB'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.grading_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(existing != null ? 'Edit Marks' : 'Enter Marks', style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('$sid — $name', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ])),
          ]),
          content: SizedBox(
            width: 820,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _buildMarksPatternHeader(),
                const SizedBox(height: 12),
                _buildPartAGrid(partACtrls),
                const SizedBox(height: 12),
                _buildPartBGrid(q6Selected, q7Selected, q8Selected, q6A, q6B, q7A, q7B, q7C, q8A, q8B, q8C, setDlgState, (v) => q6Selected = v),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Grade Selection', style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600))),
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

                // Let's auto compute grade as default
                String finalGrade = selectedGrade;
                if (existing == null) {
                  if (marks >= 45) finalGrade = 'O';
                  else if (marks >= 40) finalGrade = 'A+';
                  else if (marks >= 35) finalGrade = 'A';
                  else if (marks >= 30) finalGrade = 'B+';
                  else if (marks >= 25) finalGrade = 'B';
                  else if (marks >= 20) finalGrade = 'C';
                  else finalGrade = 'F';
                }

                if (existing != null && existing['resultId'] != null) {
                  ds.updateResult(existing['resultId'] as String, {
                    'marks': marks,
                    'totalMarks': 50,
                    'obtainedMarks': marks,
                    'paperBreakdown': breakdownResult['breakdown'],
                    'grade': finalGrade,
                    'examType': examName,
                    'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
                    'gradedBy': ds.currentUserId ?? '',
                  });
                } else {
                  ds.addResult({
                    'studentId': sid,
                    'courseId': courseId,
                    'marks': marks,
                    'totalMarks': 50,
                    'obtainedMarks': marks,
                    'paperBreakdown': breakdownResult['breakdown'],
                    'grade': finalGrade,
                    'examType': examName,
                    'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
                    'gradedBy': ds.currentUserId ?? '',
                  });
                }

                Navigator.of(ctx).pop();
                onSave();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved marks for $name: $marks/50 (Grade: $finalGrade)'), backgroundColor: const Color(0xFF10B981)));
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Save Marks'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            ),
          ],
        );
      }),
    );
  }

  void _showMarksSummaryDialog(BuildContext context, Map<String, dynamic> exam, DataService ds) {
    final courseId = exam['courseId'] as String? ?? '';
    final examName = exam['examName'] as String? ?? '';
    final students = ds.getCourseStudents(courseId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.analytics_outlined, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Marks Summary — $examName', style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Course: $courseId', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ])),
        ]),
        content: SizedBox(
          width: 900,
          height: 500,
          child: students.isEmpty
              ? const Center(child: Text('No students enrolled in this course.', style: TextStyle(color: AppColors.textLight)))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 880),
                      child: Table(
                        border: TableBorder.all(color: const Color(0xFF9AA7BB), width: 1),
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: FixedColumnWidth(90),
                          1: FixedColumnWidth(160),
                          2: FixedColumnWidth(40),
                          3: FixedColumnWidth(40),
                          4: FixedColumnWidth(40),
                          5: FixedColumnWidth(40),
                          6: FixedColumnWidth(40),
                          7: FixedColumnWidth(80),
                          8: FixedColumnWidth(110),
                          9: FixedColumnWidth(110),
                          10: FixedColumnWidth(70),
                          11: FixedColumnWidth(60),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF3F6FB)),
                            children: [
                              _headerCell('Roll No'),
                              _headerCell('Student Name'),
                              _headerCell('A1'),
                              _headerCell('A2'),
                              _headerCell('A3'),
                              _headerCell('A4'),
                              _headerCell('A5'),
                              _headerCell('Q6'),
                              _headerCell('Q7'),
                              _headerCell('Q8'),
                              _headerCell('Total'),
                              _headerCell('Grade'),
                            ],
                          ),
                          ...students.map((s) {
                            final sid = s['studentId'] ?? '';
                            final sname = s['name'] ?? '';

                            final results = ds.getStudentResults();
                            final existing = results.firstWhere(
                              (r) => r['studentId'] == sid &&
                                     r['courseId'] == courseId &&
                                     (r['examType'] == examName || r['examType'] == exam['type'] || (examName.toLowerCase().contains(r['examType']?.toString().toLowerCase() ?? 'xxx'))),
                              orElse: () => <String, dynamic>{},
                            );

                            final hasMarks = existing.isNotEmpty;
                            final breakdown = hasMarks ? (existing['paperBreakdown'] as Map<String, dynamic>?) ?? {} : {};
                            final partA = ((breakdown['partA'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
                            final partB = (breakdown['partB'] as Map<String, dynamic>?) ?? {};

                            final q1 = hasMarks && partA.length > 0 ? partA[0]['marks']?.toString() ?? '0' : '-';
                            final q2 = hasMarks && partA.length > 1 ? partA[1]['marks']?.toString() ?? '0' : '-';
                            final q3 = hasMarks && partA.length > 2 ? partA[2]['marks']?.toString() ?? '0' : '-';
                            final q4 = hasMarks && partA.length > 3 ? partA[3]['marks']?.toString() ?? '0' : '-';
                            final q5 = hasMarks && partA.length > 4 ? partA[4]['marks']?.toString() ?? '0' : '-';

                            final q6Sel = partB['q6Selected']?.toString() ?? '';
                            final q6Val = q6Sel == 'A' ? partB['q6A'] : q6Sel == 'B' ? partB['q6B'] : null;
                            final q6 = hasMarks ? (q6Val != null ? '$q6Sel: $q6Val' : 'None') : '-';

                            final q7Sel = (partB['q7Selected'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [];
                            final q7 = hasMarks
                                ? (q7Sel.isNotEmpty
                                    ? q7Sel.map((x) => '$x: ${partB['q7$x'] ?? 0}').join(', ')
                                    : 'None')
                                : '-';

                            final q8Sel = (partB['q8Selected'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [];
                            final q8 = hasMarks
                                ? (q8Sel.isNotEmpty
                                    ? q8Sel.map((x) => '$x: ${partB['q8$x'] ?? 0}').join(', ')
                                    : 'None')
                                : '-';

                            final total = hasMarks ? (existing['obtainedMarks'] ?? existing['marks'] ?? 0).toString() : '-';
                            final grade = hasMarks ? (existing['grade'] ?? '-') : '-';

                            return TableRow(
                              children: [
                                _bodyCell(sid),
                                _bodyCell(sname),
                                _bodyCell(q1),
                                _bodyCell(q2),
                                _bodyCell(q3),
                                _bodyCell(q4),
                                _bodyCell(q5),
                                _bodyCell(q6),
                                _bodyCell(q7),
                                _bodyCell(q8),
                                _bodyCell(total),
                                _bodyCell(grade),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksPatternHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '50 Marks Pattern: Part A (5 x 2 = 10, range 0-2) | Part B (5 x 8 = 40). Q6: choose 1 (max 8). Q7: choose 2 (max 8 each). Q8: choose 2 (max 8 each).',
              style: TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartAGrid(List<TextEditingController> ctrls) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Part-A: 5 Questions (2 marks each, range: 0-2)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                return SizedBox(
                  width: 90,
                  child: TextField(
                    controller: ctrls[i],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                    decoration: InputDecoration(
                      labelText: 'Q${i + 1} (Max 2)',
                      labelStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
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
    StateSetter setDlgState,
    void Function(String) onQ6Changed,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Part-B: 8 marks each (range: 0-8)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('Q6: Choose 1 of 2', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Radio<String>(
                  value: 'A',
                  groupValue: q6Selected,
                  onChanged: (v) => setDlgState(() => onQ6Changed(v!)),
                ),
                const Text('6(A)'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: q6A,
                    enabled: q6Selected == 'A',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 24),
                Radio<String>(
                  value: 'B',
                  groupValue: q6Selected,
                  onChanged: (v) => setDlgState(() => onQ6Changed(v!)),
                ),
                const Text('6(B)'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: q6B,
                    enabled: q6Selected == 'B',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('Q7: Any 2 of 3', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ...['A', 'B', 'C'].map((opt) {
                  final ctrl = opt == 'A' ? q7A : opt == 'B' ? q7B : q7C;
                  final isSel = q7Selected.contains(opt);
                  return Row(
                    children: [
                      Checkbox(
                        value: isSel,
                        onChanged: (v) {
                          setDlgState(() {
                            if (v == true) {
                              q7Selected.add(opt);
                            } else {
                              q7Selected.remove(opt);
                            }
                          });
                        },
                      ),
                      Text('7($opt)'),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: ctrl,
                          enabled: isSel,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  );
                }).toList(),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('Q8: Any 2 of 3', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ...['A', 'B', 'C'].map((opt) {
                  final ctrl = opt == 'A' ? q8A : opt == 'B' ? q8B : q8C;
                  final isSel = q8Selected.contains(opt);
                  return Row(
                    children: [
                      Checkbox(
                        value: isSel,
                        onChanged: (v) {
                          setDlgState(() {
                            if (v == true) {
                              q8Selected.add(opt);
                            } else {
                              q8Selected.remove(opt);
                            }
                          });
                        },
                      ),
                      Text('8($opt)'),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: ctrl,
                          enabled: isSel,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
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
    int total = 0;

    final partAData = <Map<String, dynamic>>[];
    for (var i = 0; i < 5; i++) {
      final text = partACtrls[i].text.trim();
      final val = text.isEmpty ? 0 : int.tryParse(text);
      if (val == null || val < 0 || val > 2) {
        _showErr(context, 'Part-A Q${i + 1} must be an integer between 0 and 2');
        return null;
      }
      total += val;
      partAData.add({'question': 'Q${i + 1}', 'marks': val});
    }

    final q6ValStr = q6Selected == 'A' ? q6A.text.trim() : q6B.text.trim();
    final q6Val = q6ValStr.isEmpty ? 0 : int.tryParse(q6ValStr);
    if (q6Val == null || q6Val < 0 || q6Val > 8) {
      _showErr(context, 'Q6(${q6Selected}) must be between 0 and 8');
      return null;
    }
    total += q6Val;

    if (q7Selected.length != 2) {
      _showErr(context, 'You must select exactly 2 options for Q7');
      return null;
    }
    for (final opt in q7Selected) {
      final ctrl = opt == 'A' ? q7A : opt == 'B' ? q7B : q7C;
      final val = ctrl.text.trim().isEmpty ? 0 : int.tryParse(ctrl.text.trim());
      if (val == null || val < 0 || val > 8) {
        _showErr(context, 'Q7($opt) marks must be between 0 and 8');
        return null;
      }
      total += val;
    }

    if (q8Selected.length != 2) {
      _showErr(context, 'You must select exactly 2 options for Q8');
      return null;
    }
    for (final opt in q8Selected) {
      final ctrl = opt == 'A' ? q8A : opt == 'B' ? q8B : q8C;
      final val = ctrl.text.trim().isEmpty ? 0 : int.tryParse(ctrl.text.trim());
      if (val == null || val < 0 || val > 8) {
        _showErr(context, 'Q8($opt) marks must be between 0 and 8');
        return null;
      }
      total += val;
    }

    final partBData = {
      'q6Selected': q6Selected,
      'q6A': q6Selected == 'A' ? q6Val : 0,
      'q6B': q6Selected == 'B' ? q6Val : 0,
      'q7Selected': q7Selected.toList(),
      'q7A': q7Selected.contains('A') ? int.tryParse(q7A.text.trim()) ?? 0 : 0,
      'q7B': q7Selected.contains('B') ? int.tryParse(q7B.text.trim()) ?? 0 : 0,
      'q7C': q7Selected.contains('C') ? int.tryParse(q7C.text.trim()) ?? 0 : 0,
      'q8Selected': q8Selected.toList(),
      'q8A': q8Selected.contains('A') ? int.tryParse(q8A.text.trim()) ?? 0 : 0,
      'q8B': q8Selected.contains('B') ? int.tryParse(q8B.text.trim()) ?? 0 : 0,
      'q8C': q8Selected.contains('C') ? int.tryParse(q8C.text.trim()) ?? 0 : 0,
    };

    return {
      'total': total,
      'breakdown': {
        'partA': partAData,
        'partB': partBData,
      }
    };
  }

  void _showErr(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFF43F5E)));
  }
}
