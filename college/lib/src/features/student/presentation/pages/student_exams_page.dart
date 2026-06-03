import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentExamsPage extends StatelessWidget {
  const StudentExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final masterKey = ds.activeMasterKey;
      final exams = ds.getStudentExams(uid, masterKey: masterKey);
      final courses = ds.getStudentCourses(uid, masterKey: masterKey);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(context, readOnly: true),
              const SizedBox(height: 16),
              _buildPatternBanner(),
              const SizedBox(height: 16),
              _buildCOPOSummary(courses, ds),
              const SizedBox(height: 24),
              if (exams.isNotEmpty) _buildNextExamCountdown(exams.first),
              const SizedBox(height: 24),
              _buildExamScheduleTables(context, exams, ds, uid),
              const SizedBox(height: 24),
              if (exams.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No upcoming exams', style: TextStyle(color: AppColors.textLight, fontSize: 16)))),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildModernHeader(BuildContext context, {required bool readOnly}) {
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
          child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Exam Schedule', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          SizedBox(height: 4),
          Text('Internal 50-mark pattern, CO/PO links, and scheduled exams in one place.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
          child: Text(readOnly ? 'Read Only' : 'Editable', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
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
          const Text('No enrolled courses found.', style: TextStyle(color: AppColors.textLight))
        else
          Wrap(spacing: 10, runSpacing: 10, children: courses.map((c) {
            final cos = ds.getCourseOutcomeCOs(c['courseId'] as String? ?? '');
            final totalCo = cos.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
              child: Text('${c['courseCode'] ?? ''}: $totalCo COs', style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }).toList()),
      ]),
    );
  }

  Widget _buildNextExamCountdown(Map<String, dynamic> exam) {
    final daysLeft = DateTime.tryParse(exam['date'] ?? '')?.difference(DateTime.now()).inDays ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Next Exam', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${exam['courseId'] ?? ''} - ${exam['examName'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${exam['date'] ?? ''} | ${exam['time'] ?? ''} | ${exam['venue'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          )),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('$daysLeft', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const Text('DAYS LEFT', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamScheduleTables(BuildContext context, List<Map<String, dynamic>> exams, DataService ds, String uid) {
    final internal = exams.where((e) => (e['type'] ?? '').toString().toLowerCase().contains('internal')).toList();
    final external = exams.where((e) => !(e['type'] ?? '').toString().toLowerCase().contains('internal')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTable(context, title: 'Internal Assessments', accent: const Color(0xFF2563EB), exams: internal, ds: ds, uid: uid, readOnly: true),
        const SizedBox(height: 18),
        _buildSectionTable(context, title: 'End Semester / External Examinations', accent: const Color(0xFF10B981), exams: external, ds: ds, uid: uid, readOnly: true),
      ],
    );
  }

  Widget _buildSectionTable(
    BuildContext context, {
    required String title,
    required Color accent,
    required List<Map<String, dynamic>> exams,
    required DataService ds,
    required String uid,
    required bool readOnly,
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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
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
                constraints: const BoxConstraints(minWidth: 1240),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(color: const Color(0xFF9AA7BB), width: 1),
                  columnWidths: const {
                    0: FixedColumnWidth(54),
                    1: FixedColumnWidth(116),
                    2: FixedColumnWidth(300),
                    3: FixedColumnWidth(120),
                    4: FixedColumnWidth(100),
                    5: FixedColumnWidth(100),
                    6: FixedColumnWidth(100),
                    7: FixedColumnWidth(110),
                    8: FixedColumnWidth(100),
                    9: FixedColumnWidth(110), // Marks column
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
                        _headerCell('Marks'),
                      ],
                    ),
                    ...List.generate(exams.length, (index) {
                      final e = exams[index];
                      final type = (e['type'] ?? '').toString();
                      final isInternal = type.toLowerCase().contains('internal');
                      final courseId = e['courseId'] as String? ?? '';
                      final course = ds.getCourseById(courseId);
                      final courseTitle = course?['courseName']?.toString() ?? e['courseTitle']?.toString() ?? '';
                      final pattern = isInternal ? '50-mark IA' : 'External';

                      // Find matching result for this student and exam
                      final results = ds.getStudentResultsFiltered(uid);
                      final examName = e['examName'] as String? ?? '';
                      final matchingResult = results.firstWhere(
                        (r) => r['courseId'] == courseId &&
                               (r['examType'] == examName || r['examType'] == type || (examName.toLowerCase().contains(r['examType']?.toString().toLowerCase() ?? 'xxx'))),
                        orElse: () => <String, dynamic>{},
                      );

                      final hasMarks = matchingResult.isNotEmpty;
                      final marksText = hasMarks ? '${matchingResult['obtainedMarks'] ?? matchingResult['marks'] ?? 0} / 50' : '-';

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

                      if (hasMarks && isInternal) {
                        cells.add(
                          SizedBox(
                            height: 32,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(marksText, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(width: 4),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                                  tooltip: 'View breakdown',
                                  onPressed: () => _showStudentBreakdownDialog(context, matchingResult),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        cells.add(_bodyCell(marksText));
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
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCell(String value, Color color) {
    return SizedBox(
      height: 32,
      child: Center(child: _pill(value, color)),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  void _showStudentBreakdownDialog(BuildContext context, Map<String, dynamic> result) {
    final breakdown = (result['paperBreakdown'] as Map<String, dynamic>?) ?? {};
    final partA = ((breakdown['partA'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final partB = (breakdown['partB'] as Map<String, dynamic>?) ?? {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Marks Breakdown', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Obtained: ${result['obtainedMarks'] ?? result['marks'] ?? 0} / 50', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                    Text('Grade: ${result['grade'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Part-A (Questions 1 - 5)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final qMark = i < partA.length ? partA[i]['marks']?.toString() ?? '0' : '0';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                    child: Column(children: [
                      Text('A${i+1}', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(qMark, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
                    ]),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Part-B', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
              const SizedBox(height: 8),
              _buildPartBDetailRow('Q6 (Choose 1)', 'Selected Option: ${partB['q6Selected'] ?? "N/A"}', 'Marks: ${partB['q6Selected'] == "A" ? partB['q6A'] : partB['q6B'] ?? 0}'),
              const SizedBox(height: 8),
              _buildPartBDetailRow('Q7 (Choose 2)', 'Selected: ${(partB['q7Selected'] as List<dynamic>?)?.join(", ") ?? "N/A"}', 'Marks: ${((partB['q7Selected'] as List<dynamic>?) ?? []).map((x) => "$x: ${partB['q7$x'] ?? 0}").join(", ")}'),
              const SizedBox(height: 8),
              _buildPartBDetailRow('Q8 (Choose 2)', 'Selected: ${(partB['q8Selected'] as List<dynamic>?)?.join(", ") ?? "N/A"}', 'Marks: ${((partB['q8Selected'] as List<dynamic>?) ?? []).map((x) => "$x: ${partB['q8$x'] ?? 0}").join(", ")}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPartBDetailRow(String label, String detail, String marks) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ]),
          Text(marks, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}
