import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyMenteesPage extends StatelessWidget {
  const FacultyMenteesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final fid = ds.currentUserId ?? '';
      final mentees = ds.getMentees(fid);
      final faculty = ds.getFacultyById(fid);
      final mentorName = faculty?['name'] as String? ?? 'Faculty';

      // Stats
      final avgCgpa = mentees.isEmpty ? 0.0 : mentees.map((m) {
        final c = m['cgpa'];
        if (c is num) return c.toDouble();
        if (c is String) return double.tryParse(c) ?? 0.0;
        return 0.0;
      }).reduce((a, b) => a + b) / mentees.length;

      final lowAttCount = mentees.where((m) {
        final att = ds.getStudentAttendanceFiltered(m['studentId'] as String? ?? '');
        if (att.isEmpty) return false;
        final total = att.length;
        final present = att.where((a) => a['status'] == 'present' || a['status'] == 'Present').length;
        return total > 0 && (present / total) < 0.75;
      }).length;

      final arrearCount = mentees.where((m) {
        final ac = m['arrearCount'];
        if (ac is num) return ac > 0;
        if (ac is String) return (int.tryParse(ac) ?? 0) > 0;
        return false;
      }).length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(isMobile, mentorName, mentees.length),
              const SizedBox(height: 24),
              _buildStatCards(isMobile, mentees.length, avgCgpa, lowAttCount, arrearCount),
              const SizedBox(height: 28),
              if (mentees.isEmpty)
                _buildEmptyState()
              else
                _buildMenteeList(isMobile, mentees, ds),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildHeader(bool isMobile, String mentorName, int count) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF059669)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.group_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Mentees', style: TextStyle(
            color: Colors.white, fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w700, letterSpacing: -0.3,
          )),
          const SizedBox(height: 4),
          Text('$count student${count != 1 ? 's' : ''} assigned to you as mentor',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
          )),
        ),
      ]),
    );
  }

  Widget _buildStatCards(bool isMobile, int totalMentees, double avgCgpa, int lowAtt, int arrears) {
    final stats = [
      _Stat('Mentees', '$totalMentees', Icons.people_rounded, const Color(0xFF3B82F6)),
      _Stat('Avg CGPA', avgCgpa.toStringAsFixed(2), Icons.school_rounded, const Color(0xFF10B981)),
      _Stat('Low Attendance', '$lowAtt', Icons.warning_rounded, const Color(0xFFF97316)),
      _Stat('With Arrears', '$arrears', Icons.error_outline_rounded, const Color(0xFFF43F5E)),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: AppCardStyles.elevated,
      child: Center(child: Column(children: [
        Icon(Icons.person_off_rounded, size: 56, color: AppColors.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 14),
        const Text('No mentees assigned yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        const Text('Your HOD will assign students to you', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
      ])),
    );
  }

  Widget _buildMenteeList(bool isMobile, List<Map<String, dynamic>> mentees, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Mentee Details', icon: Icons.people_rounded),
        const SizedBox(height: 4),
        ...mentees.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final name = m['name'] as String? ?? 'Student';
          final sid = m['studentId'] as String? ?? '';
          final regNo = m['registerNumber'] as String? ?? sid;
          final dept = m['department'] as String? ?? m['departmentId'] as String? ?? '';
          final year = m['year']?.toString() ?? '-';
          final section = m['section'] as String? ?? '';
          final cgpa = m['cgpa']?.toString() ?? '-';
          final phone = m['phone'] as String? ?? '';
          final email = m['email'] as String? ?? '';
          final parentPhone = m['parentPhone'] as String? ?? m['fatherPhone'] as String? ?? '';
          final arrears = m['arrearCount']?.toString() ?? '0';
          final batch = m['batch'] as String? ?? '';
          final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

          // Calculate attendance for this mentee
          final att = ds.getStudentAttendanceFiltered(sid);
          final totalClasses = att.length;
          final presentClasses = att.where((a) => a['status'] == 'present' || a['status'] == 'Present').length;
          final attPct = totalClasses > 0 ? (presentClasses / totalClasses * 100) : 0.0;

          final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFF8B5CF6), const Color(0xFFF97316), const Color(0xFFF43F5E)];
          final accent = colors[i % colors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: 4),
                childrenPadding: EdgeInsets.fromLTRB(isMobile ? 14 : 18, 0, isMobile ? 14 : 18, 14),
                leading: CircleAvatar(
                  radius: 20, backgroundColor: accent.withValues(alpha: 0.1),
                  child: Text(initials, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                subtitle: Text('$regNo  •  $dept Year $year-$section',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _badge('CGPA: $cgpa', const Color(0xFF3B82F6)),
                  const SizedBox(width: 6),
                  _badge('${attPct.toStringAsFixed(0)}%', attPct >= 75 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
                ]),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (isMobile)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _detailRow(Icons.badge_rounded, 'Register No', regNo),
                      _detailRow(Icons.calendar_today_rounded, 'Batch', batch),
                      _detailRow(Icons.phone_rounded, 'Phone', phone.isEmpty ? 'N/A' : phone),
                      _detailRow(Icons.email_rounded, 'Email', email.isEmpty ? 'N/A' : email),
                      _detailRow(Icons.family_restroom_rounded, 'Parent Phone', parentPhone.isEmpty ? 'N/A' : parentPhone),
                      _detailRow(Icons.warning_amber_rounded, 'Arrears', arrears),
                      _detailRow(Icons.fact_check_rounded, 'Attendance', '${attPct.toStringAsFixed(1)}% ($presentClasses/$totalClasses)'),
                    ])
                  else
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _detailRow(Icons.badge_rounded, 'Register No', regNo),
                        _detailRow(Icons.calendar_today_rounded, 'Batch', batch),
                        _detailRow(Icons.phone_rounded, 'Phone', phone.isEmpty ? 'N/A' : phone),
                        _detailRow(Icons.email_rounded, 'Email', email.isEmpty ? 'N/A' : email),
                      ])),
                      const SizedBox(width: 24),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _detailRow(Icons.family_restroom_rounded, 'Parent Phone', parentPhone.isEmpty ? 'N/A' : parentPhone),
                        _detailRow(Icons.warning_amber_rounded, 'Arrears', arrears),
                        _detailRow(Icons.fact_check_rounded, 'Attendance', '${attPct.toStringAsFixed(1)}% ($presentClasses/$totalClasses)'),
                        _detailRow(Icons.school_rounded, 'CGPA', cgpa),
                      ])),
                    ]),
                ],
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
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
