import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyDashboardPage extends StatelessWidget {
  const FacultyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final facultyId = ds.currentUserId ?? '';
      final facultyCourses = ds.getFacultyCourses(facultyId);
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final dateStr = DateFormat('d MMM yyyy').format(now);
      final todayTimetable = ds.getTimetableForDay(dayName);
      final notifications = ds.notifications;

      // Mentor & Adviser data
      final mentees = ds.getMentees(facultyId);
      final isAdviser = ds.isFacultyClassAdviser(facultyId);
      final adviserClass = isAdviser ? ds.getAdviserClass(facultyId) : null;

      String facultyName = 'Faculty';
      final fac = ds.getFacultyById(facultyId);
      if (fac != null) {
        facultyName = fac['name'] as String? ?? 'Faculty';
      } else if (facultyCourses.isNotEmpty) {
        facultyName = facultyCourses.first['facultyName'] as String? ?? 'Faculty';
      }
      final initials = facultyName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildWelcomeHeader(isMobile, facultyName, initials, dayName, dateStr),
              const SizedBox(height: 24),
              _buildFeatureBanner(isMobile, context),
              const SizedBox(height: 20),
              _buildStats(isMobile, facultyCourses, todayTimetable, mentees, notifications, context),
              const SizedBox(height: 28),
              // Mentor & Adviser Summary
              if (mentees.isNotEmpty || isAdviser) ...[
                _buildRoleSummary(isMobile, mentees, isAdviser, adviserClass, ds, context),
                const SizedBox(height: 28),
              ],
              if (isMobile) ...[
                _buildTodaySchedule(isMobile, todayTimetable, dayName),
                const SizedBox(height: 20),
                _buildMyCourses(facultyCourses, isMobile, context),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildTodaySchedule(isMobile, todayTimetable, dayName)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildMyCourses(facultyCourses, isMobile, context)),
                ]),
              const SizedBox(height: 28),
              _buildNotifications(notifications),
              const SizedBox(height: 16),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildWelcomeHeader(bool isMobile, String name, String initials, String dayName, String dateStr) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(right: -15, top: -15, child: Container(width: 80, height: 80, decoration: BoxDecoration(
            shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03),
          ))),
          isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                    ),
                    child: CircleAvatar(radius: 22, backgroundColor: const Color(0xFF10B981),
                      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting,', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  ])),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _pill('Faculty'),
                  const Spacer(),
                  Text('$dayName, $dateStr', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                ]),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                  ),
                  child: CircleAvatar(radius: 30, backgroundColor: const Color(0xFF10B981),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 22),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$greeting,', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  _pill('Faculty  •  KSRCE'),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: const Text('2025-26', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Text('$dayName, $dateStr', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
              ]),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11, fontWeight: FontWeight.w500)),
  );

  Widget _buildFeatureBanner(bool isMobile, BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final hasPattern = ds.anyQuestionPaperPatternSaved();
      final hasCOPO = ds.hasCourseOutcomes();
      final actions = [
      _BannerAction('AI-Assisted Grading', Icons.verified_rounded, '/faculty/grades', const Color(0xFF2563EB)),
      _BannerAction('Course Material Generator', Icons.auto_awesome_rounded, '/faculty/generator', const Color(0xFFF97316)),
      _BannerAction('CO/PO Setup', Icons.fact_check_rounded, '/faculty/course-details', const Color(0xFF10B981)),
    ];

      return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B).withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1E40AF), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('New Faculty Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                const _PillBadge(label: 'New', color: Color(0xFFF97316)),
              ]),
              const SizedBox(height: 8),
              Text('Use the new internal-mark grid, paper-pattern setup, and CO/PO controls from here.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: actions.map((a) => _featureChip(context, a)).toList()),
            ])
          : Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1E40AF), size: 22),
              ),
              const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('New Faculty Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(width: 10),
                  _StatusBadge(label: hasPattern ? 'IA Pattern: Configured' : 'IA Pattern: Not configured', color: hasPattern ? Color(0xFF10B981) : Color(0xFFF97316)),
                  const SizedBox(width: 8),
                  _StatusBadge(label: hasCOPO ? 'CO/PO: Available' : 'CO/PO: Missing', color: hasCOPO ? Color(0xFF10B981) : Color(0xFFF97316)),
                ]),
                const SizedBox(height: 4),
                Text('Internal IA grid, paper pattern setup, and CO/PO tools are now available for this role.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              ])),
              const SizedBox(width: 12),
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: actions.map((a) => _featureChip(context, a)).toList()),
            ]),
    );
    });
  }

  Widget _featureChip(BuildContext context, _BannerAction action) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [action.tone.withValues(alpha: 0.12), action.tone.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: action.tone.withValues(alpha: 0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(action.icon, size: 14, color: action.tone),
          const SizedBox(width: 6),
          Text(action.label, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildStats(bool isMobile, List<Map<String, dynamic>> courses, List<Map<String, dynamic>> todaySchedule, List<Map<String, dynamic>> mentees, List<Map<String, dynamic>> notifs, BuildContext context) {
    final stats = [
      _S('Mentees', '${mentees.length}', Icons.people_rounded, const Color(0xFF3B82F6), '/faculty/mentees'),
      _S('Courses', '${courses.length}', Icons.menu_book_rounded, const Color(0xFF10B981), '/faculty/courses'),
      _S('Today', '${todaySchedule.length}', Icons.today_rounded, const Color(0xFFF97316), '/faculty/timetable'),
      _S('Alerts', '${notifs.length}', Icons.notifications_rounded, const Color(0xFF8B5CF6), '/faculty/notifications'),
    ];
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.35,
        children: stats.map((s) => _statCard(s, context)).toList(),
      );
    }
    return Row(children: stats.asMap().entries.map((e) => Expanded(
      child: Padding(padding: EdgeInsets.only(left: e.key > 0 ? 14 : 0), child: _statCard(e.value, context)),
    )).toList());
  }

  Widget _statCard(_S s, BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(s.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppCardStyles.statCard(s.color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: s.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(s.value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.1, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(s.label, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildRoleSummary(bool isMobile, List<Map<String, dynamic>> mentees, bool isAdviser, Map<String, dynamic>? adviserClass, DataService ds, BuildContext context) {
    if (isMobile) {
      return Column(children: [
        if (mentees.isNotEmpty) _mentorCard(mentees, context),
        if (mentees.isNotEmpty && isAdviser) const SizedBox(height: 14),
        if (isAdviser) _adviserCard(adviserClass, ds, context),
      ]);
    }
    return Row(children: [
      if (mentees.isNotEmpty) Expanded(child: _mentorCard(mentees, context)),
      if (mentees.isNotEmpty && isAdviser) const SizedBox(width: 14),
      if (isAdviser) Expanded(child: _adviserCard(adviserClass, ds, context)),
    ]);
  }

  Widget _mentorCard(List<Map<String, dynamic>> mentees, BuildContext context) {
    final topMentees = mentees.take(3).toList();
    return GestureDetector(
      onTap: () => context.go('/faculty/mentees'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.group_rounded, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('My Mentees', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text('${mentees.length}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          ...topMentees.map((m) {
            final name = m['name'] as String? ?? 'Student';
            final init = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                CircleAvatar(radius: 13, backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                  child: Text(init, style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                Text('CGPA: ${m['cgpa'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ]),
            );
          }),
          if (mentees.length > 3) ...[
            const SizedBox(height: 4),
            Text('+ ${mentees.length - 3} more...', style: TextStyle(color: const Color(0xFF10B981).withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('View All', style: TextStyle(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF10B981)),
          ]),
        ]),
      ),
    );
  }

  Widget _adviserCard(Map<String, dynamic>? adviserClass, DataService ds, BuildContext context) {
    final deptId = adviserClass?['departmentId'] as String? ?? '';
    final year = adviserClass?['year']?.toString() ?? '-';
    final section = adviserClass?['section'] as String? ?? '-';
    final deptName = ds.getDepartmentName(deptId);
    final studentIds = (adviserClass?['studentIds'] as List<dynamic>?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () => context.go('/faculty/adviser'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Class Adviser', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Text('Active', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.business_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(deptName.isNotEmpty ? deptName : deptId, style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.class_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('Year $year  •  Section $section', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.people_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('${studentIds.length} Students', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('View Class', style: TextStyle(color: const Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF7C3AED)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTodaySchedule(bool isMobile, List<Map<String, dynamic>> schedule, String dayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: "Today's Schedule",
          icon: Icons.calendar_today_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
            child: Text(dayName, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
        if (schedule.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Column(children: [
              Icon(Icons.event_available_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              const Text('No classes today', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
            ])),
          )
        else
          ...schedule.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6), const Color(0xFFF97316), const Color(0xFFF43F5E)];
            final c = colors[i % colors.length];
            final course = s['courseName'] as String? ?? '';
            final code = s['courseCode'] as String? ?? '';
            final room = s['room'] as String? ?? '';
            final type = s['type'] as String? ?? 'Lecture';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: AppCardStyles.accentLeft(c),
                child: Row(children: [
                  SizedBox(width: isMobile ? 70 : 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['startTime'] as String? ?? '', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(s['endTime'] as String? ?? '', style: TextStyle(color: c.withValues(alpha: 0.7), fontSize: 11)),
                  ])),
                  const SizedBox(width: 8),
                  Container(width: 1.5, height: 36, decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(course, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('$code  •  $room', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(type, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            );
          }),
      ]),
    );
  }

  Widget _buildMyCourses(List<Map<String, dynamic>> courses, bool isMobile, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'My Courses', icon: Icons.menu_book_rounded),
        if (courses.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [
            Icon(Icons.book_outlined, size: 36, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text('No courses assigned', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ])))
        else
          ...courses.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final code = c['courseCode'] as String? ?? '';
            final name = c['courseName'] as String? ?? '';
            final credits = c['credits']?.toString() ?? '0';
            final room = c['room'] as String? ?? '';
            final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6), const Color(0xFFF97316)];
            final color = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => context.go('/faculty/course-details'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.1)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(code, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('$credits Cr  •  $room', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                  ]),
                ),
              ),
            );
          }),
      ]),
    );
  }

  Widget _buildNotifications(List<Map<String, dynamic>> notifications) {
    final recent = notifications.take(4).toList();
    final Map<String, IconData> typeIcons = {
      'assignment': Icons.assignment_rounded, 'exam': Icons.event_note_rounded,
      'attendance': Icons.fact_check_rounded, 'event': Icons.celebration_rounded,
      'alert': Icons.warning_amber_rounded,
    };
    final Map<String, Color> typeColors = {
      'assignment': const Color(0xFF3B82F6), 'exam': const Color(0xFFF97316),
      'attendance': const Color(0xFFF43F5E), 'event': const Color(0xFF10B981),
      'alert': const Color(0xFFEAB308),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recent Notifications', icon: Icons.notifications_rounded),
        if (recent.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Column(children: [
            Icon(Icons.notifications_off_rounded, size: 36, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text('No notifications', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ])))
        else
          ...recent.map((n) {
            final type = (n['type'] as String?) ?? 'alert';
            final icon = typeIcons[type] ?? Icons.notifications_rounded;
            final color = typeColors[type] ?? AppColors.primary;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title'] as String? ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(n['message'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            );
          }),
      ]),
    );
  }
}

class _S {
  final String label, value, route;
  final IconData icon;
  final Color color;
  const _S(this.label, this.value, this.icon, this.color, this.route);
}

class _BannerAction {
  final String label;
  final IconData icon;
  final String route;
  final Color tone;
  const _BannerAction(this.label, this.icon, this.route, [this.tone = const Color(0xFF1E40AF)]);
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
