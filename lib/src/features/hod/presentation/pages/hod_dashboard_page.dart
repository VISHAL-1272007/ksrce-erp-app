import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class HodDashboardPage extends StatelessWidget {
  const HodDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));

      final fac = ds.currentFaculty ?? {};
      final name = fac['name'] as String? ?? 'HOD';
      final deptId = fac['departmentId'] as String? ?? '';
      final dept = ds.getHODDepartment(ds.currentUserId ?? '') ?? {};
      final deptName = dept['departmentName'] as String? ?? deptId;
      final deptCode = dept['departmentCode'] as String? ?? '';

      final deptFaculty = ds.getDepartmentFaculty(deptId);
      final deptStudents = ds.getDepartmentStudents(deptId);
      final deptClasses = ds.getDepartmentClasses(deptId);
      final deptCourses = ds.getDepartmentCourses(deptId);
      final mentorAssigns = ds.getDepartmentMentorAssignments(deptId);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Welcome header
              _buildWelcomeHeader(name, deptName, deptCode, isMobile),
              const SizedBox(height: 24),
              _buildFeatureBanner(isMobile, context),
              const SizedBox(height: 20),
              // Stats
              _buildStatsRow(isMobile, deptFaculty.length, deptStudents.length, deptClasses.length, deptCourses.length),
              const SizedBox(height: 28),
              // Classes overview
              _buildClassesSection(deptClasses, ds, isMobile),
              const SizedBox(height: 28),
              // Mentor assignments overview
              _buildMentorSection(mentorAssigns, isMobile),
              const SizedBox(height: 16),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildWelcomeHeader(String name, String deptName, String deptCode, bool isMobile) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A365D), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF1A365D)),
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)))),
        Positioned(right: 40, bottom: -30, child: Container(width: 60, height: 60, decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.02)))),
        isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2)),
                  child: CircleAvatar(radius: 22, backgroundColor: const Color(0xFF10B981),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$greeting,', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                ])),
              ]),
              const SizedBox(height: 14),
              _infoPill('HOD  •  $deptName ($deptCode)'),
            ])
          : Row(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2)),
                child: CircleAvatar(radius: 30, backgroundColor: const Color(0xFF10B981),
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 22),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$greeting,', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                _infoPill('Head of Department  •  $deptName ($deptCode)'),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                  child: const Text('2025-26', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                  const SizedBox(width: 5),
                  const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ]),
            ]),
      ]),
    );
  }

  Widget _infoPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
  );

  Widget _buildFeatureBanner(bool isMobile, BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final hasPattern = ds.anyQuestionPaperPatternSaved();
      final hasCOPO = ds.hasCourseOutcomes();
      final actions = [
        _BannerAction('CO/PO Setup', Icons.fact_check_rounded, '/hod/courses', const Color(0xFF10B981)),
        _BannerAction('Paper Pattern', Icons.description_outlined, '/hod/courses', const Color(0xFFF97316)),
        _BannerAction('Faculty Links', Icons.people_rounded, '/hod/faculty', const Color(0xFF3B82F6)),
      ];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFF7ED)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1A365D).withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: const Color(0xFF1A365D).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1A365D), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('HOD Control Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                  _StatusBadge(label: hasPattern ? 'Paper Pattern: Configured' : 'Paper Pattern: Not configured', color: hasPattern ? Color(0xFF10B981) : Color(0xFFF97316)),
                  const SizedBox(width: 8),
                  _StatusBadge(label: hasCOPO ? 'CO/PO: Available' : 'CO/PO: Missing', color: hasCOPO ? Color(0xFF10B981) : Color(0xFFF97316)),
                ]),
                const SizedBox(height: 8),
                const Text('Manage CO/PO setup, paper pattern, and faculty mapping from here.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: actions.map((a) => _featureChip(context, a)).toList()),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1A365D).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1A365D), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('HOD Control Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(width: 10),
                    _StatusBadge(label: hasPattern ? 'Paper Pattern: Configured' : 'Paper Pattern: Not configured', color: hasPattern ? Color(0xFF10B981) : Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    _StatusBadge(label: hasCOPO ? 'CO/PO: Available' : 'CO/PO: Missing', color: hasCOPO ? Color(0xFF10B981) : Color(0xFFF97316)),
                  ]),
                  const SizedBox(height: 4),
                  Text('CO/PO setup, paper-pattern setup, and faculty mapping are available here.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
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
          gradient: LinearGradient(colors: [action.tone.withValues(alpha: 0.14), action.tone.withValues(alpha: 0.06)]),
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

  Widget _buildStatsRow(bool isMobile, int facultyCount, int studentCount, int classCount, int courseCount) {
    final stats = [
      _HodStat('Faculty', '$facultyCount', Icons.people_rounded, const Color(0xFF3B82F6)),
      _HodStat('Students', '$studentCount', Icons.school_rounded, const Color(0xFF10B981)),
      _HodStat('Classes', '$classCount', Icons.class_rounded, const Color(0xFFF97316)),
      _HodStat('Courses', '$courseCount', Icons.menu_book_rounded, const Color(0xFF8B5CF6)),
    ];
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.35,
        children: stats.map((s) => _buildStatCard(s)).toList(),
      );
    }
    return Row(children: stats.asMap().entries.map((e) => Expanded(
      child: Padding(padding: EdgeInsets.only(left: e.key > 0 ? 14 : 0), child: _buildStatCard(e.value)),
    )).toList());
  }

  Widget _buildStatCard(_HodStat s) {
    return Container(
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
    );
  }

  Widget _buildClassesSection(List<Map<String, dynamic>> deptClasses, DataService ds, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Classes & Advisers', icon: Icons.class_rounded),
        if (deptClasses.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [
            Icon(Icons.class_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            const Text('No classes found', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
          ])))
        else
          ...deptClasses.map((c) {
            final adviserId = c['classAdviserId'] as String? ?? '';
            final adviserName = adviserId.isNotEmpty ? ds.getFacultyName(adviserId) : 'Not Assigned';
            final studentCount = (c['studentIds'] as List<dynamic>?)?.length ?? 0;
            final isAssigned = adviserId.isNotEmpty;
            final accentColor = isAssigned ? const Color(0xFF10B981) : const Color(0xFFF97316);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: AppCardStyles.accentLeft(accentColor),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.class_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Year ${c['year']} - Section ${c['section']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.person_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Adviser: $adviserName', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const SizedBox(width: 10),
                    Icon(Icons.people_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('$studentCount students', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                  child: Text(isAssigned ? 'Assigned' : 'Pending', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _buildMentorSection(List<Map<String, dynamic>> mentorAssigns, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Mentor Assignments', icon: Icons.supervisor_account_rounded),
        if (mentorAssigns.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [
            Icon(Icons.supervisor_account_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            const Text('No mentor assignments yet', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
          ])))
        else
          ...mentorAssigns.asMap().entries.map((entry) {
            final m = entry.value;
            final menteeCount = (m['menteeIds'] as List<dynamic>?)?.length ?? 0;
            final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF97316), const Color(0xFF8B5CF6), const Color(0xFFF43F5E)];
            final c = colors[entry.key % colors.length];
            final mentorName = m['mentorName'] as String? ?? '';
            final initials = mentorName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c.withValues(alpha: 0.15), c.withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(initials, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mentorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Year ${m['year']} Sec ${m['section']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const SizedBox(width: 10),
                    Icon(Icons.people_outline_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('$menteeCount mentees', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                  child: Text('$menteeCount', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

class _HodStat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _HodStat(this.label, this.value, this.icon, this.color);
}

class _BannerAction {
  final String label;
  final IconData icon;
  final String route;
  final Color tone;
  const _BannerAction(this.label, this.icon, this.route, [this.tone = const Color(0xFF1A365D)]);
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.18))),
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
