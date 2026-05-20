import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyAttendancePage extends StatefulWidget {
  const FacultyAttendancePage({super.key});

  @override
  State<FacultyAttendancePage> createState() => _FacultyAttendancePageState();
}

class _FacultyAttendancePageState extends State<FacultyAttendancePage> with SingleTickerProviderStateMixin {
  String? _selectedCourse;
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _sessionType = 'Lecture';
  int _sessionHour = 1;

  // Mark-attendance toggles: studentId → true (present) / false (absent)
  final Map<String, bool> _attendanceMap = {};
  bool _allPresent = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initAttendanceMap(List<Map<String, dynamic>> students) {
    for (final s in students) {
      final sid = s['studentId'] as String? ?? '';
      if (sid.isNotEmpty && !_attendanceMap.containsKey(sid)) {
        _attendanceMap[sid] = true; // default: present
      }
    }
    _allPresent = _attendanceMap.values.every((v) => v);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid);
      if (_selectedCourse == null && courses.isNotEmpty) {
        _selectedCourse = courses.first['courseId'] as String?;
      }
      final students = _selectedCourse != null ? ds.getCourseStudents(_selectedCourse!) : <Map<String, dynamic>>[];
      final attendance = _selectedCourse != null ? ds.getCourseAttendance(_selectedCourse!) : <Map<String, dynamic>>[];

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return Column(children: [
            // Header & course selector
            Container(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, isMobile ? 16 : 24, isMobile ? 16 : 28, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Attendance Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3))),
                ]),
                const SizedBox(height: 20),
                _buildCourseSelector(courses),
                const SizedBox(height: 16),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    labelColor: Colors.white, unselectedLabelColor: AppColors.textMedium,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Mark Attendance'),
                      Tab(text: 'View Records'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMarkTab(isMobile, students, ds),
                  _buildViewTab(isMobile, students, attendance),
                ],
              ),
            ),
          ]);
        }),
      );
    });
  }

  Widget _buildCourseSelector(List<Map<String, dynamic>> courses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: DropdownButton<String>(
        value: _selectedCourse, isExpanded: true, dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
        items: courses.map((c) => DropdownMenuItem(
          value: c['courseId'] as String?,
          child: Text('${c['courseId']} — ${c['courseName'] ?? ''}'),
        )).toList(),
        onChanged: (v) => setState(() { _selectedCourse = v; _attendanceMap.clear(); }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: MARK ATTENDANCE
  // ═══════════════════════════════════════════════════════
  Widget _buildMarkTab(bool isMobile, List<Map<String, dynamic>> students, DataService ds) {
    _initAttendanceMap(students);
    final presentCount = _attendanceMap.values.where((v) => v).length;
    final absentCount = _attendanceMap.values.where((v) => !v).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date & session selector
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppCardStyles.elevated,
          child: isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _datePicker(),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _sessionTypePicker()),
                  const SizedBox(width: 10),
                  Expanded(child: _hourPicker()),
                ]),
              ])
            : Row(children: [
                Expanded(flex: 2, child: _datePicker()),
                const SizedBox(width: 16),
                Expanded(child: _sessionTypePicker()),
                const SizedBox(width: 16),
                SizedBox(width: 100, child: _hourPicker()),
              ]),
        ),
        const SizedBox(height: 18),
        // Quick actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: AppCardStyles.elevated,
          child: Row(children: [
            // Present/Absent count badges
            _countBadge('Present', presentCount, const Color(0xFF10B981)),
            const SizedBox(width: 10),
            _countBadge('Absent', absentCount, const Color(0xFFF43F5E)),
            const Spacer(),
            // Mark All toggle
            TextButton.icon(
              onPressed: () => setState(() {
                _allPresent = !_allPresent;
                for (final key in _attendanceMap.keys) {
                  _attendanceMap[key] = _allPresent;
                }
              }),
              icon: Icon(_allPresent ? Icons.check_circle : Icons.cancel, size: 18,
                color: _allPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
              label: Text(_allPresent ? 'Mark All Absent' : 'Mark All Present',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _allPresent ? const Color(0xFFF43F5E) : const Color(0xFF10B981))),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // Student toggles
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppCardStyles.elevated,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.people_rounded, size: 18, color: AppColors.textMedium),
              const SizedBox(width: 8),
              Text('Students (${students.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 14),
            if (students.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No students enrolled in this course', style: TextStyle(color: AppColors.textLight))))
            else
              ...students.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final sid = s['studentId'] as String? ?? '';
                final name = s['name'] as String? ?? 'Student';
                final regNo = s['registerNumber'] as String? ?? sid;
                final isPresent = _attendanceMap[sid] ?? true;
                final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isPresent ? const Color(0xFF10B981).withValues(alpha: 0.04) : const Color(0xFFF43F5E).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isPresent ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF43F5E).withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    // Index
                    SizedBox(width: 28, child: Text('${i + 1}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                    // Avatar
                    CircleAvatar(radius: 16, backgroundColor: isPresent ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF43F5E).withValues(alpha: 0.12),
                      child: Text(initials, style: TextStyle(color: isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E), fontSize: 11, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 12),
                    // Name + reg no
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(regNo, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ])),
                    // Status chip
                    GestureDetector(
                      onTap: () => setState(() {
                        _attendanceMap[sid] = !isPresent;
                        _allPresent = _attendanceMap.values.every((v) => v);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: (isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(isPresent ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(isPresent ? 'Present' : 'Absent', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                );
              }),
          ]),
        ),
        const SizedBox(height: 20),
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: students.isEmpty ? null : () => _submitAttendance(ds, students),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text('Save Attendance — ${DateFormat('d MMM yyyy').format(_selectedDate)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(DateFormat('EEEE, d MMM yyyy').format(_selectedDate), style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  Widget _sessionTypePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: _sessionType, isExpanded: true, underline: const SizedBox(),
        style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
        items: const [
          DropdownMenuItem(value: 'Lecture', child: Text('Lecture')),
          DropdownMenuItem(value: 'Lab', child: Text('Lab')),
          DropdownMenuItem(value: 'Tutorial', child: Text('Tutorial')),
        ],
        onChanged: (v) => setState(() => _sessionType = v ?? 'Lecture'),
      ),
    );
  }

  Widget _hourPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<int>(
        value: _sessionHour, isExpanded: true, underline: const SizedBox(),
        style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
        items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Hour ${i + 1}'))),
        onChanged: (v) => setState(() => _sessionHour = v ?? 1),
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _submitAttendance(DataService ds, List<Map<String, dynamic>> students) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    for (final s in students) {
      final sid = s['studentId'] as String? ?? '';
      if (sid.isEmpty) continue;
      final isPresent = _attendanceMap[sid] ?? true;
      ds.markAttendance(_selectedCourse!, sid, isPresent);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Attendance saved for ${students.length} students — $dateStr ($_sessionType, Hour $_sessionHour)'),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 2: VIEW RECORDS
  // ═══════════════════════════════════════════════════════
  Widget _buildViewTab(bool isMobile, List<Map<String, dynamic>> students, List<Map<String, dynamic>> attendance) {
    // Stats
    int totalStudents = 0, avgAttendance = 0;
    if (attendance.isNotEmpty) {
      totalStudents = attendance.length;
      int totalPresent = 0, totalClasses = 0;
      for (final a in attendance) {
        totalPresent += (a['attendedClasses'] as int?) ?? 0;
        totalClasses += (a['totalClasses'] as int?) ?? 0;
      }
      avgAttendance = totalClasses > 0 ? (totalPresent * 100 ~/ totalClasses) : 0;
    }
    final belowThreshold = attendance.where((a) {
      final total = (a['totalClasses'] as int?) ?? 1;
      final attended = (a['attendedClasses'] as int?) ?? 0;
      return total > 0 && (attended / total * 100) < 75;
    }).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats cards
        if (isMobile)
          Column(children: [
            Row(children: [
              Expanded(child: _statCard('Total Students', '$totalStudents', Icons.people_rounded, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Avg Attendance', '$avgAttendance%', Icons.trending_up_rounded, const Color(0xFF10B981))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('Below 75%', '$belowThreshold', Icons.warning_rounded, const Color(0xFFF43F5E))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Total Records', '${attendance.length}', Icons.list_alt_rounded, const Color(0xFF8B5CF6))),
            ]),
          ])
        else
          Row(children: [
            Expanded(child: _statCard('Total Students', '$totalStudents', Icons.people_rounded, const Color(0xFF3B82F6))),
            const SizedBox(width: 14),
            Expanded(child: _statCard('Avg Attendance', '$avgAttendance%', Icons.trending_up_rounded, const Color(0xFF10B981))),
            const SizedBox(width: 14),
            Expanded(child: _statCard('Below 75%', '$belowThreshold', Icons.warning_rounded, const Color(0xFFF43F5E))),
            const SizedBox(width: 14),
            Expanded(child: _statCard('Records', '${attendance.length}', Icons.list_alt_rounded, const Color(0xFF8B5CF6))),
          ]),
        const SizedBox(height: 24),
        // Student detail table
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCardStyles.elevated,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.textMedium),
              const SizedBox(width: 8),
              const Text('Attendance Records', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 16),
            if (students.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No students enrolled', style: TextStyle(color: AppColors.textLight))))
            else
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceVariant.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  SizedBox(width: isMobile ? 60 : 90, child: const Text('ID', style: TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600))),
                  const Expanded(child: Text('Name', style: TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600))),
                  SizedBox(width: isMobile ? 60 : 80, child: const Text('Classes', style: TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600))),
                  SizedBox(width: isMobile ? 50 : 70, child: const Text('%', style: TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600))),
                  if (!isMobile) const SizedBox(width: 120, child: Text('Progress', style: TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600))),
                ]),
              ),
            const SizedBox(height: 6),
            ...students.map((s) {
              final sid = s['studentId'] as String? ?? '';
              final att = attendance.where((a) => a['studentId'] == sid).toList();
              int attended = 0, total = 0;
              if (att.isNotEmpty) {
                attended = (att.first['attendedClasses'] as int?) ?? 0;
                total = (att.first['totalClasses'] as int?) ?? 0;
              }
              final pct = total > 0 ? (attended / total * 100) : 0.0;
              final color = pct >= 75 ? const Color(0xFF10B981) : pct >= 60 ? const Color(0xFFF97316) : const Color(0xFFF43F5E);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: pct < 75 ? const Color(0xFFF43F5E).withValues(alpha: 0.03) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pct < 75 ? const Color(0xFFF43F5E).withValues(alpha: 0.1) : AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  SizedBox(width: isMobile ? 60 : 90, child: Text(sid, style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
                  Expanded(child: Text(s['name'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 13))),
                  SizedBox(width: isMobile ? 60 : 80, child: Text('$attended/$total', style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
                  SizedBox(width: isMobile ? 50 : 70, child: Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
                  if (!isMobile) SizedBox(width: 120, child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100, minHeight: 6,
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )),
                ]),
              );
            }),
          ]),
        ),
      ]),
    );
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
}
