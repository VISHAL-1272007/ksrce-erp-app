import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentResultsPage extends StatelessWidget {
  const StudentResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final studentId = ds.currentUserId ?? '';
      final resultsList = ds.getStudentResultsFiltered(studentId, masterKey: ds.activeMasterKey);
      final cgpa = ds.currentCGPA;
      final sections = _groupResults(resultsList);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.assessment, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Student Marks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.lock_rounded, size: 16, color: AppColors.textLight),
                    SizedBox(width: 6),
                    Text(
                      'Published results only • read-only view',
                      style: TextStyle(color: AppColors.textLight, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<DataService>(builder: (context, ds, _) {
                  final mk = ds.activeMasterKey ?? ds.currentMasterKey ?? '—';
                  final hod = ds.getHODForMasterKey(mk);
                  final hodName = (hod != null && hod.isNotEmpty) ? (hod['name'] ?? hod['facultyName'] ?? '') : '—';
                  return Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: AppColors.textLight),
                      const SizedBox(width: 6),
                      Text('MasterKey: ${ds.getMasterKeyLabel(mk)}', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                      const SizedBox(width: 12),
                      Text('HOD: $hodName', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                _buildCGPACard(cgpa),
                const SizedBox(height: 12),
                _buildStudentCourseOutcomes(ds, studentId),
                const SizedBox(height: 24),
                if (sections.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppCardStyles.elevated,
                    child: const Center(
                      child: Text(
                        'No published results yet',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ),
                  )
                else
                  ...sections.map((section) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _buildSectionCard(section, isMobile),
                    );
                  }),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildStudentCourseOutcomes(DataService ds, String studentId) {
    final courses = ds.getStudentCourses(studentId);
    if (courses.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Course Outcomes (CO) for your enrolled courses',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...courses.map((c) {
          final cos = ds.getCourseOutcomeCOs(c['courseId']);
          return ExpansionTile(
            title: Text('${c['courseCode']} - ${c['courseName'] ?? ''}'),
            children: cos.isEmpty
                ? [const ListTile(title: Text('No COs defined'))]
                : cos.map((co) => ListTile(
                      title: Text(co['coId'] ?? ''),
                      subtitle: Text(co['description'] ?? ''),
                    )).toList(),
          );
        }).toList(),
      ]),
    );
  }

  Widget _buildCGPACard(double cgpa) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: AppColors.accent, size: 32),
          const SizedBox(width: 16),
          Column(
            children: [
              const Text(
                'Current CGPA',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cgpa.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_MarksSection section, bool isMobile) {
    final headers = _headersForSection(section.kind);
    final rows = section.items.asMap().entries.map((entry) {
      final index = entry.key + 1;
      return _buildTableRow(section.kind, index, entry.value);
    }).toList();

    final table = Table(
      border: TableBorder.all(color: const Color(0xFF9AA7BB), width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: _columnWidthsForSection(section.kind),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF3F6FB)),
          children: headers.map((h) => _headerCell(h)).toList(),
        ),
        ...rows,
      ],
    );

    return Container(
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2F66B0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isMobile ? 1180 : 1260),
                child: table,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String kind, int serial, Map<String, dynamic> result) {
    final courseCode = result['courseCode'] as String? ?? '';
    final courseName = result['courseName'] as String? ?? '';
    final marks = (result['obtainedMarks'] ?? result['marks'] ?? 0).toString();
    final total = (result['maxMarks'] ?? result['totalMarks'] ?? 0).toString();
    final displayMarks = total == '0' ? marks : '$marks/$total';
    final grade = result['grade'] as String? ?? '-';

    List<String> cells;
    if (kind == 'lab') {
      cells = [
        serial.toString(),
        courseCode,
        courseName,
        '-',
        '-',
        '-',
        '-',
        '-',
        displayMarks,
      ];
    } else if (kind == 'ssd') {
      cells = [
        serial.toString(),
        courseCode,
        courseName,
        '-',
        '-',
        '-',
        displayMarks,
      ];
    } else if (kind == 'tool') {
      cells = [
        serial.toString(),
        courseCode,
        courseName,
        '-',
        '-',
        '-',
        '-',
        '-',
        displayMarks,
      ];
    } else {
      cells = [
        serial.toString(),
        courseCode,
        courseName,
        '-',
        '-',
        '-',
        '-',
        '-',
        '-',
        '-',
        displayMarks,
        grade,
      ];
    }

    final style = TextStyle(
      color: kind == 'theory' ? const Color(0xFF0B3D91) : AppColors.textDark,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    return TableRow(
      children: cells.map((value) {
        return SizedBox(
          height: 30,
          child: Center(
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                color: value == 'Pass'
                    ? Colors.green
                    : value == 'Fail'
                        ? Colors.redAccent
                        : style.color,
                fontWeight: value == grade ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_MarksSection> _groupResults(List<Map<String, dynamic>> resultsList) {
    if (resultsList.isEmpty) return [];

    final grouped = <String, List<Map<String, dynamic>>>{};
    final sorted = [...resultsList]
      ..sort((a, b) {
        final aCode = (a['courseCode'] as String? ?? '').toLowerCase();
        final bCode = (b['courseCode'] as String? ?? '').toLowerCase();
        return aCode.compareTo(bCode);
      });

    for (final result in sorted) {
      final kind = _classifyKind(result['courseName'] as String? ?? '', result['examType'] as String? ?? '');
      grouped.putIfAbsent(kind, () => []).add(result);
    }

    final order = ['theory', 'ssd', 'lab', 'tool'];
    return order
        .where((kind) => grouped.containsKey(kind))
        .map(
          (kind) => _MarksSection(
            kind: kind,
            title: _sectionTitle(kind),
            items: grouped[kind]!,
          ),
        )
        .toList();
  }

  String _classifyKind(String courseName, String examType) {
    final name = courseName.toLowerCase();
    final exam = examType.toLowerCase();
    if (name.contains('soft skills') || name.contains('ssd') || exam.contains('ssd')) {
      return 'ssd';
    }
    if (name.contains('laboratory') || name.contains('lab') || exam.contains('lab')) {
      return 'lab';
    }
    if (name.contains('studio') || name.contains('tool') || exam.contains('tool')) {
      return 'tool';
    }
    return 'theory';
  }

  String _sectionTitle(String kind) {
    switch (kind) {
      case 'lab':
        return 'Y26 R24-2025-2026 EVEN LAB';
      case 'ssd':
        return 'Y26 R24-2025-2026 EVEN SSD';
      case 'tool':
        return 'Y26 R24-2025-2026 EVEN TOOL COURSE';
      default:
        return 'Y26 R24-2025-2026 EVEN NON INTEGRATED THEORY UG';
    }
  }

  List<String> _headersForSection(String kind) {
    switch (kind) {
      case 'lab':
        return const [
          'S.No',
          'Course Code',
          'Course Title',
          'CIE LAB 1 (100)',
          'CIE LAB 2 (100)',
          'Avg of 2 (25)',
          'RECORD (75)',
          'ATT (5)',
          'Final (60.0)',
        ];
      case 'ssd':
        return const [
          'S.No',
          'Course Code',
          'Course Title',
          'CIE 1 (50)',
          'CIE 2 (50)',
          'Avg of 2 (40)',
          'Internal (40)',
          'Final (40.0)',
        ];
      case 'tool':
        return const [
          'S.No',
          'Course Code',
          'Course Title',
          'CIE LAB 1 (50)',
          'CIE LAB 2 (50)',
          'Avg of 2 (25)',
          'ATT (5)',
          'RECORD (75)',
          'Final (50.0)',
        ];
      default:
        return const [
          'S.No',
          'Course Code',
          'Course Title',
          'CIA 1 (50)',
          'CIA 2 (50)',
          'Avg of 2 (20)',
          'A1 (50)',
          'A2 (50)',
          'Avg of 2 (15)',
          'ATTENDANCE (5)',
          'Internal (40)',
          'Final (40.0)',
        ];
    }
  }

  Map<int, TableColumnWidth> _columnWidthsForSection(String kind) {
    switch (kind) {
      case 'lab':
        return const {
          0: FixedColumnWidth(50),
          1: FixedColumnWidth(110),
          2: FixedColumnWidth(260),
          3: FixedColumnWidth(120),
          4: FixedColumnWidth(120),
          5: FixedColumnWidth(100),
          6: FixedColumnWidth(100),
          7: FixedColumnWidth(80),
          8: FixedColumnWidth(95),
        };
      case 'ssd':
        return const {
          0: FixedColumnWidth(50),
          1: FixedColumnWidth(110),
          2: FixedColumnWidth(280),
          3: FixedColumnWidth(110),
          4: FixedColumnWidth(110),
          5: FixedColumnWidth(110),
          6: FixedColumnWidth(110),
          7: FixedColumnWidth(95),
        };
      case 'tool':
        return const {
          0: FixedColumnWidth(50),
          1: FixedColumnWidth(110),
          2: FixedColumnWidth(260),
          3: FixedColumnWidth(115),
          4: FixedColumnWidth(115),
          5: FixedColumnWidth(100),
          6: FixedColumnWidth(80),
          7: FixedColumnWidth(95),
          8: FixedColumnWidth(95),
        };
      default:
        return const {
          0: FixedColumnWidth(54),
          1: FixedColumnWidth(116),
          2: FixedColumnWidth(320),
          3: FixedColumnWidth(108),
          4: FixedColumnWidth(108),
          5: FixedColumnWidth(108),
          6: FixedColumnWidth(96),
          7: FixedColumnWidth(96),
          8: FixedColumnWidth(112),
          9: FixedColumnWidth(118),
          10: FixedColumnWidth(106),
          11: FixedColumnWidth(106),
        };
    }
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
}

class _MarksSection {
  final String kind;
  final String title;
  final List<Map<String, dynamic>> items;

  const _MarksSection({
    required this.kind,
    required this.title,
    required this.items,
  });
}
