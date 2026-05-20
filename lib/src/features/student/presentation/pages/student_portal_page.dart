import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

/// Student Portal Home — inspired by KSR ERP's pinned-resources layout
/// but with a modern card-based design system.
class StudentPortalPage extends StatefulWidget {
  const StudentPortalPage({super.key});

  @override
  State<StudentPortalPage> createState() => _StudentPortalPageState();
}

class _StudentPortalPageState extends State<StudentPortalPage> {
  // Simulated recently-accessed tracking (order = last visited first)
  final List<_PortalLink> _recentlyAccessed = [];
  // Simulated pinned favourites
  final Set<String> _pinnedRoutes = {};

  // All available portal modules
  List<_PortalLink> get _allModules => [
    _PortalLink('My Courses', Icons.menu_book_rounded, '/student/courses', const Color(0xFF8B5CF6), 'View enrolled courses, credits & faculty'),
    _PortalLink('Timetable', Icons.schedule_rounded, '/student/timetable', const Color(0xFF3B82F6), 'Weekly class schedule & rooms'),
    _PortalLink('Attendance', Icons.fact_check_rounded, '/student/attendance', const Color(0xFF10B981), 'Track attendance percentage per course'),
    _PortalLink('Results', Icons.assessment_rounded, '/student/results', const Color(0xFFF43F5E), 'Exam results, grades & GPA'),
    _PortalLink('Assignments', Icons.assignment_rounded, '/student/assignments', const Color(0xFFF97316), 'Pending & submitted assignments'),
    _PortalLink('Exam Schedule', Icons.event_note_rounded, '/student/exams', const Color(0xFFEF4444), 'Upcoming exams & hall tickets'),
    _PortalLink('Fee Details', Icons.payment_rounded, '/student/fees', const Color(0xFF06B6D4), 'Fee structure, payments & dues'),
    _PortalLink('Library', Icons.local_library_rounded, '/student/library', const Color(0xFF059669), 'Browse books, due dates & e-resources'),
    _PortalLink('Notifications', Icons.notifications_rounded, '/student/notifications', const Color(0xFFEAB308), 'Announcements & alerts'),
    _PortalLink('Complaints', Icons.report_problem_rounded, '/student/complaints', const Color(0xFFDC2626), 'Raise & track grievances'),
    _PortalLink('Leave Apply', Icons.event_busy_rounded, '/student/leave', const Color(0xFF7C3AED), 'Apply for leave & check balance'),
    _PortalLink('Certificates', Icons.card_membership_rounded, '/student/certificates', const Color(0xFF0891B2), 'Request & download certificates'),
    _PortalLink('Placements', Icons.work_rounded, '/student/placements', const Color(0xFF2563EB), 'Placement drives & applications'),
    _PortalLink('Events', Icons.celebration_rounded, '/student/events', const Color(0xFFD946EF), 'College events & registrations'),
    _PortalLink('Syllabus', Icons.description_rounded, '/student/syllabus', const Color(0xFF4F46E5), 'Course syllabus & learning outcomes'),
    _PortalLink('Profile', Icons.person_rounded, '/student/profile', const Color(0xFF64748B), 'Personal info, photo & documents'),
    _PortalLink('Files', Icons.cloud_upload_rounded, '/student/files', const Color(0xFF0D9488), 'Uploaded documents & files'),
    _PortalLink('Settings', Icons.settings_rounded, '/student/settings', const Color(0xFF475569), 'App preferences & account'),
  ];

  // Frequently used – sorted by simulated usage count
  List<_PortalLink> get _frequentlyUsed {
    // Top 6 most common student actions
    final topRoutes = ['/student/attendance', '/student/results', '/student/timetable',
                       '/student/assignments', '/student/courses', '/student/notifications'];
    return _allModules.where((m) => topRoutes.contains(m.route)).toList();
  }

  void _navigateAndTrack(BuildContext context, _PortalLink link) {
    setState(() {
      _recentlyAccessed.removeWhere((l) => l.route == link.route);
      _recentlyAccessed.insert(0, link);
      if (_recentlyAccessed.length > 8) _recentlyAccessed.removeLast();
    });
    context.go(link.route);
  }

  void _togglePin(String route) {
    setState(() {
      if (_pinnedRoutes.contains(route)) {
        _pinnedRoutes.remove(route);
      } else {
        _pinnedRoutes.add(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final student = ds.currentStudent ?? {};
      final name = (student['name'] as String?) ?? 'Student';
      final dept = (student['department'] as String?) ?? 'Computer Science';
      final year = (student['year'] as String?) ?? '3';
      final section = (student['section'] as String?) ?? 'A';
      final rollNo = (student['studentId'] as String?) ?? ds.currentUserId ?? '';
      final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final dateStr = DateFormat('d MMMM yyyy').format(now);
      final todayPeriods = ds.getTimetableForDay(dayName);
      final mentor = ds.getStudentMentor(rollNo);
      final unreadCount = ds.unreadNotificationCount;
      final pendingAssignments = ds.pendingAssignmentsCount;
      final notifications = ds.notifications;
      final upcomingEvents = ds.events.take(3).toList();
      final pinnedModules = _allModules.where((m) => _pinnedRoutes.contains(m.route)).toList();

      // Day order mapping (Mon=1, Tue=2, ...)
      final dayOrders = {'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
                         'Thursday': 4, 'Friday': 5, 'Saturday': 6};
      final dayOrder = dayOrders[dayName] ?? 1;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;
          final isTablet = constraints.maxWidth < 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 14 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── BREADCRUMB ───
                _buildBreadcrumb(context),
                const SizedBox(height: 16),

                // ─── DAY ORDER + NOTICE BOARD BANNERS ───
                _buildDayOrderBanner(dayName, dayOrder, dateStr),
                const SizedBox(height: 12),
                _buildNoticeBoard(notifications, unreadCount, context),
                const SizedBox(height: 20),

                // ─── PROFILE STRIP + QUICK STATS ───
                _buildProfileStrip(isMobile, name, initials, dept, year, section, rollNo, mentor),
                const SizedBox(height: 20),

                // ─── TODAY'S SCHEDULE PEEK ───
                _buildTodaySchedulePeek(isMobile, todayPeriods, dayName, context),
                const SizedBox(height: 24),

                // ─── THREE-COLUMN: RECENTLY ACCESSED | FREQUENTLY ACCESSED | PINNED ───
                if (isMobile) ...[
                  _buildRecentlyAccessedSection(context),
                  const SizedBox(height: 16),
                  _buildFrequentlyAccessedSection(context),
                  const SizedBox(height: 16),
                  _buildPinnedFavouritesSection(pinnedModules, context),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentlyAccessedSection(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFrequentlyAccessedSection(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPinnedFavouritesSection(pinnedModules, context)),
                    ],
                  ),
                const SizedBox(height: 24),

                // ─── ALL MODULES GRID ───
                _buildAllModulesGrid(isMobile, isTablet, context),
                const SizedBox(height: 24),

                // ─── QUICK INFO FOOTER: UPCOMING EVENTS + PENDING TASKS + MENTOR ───
                if (isMobile) ...[
                  _buildUpcomingEventsCard(upcomingEvents, context),
                  const SizedBox(height: 16),
                  _buildPendingTasksCard(pendingAssignments, unreadCount, context),
                  const SizedBox(height: 16),
                  if (mentor != null) _buildMentorCard(mentor),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildUpcomingEventsCard(upcomingEvents, context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPendingTasksCard(pendingAssignments, unreadCount, context)),
                      if (mentor != null) ...[
                        const SizedBox(width: 16),
                        Expanded(child: _buildMentorCard(mentor)),
                      ],
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }),
      );
    });
  }

  // ─────────────────────────────────────────────────────────
  // BREADCRUMB
  // ─────────────────────────────────────────────────────────
  Widget _buildBreadcrumb(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/student/dashboard'),
          borderRadius: BorderRadius.circular(4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.home_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text('Home', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.5)),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.apps_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          const Text('Student Portal', style: TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // DAY ORDER BANNER
  // ─────────────────────────────────────────────────────────
  Widget _buildDayOrderBanner(String dayName, int dayOrder, String dateStr) {
    return GestureDetector(
      onTap: () => context.go('/student/timetable'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Today's Day Order: $dayName",
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w400)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text('Day $dayOrder', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // NOTICE BOARD BANNER
  // ─────────────────────────────────────────────────────────
  Widget _buildNoticeBoard(List<Map<String, dynamic>> notifications, int unreadCount, BuildContext context) {
    // Latest unread notification as the "notice"
    final latest = notifications.isNotEmpty ? notifications.first : null;
    final message = (latest?['title'] as String?) ?? 'No new notices at this time.';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: () => context.go('/student/notifications'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppCardStyles.coloredShadow(const Color(0xFFF43F5E)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Notice Board', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (unreadCount > 0) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$unreadCount new', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(message, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PROFILE INFO STRIP
  // ─────────────────────────────────────────────────────────
  Widget _buildProfileStrip(bool isMobile, String name, String initials, String dept, String year, String section, String rollNo, Map<String, dynamic>? mentor) {
    return GestureDetector(
      onTap: () => context.go('/student/profile'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: isMobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _profileAvatar(initials, 20),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(rollNo, style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
              ])),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _chipTag(dept, Icons.business_rounded, AppColors.primary),
              _chipTag('Year $year', Icons.school_rounded, const Color(0xFF10B981)),
              _chipTag('Section $section', Icons.group_rounded, const Color(0xFF8B5CF6)),
              if (mentor != null) _chipTag('Mentor: ${mentor['name'] ?? ''}', Icons.person_pin_rounded, const Color(0xFFF97316)),
            ]),
          ])
        : Row(children: [
            _profileAvatar(initials, 24),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _chipTag(rollNo, Icons.badge_rounded, AppColors.textMedium),
                _chipTag(dept, Icons.business_rounded, AppColors.primary),
                _chipTag('Year $year  •  Sec $section', Icons.school_rounded, const Color(0xFF10B981)),
                if (mentor != null) _chipTag('Mentor: ${mentor['name'] ?? ''}', Icons.person_pin_rounded, const Color(0xFFF97316)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20)),
                child: const Text('2025–26', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                const SizedBox(width: 5),
                const Text('Active', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ]),
      ),
      ),
    );
  }

  Widget _profileAvatar(String initials, double radius) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: CircleAvatar(radius: radius, backgroundColor: AppColors.primary,
        child: Text(initials, style: TextStyle(color: Colors.white, fontSize: radius * 0.75, fontWeight: FontWeight.w700))),
    );
  }

  Widget _chipTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TODAY'S SCHEDULE PEEK (compact horizontal)
  // ─────────────────────────────────────────────────────────
  Widget _buildTodaySchedulePeek(bool isMobile, List<Map<String, dynamic>> periods, String dayName, BuildContext context) {
    final periodColors = [
      const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6),
      const Color(0xFFF97316), const Color(0xFFF43F5E), const Color(0xFF06B6D4),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.raised,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.view_timeline_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text("Today's Classes", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          GestureDetector(
            onTap: () => context.go('/student/timetable'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Full Timetable', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary.withValues(alpha: 0.7)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        if (periods.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Column(children: [
              Icon(Icons.beach_access_rounded, size: 32, color: AppColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              const Text('No classes today', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            ])),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: periods.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final c = periodColors[i % periodColors.length];
                return GestureDetector(
                  onTap: () => context.go('/student/timetable'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                  width: isMobile ? 140 : 160,
                  margin: EdgeInsets.only(right: i < periods.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withValues(alpha: 0.12)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('${p['startTime'] ?? ''}', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Text(p['room'] as String? ?? '', style: TextStyle(color: c.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 8),
                    Text(p['courseCode'] as String? ?? '', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(p['courseName'] as String? ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                  ),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // RECENTLY ACCESSED
  // ─────────────────────────────────────────────────────────
  Widget _buildRecentlyAccessedSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Recently Accessed', Icons.history_rounded, const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        if (_recentlyAccessed.isEmpty)
          _emptyState('Navigate to any module to see it here', Icons.touch_app_rounded)
        else
          ...(_recentlyAccessed.take(5).map((link) => _linkTile(link, context, showPin: true))),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FREQUENTLY ACCESSED
  // ─────────────────────────────────────────────────────────
  Widget _buildFrequentlyAccessedSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Frequently Accessed', Icons.star_rounded, const Color(0xFFF97316)),
        const SizedBox(height: 12),
        ..._frequentlyUsed.map((link) => _linkTile(link, context, showPin: true)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PINNED FAVOURITES
  // ─────────────────────────────────────────────────────────
  Widget _buildPinnedFavouritesSection(List<_PortalLink> pinnedModules, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Pinned Favourites', Icons.push_pin_rounded, const Color(0xFF10B981)),
        const SizedBox(height: 12),
        if (pinnedModules.isEmpty)
          _emptyState('Click the pin icon on any module to add favourites', Icons.push_pin_outlined)
        else
          ...pinnedModules.map((link) => _linkTile(link, context, showPin: true, isPinned: true)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // ALL MODULES GRID
  // ─────────────────────────────────────────────────────────
  Widget _buildAllModulesGrid(bool isMobile, bool isTablet, BuildContext context) {
    final crossAxis = isMobile ? 2 : isTablet ? 3 : 4;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.raised,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('All Modules', Icons.apps_rounded, AppColors.primary),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossAxis,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isMobile ? 1.3 : 1.5,
          children: _allModules.map((m) => _ModuleCard(
            link: m,
            isPinned: _pinnedRoutes.contains(m.route),
            onTap: () => _navigateAndTrack(context, m),
            onPin: () => _togglePin(m.route),
          )).toList(),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // UPCOMING EVENTS
  // ─────────────────────────────────────────────────────────
  Widget _buildUpcomingEventsCard(List<Map<String, dynamic>> events, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _sectionIcon(Icons.event_rounded, const Color(0xFFD946EF)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Upcoming Events', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          GestureDetector(
            onTap: () => context.go('/student/events'),
            child: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 14),
        if (events.isEmpty)
          _emptyState('No upcoming events', Icons.event_busy_rounded)
        else
          ...events.map((e) {
            final eventDate = e['date'] as String? ?? '';
            return GestureDetector(
              onTap: () => context.go('/student/events'),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD946EF).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD946EF).withValues(alpha: 0.08)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD946EF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_extractDay(eventDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFD946EF))),
                        Text(_extractMonth(eventDate), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD946EF))),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e['title'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(e['type'] as String? ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFD946EF)),
                  ]),
                ),
              ),
            );
          }),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PENDING TASKS CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildPendingTasksCard(int pendingAssignments, int unreadNotifs, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _sectionIcon(Icons.checklist_rounded, const Color(0xFFF97316)),
          const SizedBox(width: 10),
          const Text('Pending Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 14),
        _taskRow('Assignments Due', '$pendingAssignments', Icons.assignment_late_rounded, const Color(0xFFF97316), () => context.go('/student/assignments')),
        const SizedBox(height: 8),
        _taskRow('Unread Alerts', '$unreadNotifs', Icons.notifications_active_rounded, const Color(0xFFF43F5E), () => context.go('/student/notifications')),
      ]),
    );
  }

  Widget _taskRow(String label, String count, IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MENTOR INFO CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    final mentorName = mentor['name'] as String? ?? 'N/A';
    final mentorDept = mentor['department'] as String? ?? '';
    final mentorInit = mentorName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _sectionIcon(Icons.person_pin_rounded, const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          const Text('Your Mentor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
            child: Text(mentorInit, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w700, fontSize: 14))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mentorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(mentorDept, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ])),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.go('/student/profile'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.1)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.email_rounded, size: 14, color: Color(0xFF7C3AED)),
                SizedBox(width: 6),
                Text('Contact Mentor', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      _sectionIcon(icon, color),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const Spacer(),
      Icon(Icons.help_outline_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.5)),
    ]);
  }

  Widget _sectionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 28, color: AppColors.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppColors.textLight, fontSize: 12), textAlign: TextAlign.center),
      ])),
    );
  }

  Widget _linkTile(_PortalLink link, BuildContext context, {bool showPin = false, bool isPinned = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _navigateAndTrack(context, link),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: link.color.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: link.color.withValues(alpha: 0.06)),
          ),
          child: Row(children: [
            Icon(link.icon, size: 18, color: link.color),
            const SizedBox(width: 10),
            Expanded(child: Text(link.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
            if (showPin)
              GestureDetector(
                onTap: () => _togglePin(link.route),
                child: Icon(
                  _pinnedRoutes.contains(link.route) ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 15,
                  color: _pinnedRoutes.contains(link.route) ? const Color(0xFF10B981) : AppColors.textMuted.withValues(alpha: 0.4),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.4)),
          ]),
        ),
      ),
    );
  }

  String _extractDay(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}';
    } catch (_) {
      return '';
    }
  }

  String _extractMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────
class _PortalLink {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final String description;
  const _PortalLink(this.label, this.icon, this.route, this.color, this.description);
}

// ─────────────────────────────────────────────────────────
// MODULE CARD WIDGET
// ─────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final _PortalLink link;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onPin;
  const _ModuleCard({required this.link, required this.isPinned, required this.onTap, required this.onPin});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? link.color.withValues(alpha: 0.08) : link.color.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? link.color.withValues(alpha: 0.25) : link.color.withValues(alpha: 0.08),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered ? [BoxShadow(color: link.color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: link.color.withValues(alpha: _hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(link.icon, size: 20, color: link.color),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onPin,
                  child: Icon(
                    widget.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 14,
                    color: widget.isPinned ? const Color(0xFF10B981) : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(link.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _hovered ? link.color : AppColors.textDark,
                )),
                const SizedBox(height: 2),
                Text(link.description, style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
