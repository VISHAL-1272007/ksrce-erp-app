import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyAdviserPage extends StatelessWidget {
  const FacultyAdviserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final fid = ds.currentUserId ?? '';
      final isAdviser = ds.isFacultyClassAdviser(fid);
      final adviserClass = ds.getAdviserClass(fid);

      if (!isAdviser || adviserClass == null || adviserClass.isEmpty) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: _buildNotAssigned()),
        );
      }

      final deptId = adviserClass['departmentId'] as String? ?? '';
      final year = adviserClass['year']?.toString() ?? '-';
      final section = adviserClass['section'] as String? ?? '-';
      final deptName = ds.getDepartmentName(deptId);
      final studentIds = (adviserClass['studentIds'] as List<dynamic>?)?.cast<String>() ?? [];

      // Get all students in this class
      final classStudents = ds.students.where((s) =>
        studentIds.contains(s['studentId'] as String?) ||
        (s['departmentId'] == deptId && s['year']?.toString() == year && s['section'] == section)
      ).toList();

      // Calculate class statistics
      double totalCgpa = 0; int cgpaCount = 0;
      int arrearStudents = 0;
      for (final s in classStudents) {
        final c = s['cgpa'];
        if (c != null) {
          final val = c is num ? c.toDouble() : double.tryParse(c.toString()) ?? 0;
          if (val > 0) { totalCgpa += val; cgpaCount++; }
        }
        final ac = s['arrearCount'];
        if (ac != null && ((ac is num && ac > 0) || (ac is String && (int.tryParse(ac) ?? 0) > 0))) arrearStudents++;
      }
      final avgCgpa = cgpaCount > 0 ? totalCgpa / cgpaCount : 0.0;

      // Recent complaints from class students
      final classStudentIds = classStudents.map((s) => s['studentId'] as String?).where((id) => id != null).toSet();
      final classComplaints = ds.complaints.where((c) => classStudentIds.contains(c['studentId'])).toList();
      final pendingComplaints = classComplaints.where((c) => c['status'] == 'pending' || c['status'] == 'open').length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(isMobile, deptName, year, section, classStudents.length),
              const SizedBox(height: 24),
              _buildClassStats(isMobile, classStudents.length, avgCgpa, arrearStudents, pendingComplaints),
              const SizedBox(height: 28),
              if (isMobile) ...[
                _buildStudentList(isMobile, classStudents, ds),
                const SizedBox(height: 20),
                _buildComplaintsSection(classComplaints),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildStudentList(isMobile, classStudents, ds)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildComplaintsSection(classComplaints)),
                ]),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildNotAssigned() {
    return Container(
      padding: const EdgeInsets.all(40),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: AppCardStyles.elevated,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_off_rounded, size: 48, color: Color(0xFFF97316)),
        ),
        const SizedBox(height: 20),
        const Text('Not a Class Adviser',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 8),
        const Text('You are not currently assigned as a class adviser.\nYour HOD can assign you to a class.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.5)),
      ]),
    );
  }

  Widget _buildHeader(bool isMobile, String deptName, String year, String section, int count) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF7C3AED)),
      ),
      child: isMobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Class Adviser', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$deptName  •  Year $year  •  Section $section',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _headerPill('$count Students'),
              const SizedBox(width: 8),
              _headerPill('Year $year'),
              const SizedBox(width: 8),
              _headerPill('Section $section'),
            ]),
          ])
        : Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Class Adviser Dashboard', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Text('$deptName  •  Year $year  •  Section $section',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            ])),
            Row(children: [
              _headerPill('$count Students'),
              const SizedBox(width: 8),
              _headerPill('Section $section'),
            ]),
          ]),
    );
  }

  Widget _headerPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildClassStats(bool isMobile, int total, double avgCgpa, int arrears, int complaints) {
    final stats = [
      _Stat('Students', '$total', Icons.people_rounded, const Color(0xFF3B82F6)),
      _Stat('Avg CGPA', avgCgpa.toStringAsFixed(2), Icons.trending_up_rounded, const Color(0xFF10B981)),
      _Stat('With Arrears', '$arrears', Icons.warning_rounded, const Color(0xFFF97316)),
      _Stat('Complaints', '$complaints', Icons.report_problem_rounded, const Color(0xFFF43F5E)),
    ];
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
        children: stats.map(_statCard).toList(),
      );
    }
    return Row(children: stats.asMap().entries.map((e) =>
      Expanded(child: Padding(
        padding: EdgeInsets.only(left: e.key > 0 ? 14 : 0),
        child: _statCard(e.value),
      )),
    ).toList());
  }

  Widget _statCard(_Stat s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.statCard(s.color),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: s.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(s.icon, color: s.color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(s.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
        Text(s.label, style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildStudentList(bool isMobile, List<Map<String, dynamic>> students, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Class Students', icon: Icons.people_rounded),
        if (students.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No students in this class', style: TextStyle(color: AppColors.textLight))),
          )
        else
          ...students.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final name = s['name'] as String? ?? 'Student';
            final sid = s['studentId'] as String? ?? '';
            final regNo = s['registerNumber'] as String? ?? sid;
            final cgpa = s['cgpa']?.toString() ?? '-';
            final phone = s['phone'] as String? ?? '';
            final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

            final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6), const Color(0xFFF97316), const Color(0xFFF43F5E)];
            final accent = colors[i % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 18, backgroundColor: accent.withValues(alpha: 0.1),
                  child: Text(initials, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(regNo, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                ])),
                if (!isMobile && phone.isNotEmpty) ...[
                  Icon(Icons.phone_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(phone, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text('CGPA: $cgpa', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _buildComplaintsSection(List<Map<String, dynamic>> complaints) {
    final recent = complaints.take(6).toList();
    final statusColors = {
      'pending': const Color(0xFFF97316), 'open': const Color(0xFFF97316),
      'resolved': const Color(0xFF10B981), 'closed': const Color(0xFF6B7280),
      'in_progress': const Color(0xFF3B82F6),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Student Complaints', icon: Icons.report_problem_rounded),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(children: [
              Icon(Icons.check_circle_rounded, size: 36, color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              const Text('No complaints', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            ])),
          )
        else
          ...recent.map((c) {
            final status = (c['status'] as String?) ?? 'pending';
            final color = statusColors[status] ?? const Color(0xFFF97316);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(c['subject'] as String? ?? c['title'] as String? ?? 'Complaint',
                    style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(c['description'] as String? ?? c['message'] as String? ?? '',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('By: ${c['studentName'] ?? c['studentId'] ?? ''}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            );
          }),
      ]),
    );
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}
