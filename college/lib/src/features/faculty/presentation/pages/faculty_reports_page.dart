import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyReportsPage extends StatelessWidget {
  const FacultyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid);

      // Compute attendance summary per course
      final summaries = <Map<String, dynamic>>[];
      for (final c in courses) {
        final cid = c['courseId'] as String? ?? '';
        final att = ds.getCourseAttendance(cid);
        final students = ds.getCourseStudents(cid);
        int totalP = 0, totalC = 0;
        for (final a in att) {
          totalP += (a['attendedClasses'] as int?) ?? 0;
          totalC += (a['totalClasses'] as int?) ?? 0;
        }
        final avgPct = totalC > 0 ? (totalP / totalC * 100) : 0.0;
        final below75 = att.where((a) {
          final t = (a['totalClasses'] as int?) ?? 1;
          final p = (a['attendedClasses'] as int?) ?? 0;
          return t > 0 && (p / t * 100) < 75;
        }).length;
        summaries.add({'courseId': cid, 'courseName': c['courseName'], 'students': students.length, 'avgAttendance': avgPct, 'below75': below75});
      }

      // Result analysis
      final resultSummary = <Map<String, dynamic>>[];
      for (final c in courses) {
        final cid = c['courseId'] as String? ?? '';
        final res = ds.results.where((r) => r['courseId'] == cid).toList();
        final passCount = res.where((r) => r['grade'] != 'F' && r['grade'] != null).length;
        final total = res.length;
        resultSummary.add({'courseId': cid, 'courseName': c['courseName'], 'total': total, 'pass': passCount, 'passRate': total > 0 ? (passCount / total * 100) : 0.0});
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.analytics, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text('Reports & Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 24),
            _buildAttendanceSummary(summaries),
            const SizedBox(height: 24),
            _buildResultAnalysis(resultSummary),
          ]),
        ),
      );
    });
  }

  Widget _buildAttendanceSummary(List<Map<String, dynamic>> summaries) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Attendance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        if (summaries.isEmpty) const Center(child: Text('No data', style: TextStyle(color: AppColors.textLight))),
        ...summaries.map((s) {
          final pct = (s['avgAttendance'] as double?) ?? 0;
          final color = pct >= 75 ? Colors.green : pct >= 60 ? Colors.orange : Colors.redAccent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s['courseId']} - ${s['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${s['students']} students | ${s['below75']} below 75%', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
              SizedBox(width: 100, child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color))),
              const SizedBox(width: 10),
              Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildResultAnalysis(List<Map<String, dynamic>> results) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Result Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        if (results.isEmpty) const Center(child: Text('No data', style: TextStyle(color: AppColors.textLight))),
        ...results.map((r) {
          final passRate = (r['passRate'] as double?) ?? 0;
          final color = passRate >= 80 ? Colors.green : passRate >= 50 ? Colors.orange : Colors.redAccent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r['courseId']} - ${r['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${r['pass']}/${r['total']} passed', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
              SizedBox(width: 100, child: LinearProgressIndicator(value: passRate / 100, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color))),
              const SizedBox(width: 10),
              Text('${passRate.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ]),
          );
        }),
      ]),
    );
  }
}
