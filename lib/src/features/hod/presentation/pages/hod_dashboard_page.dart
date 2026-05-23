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
          final isMobile = constraints.maxWidth < 950;
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
              
              // 📊 Departmental Analytics Hub (NEW ADVANCED MODULE)
              const SectionHeader(title: 'Departmental Analytics Hub', icon: Icons.insights_rounded),
              if (isMobile) ...[
                const AcademicPerformanceChart(),
                const SizedBox(height: 16),
                const GrievanceResponseTimeChart(),
                const SizedBox(height: 16),
                const AttendanceHeatmapChart(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 3, child: AcademicPerformanceChart()),
                    SizedBox(width: 20),
                    Expanded(flex: 2, child: GrievanceResponseTimeChart()),
                  ],
                ),
                const SizedBox(height: 20),
                const AttendanceHeatmapChart(),
              ],
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
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _StatusBadge(label: hasPattern ? 'Pattern: Done' : 'Pattern: Pending', color: hasPattern ? Color(0xFF10B981) : Color(0xFFF97316)),
                  _StatusBadge(label: hasCOPO ? 'CO/PO: Seeded' : 'CO/PO: Missing', color: hasCOPO ? Color(0xFF10B981) : Color(0xFFF97316)),
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

// ── CUSTOM ACADEMIC CHART (SPLINE CURVE) ────────────────
class AcademicPerformanceChart extends StatelessWidget {
  const AcademicPerformanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [8.0, 22.0, 45.0, 30.0, 15.0];
    final labels = ['<6.0 GPA', '6.0–7.0', '7.0–8.0', '8.0–9.0', '>9.0 GPA'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Academic performance (GPA Curve)',
            icon: Icons.analytics,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _SplineAreaPainter(data: data, labels: labels),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map((l) => Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted))).toList(),
          ),
        ],
      ),
    );
  }
}

class _SplineAreaPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  _SplineAreaPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 20.0;
    final double width = size.width - (padding * 2);
    final double height = size.height - 20;

    final double maxVal = 50.0; 
    final int steps = data.length;
    final double stepWidth = width / (steps - 1);

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (height * i / 4);
      canvas.drawLine(Offset(padding, y), Offset(padding + width, y), gridPaint);
    }

    // Map points to canvas coordinates
    final List<Offset> points = [];
    for (int i = 0; i < steps; i++) {
      final x = padding + (i * stepWidth);
      final y = padding + height - (data[i] / maxVal * height);
      points.add(Offset(x, y));
    }

    // Draw spline area (gradient fill)
    final path = Path();
    path.moveTo(points.first.dx, padding + height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + stepWidth / 2, p0.dy);
      final controlPoint2 = Offset(p1.dx - stepWidth / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    path.lineTo(points.last.dx, padding + height);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTRB(padding, padding, padding + width, padding + height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Draw spline curve line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + stepWidth / 2, p0.dy);
      final controlPoint2 = Offset(p1.dx - stepWidth / 2, p1.dy);
      linePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    // Draw point dots and values
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      
      canvas.drawCircle(pt, 6, dotPaint);
      canvas.drawCircle(pt, 4, glowPaint);
      canvas.drawCircle(pt, 2.5, dotPaint);

      textPainter.text = TextSpan(
        text: '${data[i].toInt()} std',
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CUSTOM ATTENDANCE HEATMAP ──────────────────────────
class AttendanceHeatmapChart extends StatelessWidget {
  const AttendanceHeatmapChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> years = ['CSE - Year I', 'CSE - Year II', 'CSE - Year III', 'CSE - Year IV'];
    final List<String> weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'];

    final Map<String, List<double>> attendanceData = {
      'CSE - Year I': [91.2, 88.5, 84.1, 79.8, 86.4, 90.0],
      'CSE - Year II': [89.0, 87.2, 81.5, 74.0, 78.5, 83.2],
      'CSE - Year III': [94.5, 92.0, 89.2, 85.5, 91.0, 93.4],
      'CSE - Year IV': [85.0, 82.4, 78.0, 71.5, 73.8, 80.5],
    };

    Color getHeatmapColor(double val) {
      if (val >= 85) return const Color(0xFF10B981); 
      if (val >= 75) return const Color(0xFFF59E0B); 
      return const Color(0xFFEF4444); 
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Section attendance heatmap',
            icon: Icons.grid_on,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(115),
              border: TableBorder.all(color: AppColors.border, width: 0.5),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    const TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                        child: Text('Class & Sec', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMedium)),
                      ),
                    ),
                    ...weeks.map((w) => TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMedium),
                        ),
                      ),
                    )),
                  ],
                ),
                ...years.map((y) {
                  final rowData = attendanceData[y]!;
                  return TableRow(
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            y,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                          ),
                        ),
                      ),
                      ...rowData.map((val) {
                        final cellColor = getHeatmapColor(val);
                        return TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: cellColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cellColor.withValues(alpha: 0.2), width: 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${val.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: cellColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  val >= 85 ? 'Excellent' : val >= 75 ? 'Caution' : 'Critical',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: cellColor.withValues(alpha: 0.8),
                                  ),
                                ),
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
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildHeatmapLegend('🟢 >=85% (Good)', const Color(0xFF10B981)),
              const SizedBox(width: 14),
              _buildHeatmapLegend('🟡 75%–85% (Warning)', const Color(0xFFF59E0B)),
              const SizedBox(width: 14),
              _buildHeatmapLegend('🔴 <75% (Shortage)', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ── CUSTOM GRIEVANCE & SUPPORT RESOLUTION CHART ──────────
class GrievanceResponseTimeChart extends StatelessWidget {
  const GrievanceResponseTimeChart({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': 'Academic Issues', 'resolved': 12, 'pending': 1},
      {'title': 'Facility/Labs', 'resolved': 8, 'pending': 2},
      {'title': 'Hostel/Mess', 'resolved': 15, 'pending': 0},
      {'title': 'General Admin', 'resolved': 5, 'pending': 1},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Grievance resolution rates',
            icon: Icons.feedback_outlined,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: AppCardStyles.tinted(AppColors.secondary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Resolved Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      SizedBox(height: 4),
                      Text('91.0%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: AppCardStyles.tinted(AppColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Avg Resolution', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      SizedBox(height: 4),
                      Text('1.8 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...categories.map((c) {
            final int res = c['resolved'] as int;
            final int pen = c['pending'] as int;
            final int total = res + pen;
            final double resPercent = total > 0 ? res / total : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textDark),
                      ),
                      Text(
                        '$res Resolved / $pen Pending',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: resPercent,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
