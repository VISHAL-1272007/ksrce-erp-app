import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import 'dart:math';

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final studentId = ds.currentUserId ?? '';
      final attList = ds.getStudentAttendanceFiltered(studentId);
      int totalClasses = 0, totalPresent = 0, totalAbsent = 0;
      for (final a in attList) {
        totalClasses += (a['totalClasses'] as int? ?? 0);
        totalPresent += (a['attendedClasses'] as int? ?? 0);
        totalAbsent += (a['absentClasses'] as int? ?? 0);
      }
      final overallPct = ds.overallAttendancePercentage;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.fact_check, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Attendance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Current Semester Attendance', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              if (isMobile) ...[
                _buildOverallAttendance(overallPct, totalClasses, totalPresent, totalAbsent),
                const SizedBox(height: 24),
                _buildSubjectBars(attList),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildOverallAttendance(overallPct, totalClasses, totalPresent, totalAbsent)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSubjectBars(attList)),
                ]),
              const SizedBox(height: 24),
              _buildSubjectWiseTable(attList),
              const SizedBox(height: 24),
              _buildAttendanceNote(),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildOverallAttendance(double pct, int total, int present, int absent) {
    Color ringColor = pct >= 85 ? Colors.green : pct >= 75 ? Colors.orange : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppCardStyles.elevated,
      child: Column(children: [
        const Text('Overall Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 24),
        SizedBox(width: 160, height: 160, child: CustomPaint(
          painter: _CircularProgressPainter(pct / 100, ringColor),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: ringColor)),
            const Text('Present', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ])),
        )),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _statItem('Total Classes', '$total', AppColors.textDark),
          _statItem('Present', '$present', Colors.green),
          _statItem('Absent', '$absent', Colors.redAccent),
        ]),
      ]),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
    ]);
  }

  Widget _buildSubjectBars(List<Map<String, dynamic>> attList) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Subject-wise Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        ...attList.map((a) {
          final pct = (a['percentage'] as num?)?.toDouble() ?? 0;
          return _barRow(a['courseName'] as String? ?? '', pct.round());
        }),
      ]),
    );
  }

  Widget _barRow(String label, int pct) {
    Color color = pct >= 85 ? Colors.green : pct >= 75 ? Colors.orange : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
        )),
        const SizedBox(width: 12),
        SizedBox(width: 40, child: Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSubjectWiseTable(List<Map<String, dynamic>> attList) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Subject-wise Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600),
            child: Table(
              columnWidths: const {0: FixedColumnWidth(90), 1: FlexColumnWidth(2), 2: FixedColumnWidth(70), 3: FixedColumnWidth(70), 4: FixedColumnWidth(80), 5: FixedColumnWidth(80)},
              children: [
                TableRow(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  children: ['Code', 'Subject', 'Present', 'Total', 'Percentage', 'Status'].map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(h, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                  )).toList(),
                ),
                ...attList.map((s) {
                  final pct = (s['percentage'] as num?)?.toDouble() ?? 0;
                  Color statusColor = pct >= 75 ? Colors.green : pct >= 70 ? Colors.orange : Colors.redAccent;
                  String status = pct >= 75 ? 'Safe' : pct >= 70 ? 'Warning' : 'Shortage';
                  return TableRow(children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(s['courseCode'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(s['courseName'] as String? ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 13))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('${s['attendedClasses'] ?? 0}', style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('${s['totalClasses'] ?? 0}', style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    )),
                  ]);
                }),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAttendanceNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(children: const [
        Icon(Icons.info_outline, color: Colors.orange, size: 20),
        SizedBox(width: 12),
        Expanded(child: Text(
          'Minimum 75% attendance is required in each subject to be eligible for end semester examinations.',
          style: TextStyle(color: Colors.orange, fontSize: 13),
        )),
      ]),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CircularProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final bgPaint = Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 12;
    final fgPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
