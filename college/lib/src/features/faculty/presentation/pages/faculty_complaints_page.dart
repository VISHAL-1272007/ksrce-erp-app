import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyComplaintsPage extends StatelessWidget {
  const FacultyComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final complaints = ds.getFacultyComplaints(fid);
      final pendingCount = complaints.where((c) => c['status'] == 'pending').length;
      final resolvedCount = complaints.where((c) => c['status'] == 'resolved').length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.report_problem, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text('Student Complaints', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              _stat('Total', '${complaints.length}', AppColors.primary, Icons.inbox),
              const SizedBox(width: 16),
              _stat('Pending', '$pendingCount', Colors.orange, Icons.pending),
              const SizedBox(width: 16),
              _stat('Resolved', '$resolvedCount', Colors.green, Icons.check_circle),
            ]),
            const SizedBox(height: 24),
            _buildComplaintsList(complaints, ds),
          ]),
        ),
      );
    });
  }

  Widget _stat(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
      ]),
    ));
  }

  Widget _buildComplaintsList(List<Map<String, dynamic>> complaints, DataService ds) {
    if (complaints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('No complaints from students', style: TextStyle(color: AppColors.textLight))),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        ...complaints.map((c) {
          final status = c['status'] ?? 'pending';
          final color = status == 'resolved' ? Colors.green : status == 'in_progress' ? Colors.blue : Colors.orange;
          final studentName = ds.getStudentById(c['studentId'] ?? '')?.containsKey('name') == true
              ? ds.getStudentById(c['studentId'] ?? '')!['name'] : c['studentId'] ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(c['subject'] ?? c['category'] ?? 'Complaint', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(status.toString().toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(c['description'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
              const SizedBox(height: 6),
              Text('From: $studentName | ${c['submittedDate'] ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ]),
          );
        }),
      ]),
    );
  }
}
