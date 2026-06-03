import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentPlacementsPage extends StatelessWidget {
  const StudentPlacementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final upcoming = ds.getUpcomingPlacements();
      final completed = ds.getCompletedPlacements();
      final applications = ds.getStudentPlacementApplications(uid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.business_center, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Placements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Campus placement drives and applications', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildPlacementStats(upcoming.length, completed.length, applications.length),
              const SizedBox(height: 24),
              _buildUpcomingDrives(upcoming, ds, uid),
              const SizedBox(height: 24),
              _buildApplications(applications, ds),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlacementStats(int upcomingCount, int completedCount, int appliedCount) {
    return Row(children: [
      _statCard('Upcoming Drives', '$upcomingCount', AppColors.primary, Icons.business),
      const SizedBox(width: 16),
      _statCard('Completed', '$completedCount', Colors.green, Icons.done_all),
      const SizedBox(width: 16),
      _statCard('My Applications', '$appliedCount', Colors.orange, Icons.description),
    ]);
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppCardStyles.elevated,
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildUpcomingDrives(List<Map<String, dynamic>> drives, DataService ds, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Placement Drives', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          if (drives.isEmpty) const Center(child: Text('No upcoming drives', style: TextStyle(color: AppColors.textLight))),
          ...drives.map((d) {
            final hasApplied = ds.getStudentPlacementApplications(uid).any((a) => a['placementId'] == d['placementId']);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppCardStyles.flat,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.business, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['company'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(d['role'] ?? '', style: const TextStyle(color: AppColors.accent, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.calendar_today, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text(d['date'] ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.monetization_on, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text(d['package'] ?? '', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Text('Min CGPA: ${d['minCGPA'] ?? '-'}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ]),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: hasApplied ? null : () => ds.applyForPlacement(uid, d['placementId'] ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasApplied ? Colors.grey : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(hasApplied ? 'Applied' : 'Apply Now'),
                  ),
                ])),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApplications(List<Map<String, dynamic>> applications, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          if (applications.isEmpty) const Center(child: Text('No applications yet', style: TextStyle(color: AppColors.textLight))),
          ...applications.map((a) {
            final placement = ds.getPlacementById(a['placementId'] ?? '');
            final status = a['status'] ?? 'applied';
            final color = status == 'shortlisted' ? Colors.green : status == 'rejected' ? Colors.redAccent : Colors.orange;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.description, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(placement?['company'] ?? a['placementId'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                  Text('Applied: ${a['appliedDate'] ?? '-'} | ${placement?['role'] ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(status.toString().toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
