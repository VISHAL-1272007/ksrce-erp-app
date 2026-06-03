import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/data_service.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DataService>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Institutional Reports & Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time academic records, student safety attendance shortage lists, and grievance resolution indexes.',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 28),
            
            // Standard Overview Cards (legibility fix applied!)
            LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth > 800;
              final width = w ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ReportCard(
                    title: 'Student Enrollment',
                    icon: Icons.school,
                    count: '${ds.students.length}',
                    subtitle: 'Total registered students',
                    color: AppColors.primary,
                    width: width,
                  ),
                  _ReportCard(
                    title: 'Course Statistics',
                    icon: Icons.book,
                    count: '${ds.courses.length}',
                    subtitle: 'Active institutional modules',
                    color: AppColors.secondary,
                    width: width,
                  ),
                  _ReportCard(
                    title: 'System Complaints',
                    icon: Icons.warning_amber_rounded,
                    count: '${ds.complaints.length}',
                    subtitle: '${ds.complaints.where((c) => c["status"] == "pending").length} pending grievances',
                    color: AppColors.accent,
                    width: width,
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),

            // Advanced Dashboards Row 1
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 950;
              if (isMobile) {
                return Column(
                  children: const [
                    DeptGpaChart(),
                    SizedBox(height: 20),
                    AttendanceAlertsGauge(),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: DeptGpaChart()),
                    SizedBox(width: 20),
                    Expanded(child: AttendanceAlertsGauge()),
                  ],
                );
              }
            }),
            const SizedBox(height: 20),

            // Advanced Dashboards Row 2
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 950;
              if (isMobile) {
                return Column(
                  children: [
                    const ResponseLeaderboard(),
                    const SizedBox(height: 20),
                    _buildLegacyAttendanceOverview(ds),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: ResponseLeaderboard()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildLegacyAttendanceOverview(ds)),
                  ],
                );
              }
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyAttendanceOverview(DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Attendance Overview by Course',
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 12),
          if (ds.attendance.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('No attendance registers found.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...ds.attendance.take(5).map((a) {
              final String courseId = a['courseId'] ?? '';
              final int percent = a['percentage'] ?? 0;
              final double value = percent / 100.0;
              final Color barColor = percent >= 75 ? AppColors.secondary : AppColors.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        courseId,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$percent%',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: barColor),
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

// ── OVERVIEW CARD WITH LEGIBILITY COLOR FIX ─────────────
class _ReportCard extends StatelessWidget {
  final String title, count, subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.subtitle,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.raised,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DEPARTMENT GPA COMPARATIVE PROGRESS BARS ─────────────
class DeptGpaChart extends StatelessWidget {
  const DeptGpaChart({super.key});

  @override
  Widget build(BuildContext context) {
    final depts = [
      {'name': 'Computer Science & Eng (CSE)', 'gpa': 8.42, 'color': AppColors.primary},
      {'name': 'Information Technology (IT)', 'gpa': 8.15, 'color': AppColors.primaryLight},
      {'name': 'Electronics & Comm (ECE)', 'gpa': 7.88, 'color': AppColors.secondary},
      {'name': 'Electrical & Electronics (EEE)', 'gpa': 7.54, 'color': AppColors.warning},
      {'name': 'Mechanical Engineering (MECH)', 'gpa': 7.12, 'color': AppColors.error},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Department GPA comparisons',
            icon: Icons.bar_chart,
          ),
          const SizedBox(height: 12),
          ...depts.map((d) {
            final double gpa = d['gpa'] as double;
            final double progress = gpa / 10.0; 
            final Color color = d['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        d['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                      ),
                      Text(
                        '$gpa / 10.0',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.7), color],
                            ),
                            borderRadius: BorderRadius.circular(5),
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

// ── radial nested concentric shortage gauge ─────────────
class AttendanceAlertsGauge extends StatelessWidget {
  const AttendanceAlertsGauge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Attendance Shortage Alert Tracker',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 8),
          const Text(
            'Institutional tracking of students falling below the mandatory 75% attendance threshold.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _AttendanceGaugePainter(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('CSE Shortage: 12%', const Color(0xFFEF4444), '14 Students'),
                    const SizedBox(height: 10),
                    _buildLegendItem('IT Shortage: 18%', const Color(0xFFF59E0B), '19 Students'),
                    const SizedBox(height: 10),
                    _buildLegendItem('ECE Shortage: 22%', const Color(0xFF3B82F6), '26 Students'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceGaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final basePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0;

    final double r1 = 52.0;
    final double r2 = 39.0;
    final double r3 = 26.0;

    canvas.drawCircle(center, r1, basePaint);
    canvas.drawCircle(center, r2, basePaint);
    canvas.drawCircle(center, r3, basePaint);

    void drawArc(double radius, double percent, Color color) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7.0;

      final double startAngle = -3.14159 / 2; 
      final double sweepAngle = 2 * 3.14159 * percent;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    drawArc(r1, 0.12, const Color(0xFFEF4444)); 
    drawArc(r2, 0.18, const Color(0xFFF59E0B)); 
    drawArc(r3, 0.22, const Color(0xFF3B82F6)); 
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── GRIEVANCE RESOLUTION LEADERBOARD INDEX ───────────────
class ResponseLeaderboard extends StatelessWidget {
  const ResponseLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final leaders = [
      {'name': 'Design & Algorithms (CSE)', 'time': '1.2 Days', 'score': 0.95, 'color': const Color(0xFF10B981)},
      {'name': 'Information Tech (IT)', 'time': '1.8 Days', 'score': 0.88, 'color': const Color(0xFF3B82F6)},
      {'name': 'Electronics & Comm (ECE)', 'time': '2.1 Days', 'score': 0.82, 'color': const Color(0xFFF59E0B)},
      {'name': 'Electrical & Electronics (EEE)', 'time': '2.9 Days', 'score': 0.74, 'color': const Color(0xFFF97316)},
      {'name': 'Mechanical Engineering (MECH)', 'time': '3.5 Days', 'score': 0.65, 'color': const Color(0xFFEF4444)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Department Grievance Leaderboard',
            icon: Icons.leaderboard,
          ),
          const SizedBox(height: 12),
          ...leaders.asMap().entries.map((entry) {
            final int index = entry.key;
            final item = entry.value;
            final Color color = item['color'] as Color;
            final double score = item['score'] as double;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Avg Resolution Time: ${item['time']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: score,
                          strokeWidth: 3,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Text(
                        '${(score * 100).toInt()}%',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
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
