import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

/// Faculty page to log which topic was covered in each period,
/// along with teaching method (Board, PPT, Animation, custom), COs covered,
/// and optional remarks. Acts as a digital course diary.
class FacultyCourseDiaryPage extends StatefulWidget {
  const FacultyCourseDiaryPage({super.key});

  @override
  State<FacultyCourseDiaryPage> createState() => _FacultyCourseDiaryPageState();
}

class _FacultyCourseDiaryPageState extends State<FacultyCourseDiaryPage> {
  String? _selectedCourseId;
  bool _showAddForm = false;
  String _viewMode = 'list'; // 'list' or 'calendar'

  // Add entry form state
  final _topicCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _customMethodCtrl = TextEditingController();
  String _selectedMethod = 'Board';
  bool _useCustomMethod = false;
  int _selectedUnit = 1;
  int _selectedHour = 1;
  String _selectedSection = 'A';
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedCOs = [];
  int _absentCount = 0;

  static const _defaultMethods = [
    'Board',
    'PPT',
    'Animation',
    'Live Coding',
    'Video',
    'Group Discussion',
    'Lab Demo',
    'Flipped Classroom',
    'Board + PPT',
    'PPT + Live Coding',
    'Board + Animation',
  ];

  static const _hourSlots = {
    1: '08:30-09:20',
    2: '09:20-10:10',
    3: '10:30-11:20',
    4: '11:20-12:10',
    5: '01:00-01:50',
    6: '01:50-02:40',
    7: '02:40-03:30',
  };

  static const _dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    _remarksCtrl.dispose();
    _customMethodCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid);
      if (_selectedCourseId == null && courses.isNotEmpty) {
        _selectedCourseId = courses.first['courseId'] as String?;
      }

      final diary = _selectedCourseId != null
          ? ds.getCourseDiary(_selectedCourseId!)
          : <Map<String, dynamic>>[];
      final course = courses.firstWhere(
        (c) => c['courseId'] == _selectedCourseId,
        orElse: () => <String, dynamic>{},
      );
      final sections =
          (course['sections'] as List<dynamic>?)?.cast<String>() ?? ['A'];
      final syllabus = ds.getCourseSyllabus(_selectedCourseId ?? '');
      final units = syllabus.isNotEmpty
          ? ((syllabus.first['units'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final cos = ds.getCourseOutcomeCOs(_selectedCourseId ?? '');

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => setState(() => _showAddForm = !_showAddForm),
          backgroundColor: AppColors.primary,
          icon: Icon(_showAddForm ? Icons.close : Icons.add, size: 20),
          label: Text(_showAddForm ? 'Cancel' : 'Log Entry'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header
              _buildHeader(diary.length),
              const SizedBox(height: 20),

              // ── Course Selector + View Toggle
              _buildControls(courses),
              const SizedBox(height: 20),

              // ── Stats Row
              if (diary.isNotEmpty) ...[
                _buildStatsRow(diary, units),
                const SizedBox(height: 20),
              ],

              // ── Add Entry Form
              if (_showAddForm) ...[
                _buildAddEntryForm(ds, units, cos, sections),
                const SizedBox(height: 20),
              ],

              // ── Diary Entries
              if (diary.isEmpty)
                _buildEmptyState()
              else if (_viewMode == 'list')
                _buildDiaryList(diary)
              else
                _buildCalendarView(diary),
            ],
          ),
        ),
      );
    });
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader(int entryCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_calendar,
              color: AppColors.accent, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Course Timetable Log',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              Text(
                'Record topics covered each period with teaching method',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$entryCount entries',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }

  // ── Controls: Course Selector + View Toggle ────────────
  Widget _buildControls(List<Map<String, dynamic>> courses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Row(
        children: [
          const Icon(Icons.class_, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          const Text('Course: ',
              style: TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButton<String>(
                value: _selectedCourseId,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.textDark),
                items: courses
                    .map((c) => DropdownMenuItem(
                          value: c['courseId'] as String?,
                          child: Text(
                              '${c['courseId']} - ${c['courseName'] ?? ''}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedCourseId = v;
                  _showAddForm = false;
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ToggleButtons(
            isSelected: [_viewMode == 'list', _viewMode == 'calendar'],
            onPressed: (i) =>
                setState(() => _viewMode = i == 0 ? 'list' : 'calendar'),
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: AppColors.primary,
            color: AppColors.textLight,
            constraints: const BoxConstraints(minWidth: 42, minHeight: 36),
            children: const [
              Icon(Icons.list, size: 20),
              Icon(Icons.calendar_month, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────
  Widget _buildStatsRow(
      List<Map<String, dynamic>> diary, List<Map<String, dynamic>> units) {
    // Method distribution
    final methodCounts = <String, int>{};
    for (final e in diary) {
      final m = e['teachingMethod']?.toString() ?? 'Other';
      methodCounts[m] = (methodCounts[m] ?? 0) + 1;
    }
    final topMethod = methodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Units covered count
    final unitsCovered = diary.map((e) => e['unitNo']).toSet().length;
    final totalUnits = units.length > 0 ? units.length : 5;

    // Unique dates = number of classes taken
    final classesTaken = diary.map((e) => '${e['date']}_${e['hour']}').toSet().length;

    return Row(
      children: [
        _statCard('Classes Logged', '$classesTaken', Icons.check_circle,
            AppColors.secondary),
        const SizedBox(width: 12),
        _statCard('Units Covered', '$unitsCovered / $totalUnits',
            Icons.layers, AppColors.primary),
        const SizedBox(width: 12),
        _statCard(
            'Top Method',
            topMethod.isNotEmpty ? topMethod.first.key : '-',
            Icons.school,
            AppColors.accent),
        const SizedBox(width: 12),
        _statCard(
            'Methods Used',
            '${methodCounts.length}',
            Icons.category,
            Colors.deepPurple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Entry Form ─────────────────────────────────────
  Widget _buildAddEntryForm(
    DataService ds,
    List<Map<String, dynamic>> units,
    List<Map<String, dynamic>> cos,
    List<String> sections,
  ) {
    if (sections.isNotEmpty && !sections.contains(_selectedSection)) {
      _selectedSection = sections.first;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_task, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text('Log New Entry',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1: Date, Hour, Section
          Row(
            children: [
              // Date picker
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
                          style: const TextStyle(
                              color: AppColors.textDark, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${_dayNames[_selectedDate.weekday]})',
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Hour dropdown
              Expanded(
                child: _dropdownField<int>(
                  'Hour',
                  _selectedHour,
                  _hourSlots.keys.toList(),
                  (v) => 'Hr $v (${_hourSlots[v]})',
                  (v) => setState(() => _selectedHour = v!),
                ),
              ),
              const SizedBox(width: 12),
              // Section dropdown
              Expanded(
                child: _dropdownField<String>(
                  'Section',
                  _selectedSection,
                  sections,
                  (v) => 'Sec $v',
                  (v) => setState(() => _selectedSection = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Unit, Topic
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: _dropdownField<int>(
                  'Unit',
                  _selectedUnit,
                  List.generate(
                      units.isNotEmpty ? units.length : 5, (i) => i + 1),
                  (v) => 'Unit $v',
                  (v) => setState(() => _selectedUnit = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(_topicCtrl, 'Topic Covered *',
                    'e.g. Binary Search Tree - Insertion & Deletion',
                    maxLines: 2),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Teaching Method
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Teaching Method *',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._defaultMethods.map((m) => _methodChip(m)),
                        // Custom method toggle
                        ActionChip(
                          avatar: Icon(
                              _useCustomMethod ? Icons.close : Icons.edit,
                              size: 16),
                          label:
                              Text(_useCustomMethod ? 'Cancel' : 'Custom...'),
                          onPressed: () => setState(
                              () => _useCustomMethod = !_useCustomMethod),
                          backgroundColor: _useCustomMethod
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : null,
                        ),
                      ],
                    ),
                    if (_useCustomMethod) ...[
                      const SizedBox(height: 8),
                      _textField(_customMethodCtrl, 'Custom Method',
                          'Type your own teaching method'),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 4: COs Covered
          if (cos.isNotEmpty) ...[
            const Text('COs Covered',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cos.map((co) {
                final coId = co['coId']?.toString() ?? '';
                final selected = _selectedCOs.contains(coId);
                return FilterChip(
                  label: Text(coId),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _selectedCOs.add(coId);
                      } else {
                        _selectedCOs.remove(coId);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Row 5: Absent count + Remarks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Absent Students',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20),
                          onPressed: _absentCount > 0
                              ? () =>
                                  setState(() => _absentCount--)
                              : null,
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text('$_absentCount',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () =>
                              setState(() => _absentCount++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _textField(
                    _remarksCtrl, 'Remarks (optional)',
                    'e.g. Quiz conducted, assignment given...'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Submit button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _submitEntry(ds),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String method) {
    final selected = !_useCustomMethod && _selectedMethod == method;
    return ChoiceChip(
      label: Text(method),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textMedium,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (sel) {
        if (sel) {
          setState(() {
            _selectedMethod = method;
            _useCustomMethod = false;
            _customMethodCtrl.clear();
          });
        }
      },
    );
  }

  void _submitEntry(DataService ds) {
    if (_topicCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the topic covered')),
      );
      return;
    }

    final method = _useCustomMethod && _customMethodCtrl.text.trim().isNotEmpty
        ? _customMethodCtrl.text.trim()
        : _selectedMethod;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    ds.addDiaryEntry({
      'courseId': _selectedCourseId,
      'facultyId': ds.currentUserId,
      'date': dateStr,
      'day': _dayNames[_selectedDate.weekday],
      'hour': _selectedHour,
      'time': _hourSlots[_selectedHour] ?? '',
      'section': _selectedSection,
      'unitNo': _selectedUnit,
      'topicCovered': _topicCtrl.text.trim(),
      'teachingMethod': method,
      'cosCovered': List<String>.from(_selectedCOs),
      'remarks': _remarksCtrl.text.trim(),
      'absentCount': _absentCount,
      'totalStudents': 60,
    });

    _topicCtrl.clear();
    _remarksCtrl.clear();
    _customMethodCtrl.clear();
    _selectedCOs.clear();
    _absentCount = 0;
    _useCustomMethod = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diary entry saved successfully!'),
        backgroundColor: AppColors.secondary,
      ),
    );
    setState(() => _showAddForm = false);
  }

  // ── Diary List View ────────────────────────────────────
  Widget _buildDiaryList(List<Map<String, dynamic>> diary) {
    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in diary) {
      final date = e['date']?.toString() ?? '';
      grouped.putIfAbsent(date, () => []).add(e);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dates.map((date) {
        final entries = grouped[date]!
          ..sort((a, b) =>
              ((a['hour'] as int?) ?? 0).compareTo((b['hour'] as int?) ?? 0));
        final day = entries.first['day'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppCardStyles.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(_formatDate(date),
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(width: 8),
                    Text('($day)',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                    const Spacer(),
                    Text('${entries.length} periods',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              // Entry cards
              ...entries.map((e) => _buildEntryCard(e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final method = entry['teachingMethod']?.toString() ?? '';
    final methodColor = _getMethodColor(method);
    final cosList =
        (entry['cosCovered'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hour badge
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('Hr ${entry['hour']}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(entry['time']?.toString().split('-').first ?? '',
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry['topicCovered']?.toString() ?? '',
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                    _tag('Sec ${entry['section'] ?? ''}', AppColors.textLight),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tag(method, methodColor),
                    const SizedBox(width: 8),
                    _tag('Unit ${entry['unitNo'] ?? ''}', AppColors.primary),
                    if (cosList.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ...cosList
                          .map((co) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _tag(co, Colors.deepPurple),
                              ))
                          ,
                    ],
                    if ((entry['absentCount'] as int?) != null &&
                        (entry['absentCount'] as int) > 0) ...[
                      const Spacer(),
                      _tag('${entry['absentCount']} absent', Colors.red),
                    ],
                  ],
                ),
                if (entry['remarks']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(entry['remarks'].toString(),
                      style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar View ──────────────────────────────────────
  Widget _buildCalendarView(List<Map<String, dynamic>> diary) {
    // Show current week's schedule
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(6, (i) => monday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week\'s Log',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8)),
            columnWidths: const {
              0: FixedColumnWidth(70),
            },
            children: [
              // Header
              TableRow(
                decoration:
                    BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08)),
                children: [
                  const _TableHeader('Hour'),
                  ...weekDays.map((d) => _TableHeader(
                      '${_dayNames[d.weekday].substring(0, 3)}\n${d.day}/${d.month}')),
                ],
              ),
              // 7 hours
              ...List.generate(7, (hi) {
                final hour = hi + 1;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          Text('$hour',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  fontSize: 13)),
                          Text(_hourSlots[hour]?.split('-').first ?? '',
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 11)),
                        ],
                      ),
                    ),
                    ...weekDays.map((d) {
                      final dateStr =
                          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      final match = diary.where((e) =>
                          e['date'] == dateStr && e['hour'] == hour);
                      if (match.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text('-',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppColors.textLight)),
                        );
                      }
                      final e = match.first;
                      final method =
                          e['teachingMethod']?.toString() ?? '';
                      final color = _getMethodColor(method);
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              Text(
                                (e['topicCovered']?.toString() ?? '')
                                    .substring(
                                        0,
                                        (e['topicCovered']?.toString() ?? '')
                                                    .length >
                                                20
                                            ? 20
                                            : (e['topicCovered']?.toString() ??
                                                    '')
                                                .length),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(method,
                                  style: TextStyle(
                                      color: color.withValues(alpha: 0.85),
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: AppCardStyles.elevated,
      child: Column(
        children: [
          Icon(Icons.edit_calendar,
              size: 56, color: AppColors.textLight.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('No diary entries yet',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
              'Tap "Log Entry" to record the first topic for this course',
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────
  Color _getMethodColor(String method) {
    final m = method.toLowerCase();
    if (m.contains('board') && m.contains('ppt')) return Colors.teal;
    if (m.contains('board')) return Colors.blue;
    if (m.contains('ppt')) return Colors.orange;
    if (m.contains('animation')) return Colors.purple;
    if (m.contains('live') || m.contains('coding')) return Colors.green;
    if (m.contains('video')) return Colors.red;
    if (m.contains('lab')) return Colors.indigo;
    if (m.contains('group') || m.contains('discussion')) return Colors.cyan;
    if (m.contains('flip')) return Colors.deepOrange;
    return AppColors.textMedium;
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${parts[2]} ${months[int.parse(parts[1])]} ${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _dropdownField<T>(String label, T value, List<T> items,
      String Function(T) displayText, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<T>(
            value: items.contains(value) ? value : (items.isNotEmpty ? items.first : value),
            isExpanded: true,
            dropdownColor: AppColors.surface,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.textDark, fontSize: 13),
            items: items
                .map((v) => DropdownMenuItem(
                    value: v, child: Text(displayText(v))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    );
  }
}
