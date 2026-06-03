import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

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
      final dept = (student['department'] as String?) ?? '';
      final year = (student['year'] as String?) ?? '';
      final section = (student['section'] as String?) ?? '';
      final cgpa = ds.currentCGPA;
      final attPct = ds.overallAttendancePercentage;
      final pendingCount = ds.pendingAssignmentsCount;
      final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final dateStr = DateFormat('d MMM yyyy').format(now);
      final todayTimetable = ds.getTimetableForDay(dayName);
      final unreadCount = ds.unreadNotificationCount;
      final notifications = ds.notifications;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          final studentId = student['studentId'] as String? ?? ds.currentUserId ?? '';
          final mentor = ds.getStudentMentor(studentId);
          final classAdviser = ds.getStudentClassAdviser(studentId);
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(isMobile, name, initials, dept, year, section, studentId, dayName, dateStr),
                const SizedBox(height: 24),
                _buildStatsRow(isMobile, attPct, cgpa, pendingCount, unreadCount, context),
                const SizedBox(height: 28),
                // Mentor & Class Adviser info
                if (mentor != null || classAdviser != null) ...[
                  _buildMentorAdviserRow(isMobile, mentor, classAdviser),
                  const SizedBox(height: 28),
                ],
                if (isMobile) ...[
                  _buildTodayTimetable(isMobile, todayTimetable, dayName),
                  const SizedBox(height: 20),
                  _buildRecentNotifications(notifications),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildTodayTimetable(isMobile, todayTimetable, dayName)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildRecentNotifications(notifications)),
                    ],
                  ),
                const SizedBox(height: 28),
                _buildQuickActions(context),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildWelcomeHeader(bool isMobile, String name, String initials, String dept, String year, String section, String rollNo, String dayName, String dateStr) {
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF1E3A5F)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(
            shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03),
          ))),
          Positioned(right: 40, bottom: -30, child: Container(width: 60, height: 60, decoration: BoxDecoration(
            shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.02),
          ))),
          isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                    ),
                    child: CircleAvatar(radius: 22, backgroundColor: const Color(0xFF3B82F6),
                      child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting,', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w400)),
                    const SizedBox(height: 2),
                    Text(firstName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                  ])),
                ]),
                const SizedBox(height: 16),
                _infoPill('$dept  •  Year $year  •  Sec $section'),
                const SizedBox(height: 8),
                Row(children: [
                  _infoPill(rollNo),
                  const Spacer(),
                  Text('$dayName, $dateStr', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                ]),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                  ),
                  child: CircleAvatar(radius: 30, backgroundColor: const Color(0xFF3B82F6),
                    child: Text(initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(width: 22),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$greeting,', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w400)),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _infoPill('$dept  •  Year $year  •  Sec $section'),
                    const SizedBox(width: 8),
                    _infoPill(rollNo),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
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

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatsRow(bool isMobile, double attPct, double cgpa, int pendingCount, int unreadCount, BuildContext context) {
    final stats = [
      _StatItem('Attendance', '${attPct.toStringAsFixed(0)}%', Icons.check_circle_outline_rounded, const Color(0xFF10B981), attPct >= 75 ? 'On Track' : 'Low', '/student/attendance'),
      _StatItem('CGPA', cgpa.toStringAsFixed(1), Icons.school_rounded, const Color(0xFF3B82F6), 'Overall', '/student/results'),
      _StatItem('Pending', '$pendingCount', Icons.assignment_late_rounded, const Color(0xFFF97316), pendingCount == 0 ? 'All Clear' : 'Due', '/student/assignments'),
      _StatItem('Alerts', '$unreadCount', Icons.notifications_rounded, const Color(0xFFF43F5E), unreadCount > 0 ? 'New' : 'None', '/student/notifications'),
    ];
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.35,
        children: stats.map((s) => _buildStatCard(s, context)).toList(),
      );
    }
    return Row(
      children: stats.asMap().entries.map((e) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: e.key > 0 ? 14 : 0),
          child: _buildStatCard(e.value, context),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatItem s, BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(s.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppCardStyles.statCard(s.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.icon, color: s.color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(s.badge, style: TextStyle(color: s.color, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.value, style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.1, letterSpacing: -0.5,
            )),
            const SizedBox(height: 2),
            Text(s.label, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorAdviserRow(bool isMobile, Map<String, dynamic>? mentor, Map<String, dynamic>? classAdviser) {
    if (isMobile) {
      return Column(children: [
        if (mentor != null) _mentorCard(mentor),
        if (mentor != null && classAdviser != null) const SizedBox(height: 12),
        if (classAdviser != null) _adviserCard(classAdviser),
      ]);
    }
    return Row(children: [
      if (mentor != null) Expanded(child: _mentorCard(mentor)),
      if (mentor != null && classAdviser != null) const SizedBox(width: 14),
      if (classAdviser != null) Expanded(child: _adviserCard(classAdviser)),
    ]);
  }

  Widget _mentorCard(Map<String, dynamic> mentor) {
    final name = mentor['name'] as String? ?? 'Mentor';
    final deptName = mentor['department'] as String? ?? mentor['departmentId'] as String? ?? '';
    final phone = mentor['phone'] as String? ?? '';
    final email = mentor['email'] as String? ?? '';
    final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2), width: 2),
          ),
          child: CircleAvatar(radius: 20, backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
            child: Text(initials, style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: const Text('MENTOR', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
          if (deptName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(deptName, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ],
          if (phone.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (phone.isNotEmpty) ...[
                const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(phone, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ],
              if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(width: 10),
              if (email.isNotEmpty)
                Expanded(child: Row(children: [
                  const Icon(Icons.email_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(child: Text(email, style: const TextStyle(color: AppColors.textLight, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ])),
            ]),
          ],
        ])),
      ]),
    );
  }

  Widget _adviserCard(Map<String, dynamic> adviser) {
    final name = adviser['name'] as String? ?? 'Class Adviser';
    final deptName = adviser['department'] as String? ?? adviser['departmentId'] as String? ?? '';
    final phone = adviser['phone'] as String? ?? '';
    final email = adviser['email'] as String? ?? '';
    final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2), width: 2),
          ),
          child: CircleAvatar(radius: 20, backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            child: Text(initials, style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 14, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: const Text('CLASS ADVISER', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
          if (deptName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(deptName, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ],
          if (phone.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (phone.isNotEmpty) ...[
                const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(phone, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ],
              if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(width: 10),
              if (email.isNotEmpty)
                Expanded(child: Row(children: [
                  const Icon(Icons.email_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(child: Text(email, style: const TextStyle(color: AppColors.textLight, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ])),
            ]),
          ],
        ])),
      ]),
    );
  }

  Widget _buildTodayTimetable(bool isMobile, List<Map<String, dynamic>> todayPeriods, String dayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: "Today's Schedule",
          icon: Icons.calendar_today_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(dayName, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
        if (todayPeriods.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Column(children: [
              Icon(Icons.event_available_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              const Text('No classes scheduled', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Enjoy your free day!', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
          )
        else
          ...todayPeriods.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final timeStr = '${p['startTime'] ?? ''} – ${p['endTime'] ?? ''}';
            final subject = p['courseName'] as String? ?? '';
            final code = p['courseCode'] as String? ?? '';
            final room = (p['room'] as String?) ?? '';
            final faculty = (p['facultyName'] as String?) ?? '';
            final colors = [
              const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6),
              const Color(0xFFF97316), const Color(0xFFF43F5E), const Color(0xFF06B6D4),
            ];
            final c = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: AppCardStyles.accentLeft(c),
                child: isMobile
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.access_time_rounded, size: 13, color: c),
                        const SizedBox(width: 5),
                        Text(timeStr, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (room.isNotEmpty) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                          child: Text(room, style: const TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(subject, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('$code  •  $faculty', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ])
                  : Row(children: [
                      Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p['startTime'] as String? ?? '', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(p['endTime'] as String? ?? '', style: TextStyle(color: c.withValues(alpha: 0.5), fontSize: 11)),
                        ]),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 1.5, height: 36, decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(1))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(subject, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('$code  •  $faculty', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ])),
                      if (room.isNotEmpty) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.room_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(room, style: const TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ]),
              ),
            );
          }),
      ]),
    );
  }

  Widget _buildRecentNotifications(List<Map<String, dynamic>> allNotifs) {
    final recent = allNotifs.take(5).toList();
    final Map<String, IconData> typeIcons = {
      'assignment': Icons.assignment_rounded, 'exam': Icons.event_note_rounded,
      'attendance': Icons.fact_check_rounded, 'event': Icons.celebration_rounded,
      'alert': Icons.warning_amber_rounded,
    };
    final Map<String, Color> typeColors = {
      'assignment': const Color(0xFFF97316), 'exam': const Color(0xFFF43F5E),
      'attendance': const Color(0xFF10B981), 'event': const Color(0xFF3B82F6),
      'alert': const Color(0xFFEAB308),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Notifications',
          icon: Icons.notifications_rounded,
          trailing: recent.isNotEmpty ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${allNotifs.where((n) => n['isRead'] == false).length} new',
              style: const TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w600)),
          ) : null,
        ),
        if (recent.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [
            Icon(Icons.notifications_off_rounded, size: 36, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text('All caught up!', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ])))
        else
          ...recent.map((n) {
            final type = (n['type'] as String?) ?? 'alert';
            final icon = typeIcons[type] ?? Icons.notifications_rounded;
            final color = typeColors[type] ?? AppColors.primary;
            final timeStr = _formatTime(n['timestamp'] as String?);
            final isUnread = n['isRead'] == false;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnread ? color.withValues(alpha: 0.03) : AppColors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: isUnread ? Border.all(color: color.withValues(alpha: 0.1)) : null,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title'] as String? ?? '', style: TextStyle(
                    color: AppColors.textDark, fontSize: 13,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                  )),
                  const SizedBox(height: 3),
                  Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ])),
                if (isUnread)
                  Container(width: 7, height: 7, decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                  )),
              ]),
            );
          }),
      ]),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem('AI Tutor', Icons.smart_toy_rounded, const Color(0xFF3B82F6), '/student/tutor'),
      _ActionItem('Smart Notes', Icons.edit_document, const Color(0xFF8B5CF6), '/student/notes'),
      _ActionItem('Workspace', Icons.group_work_rounded, const Color(0xFFF59E0B), '/student/workspace'),
      _ActionItem('Attendance', Icons.fact_check_rounded, const Color(0xFF10B981), '/student/attendance'),
      _ActionItem('Assignments', Icons.assignment_rounded, const Color(0xFFF97316), '/student/assignments'),
      _ActionItem('Exams', Icons.event_note_rounded, const Color(0xFFF43F5E), '/student/exams'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded),
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2,
          children: actions.map((a) => _QuickActionTile(action: a)).toList(),
        ),
      ]),
    );
  }
}

class _StatItem {
  final String label, value, badge, route;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color, this.badge, this.route);
}

class _ActionItem {
  final String label, route;
  final IconData icon;
  final Color color;
  const _ActionItem(this.label, this.icon, this.color, this.route);
}

class _QuickActionTile extends StatefulWidget {
  final _ActionItem action;
  const _QuickActionTile({required this.action});
  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(a.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? a.color.withValues(alpha: 0.1) : a.color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? a.color.withValues(alpha: 0.25) : a.color.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(a.icon, size: 18, color: a.color),
              const SizedBox(width: 8),
              Flexible(child: Text(a.label, style: TextStyle(
                color: _hovered ? a.color : AppColors.textDark,
                fontSize: 12, fontWeight: FontWeight.w600,
              ), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
