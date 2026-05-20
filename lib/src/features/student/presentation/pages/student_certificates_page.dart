import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentCertificatesPage extends StatelessWidget {
  const StudentCertificatesPage({super.key});

  static final _certTypes = [
    {'name': 'Bonafide Certificate', 'desc': 'Proof of being a bonafide student', 'icon': Icons.verified, 'fee': 50, 'days': 3},
    {'name': 'Transfer Certificate', 'desc': 'Required when transferring', 'icon': Icons.swap_horiz, 'fee': 100, 'days': 7},
    {'name': 'Character Certificate', 'desc': 'Good character and conduct', 'icon': Icons.person_pin, 'fee': 50, 'days': 3},
    {'name': 'Study Certificate', 'desc': 'Proof of study period', 'icon': Icons.school, 'fee': 50, 'days': 3},
    {'name': 'Medium of Instruction', 'desc': 'English medium certificate', 'icon': Icons.language, 'fee': 50, 'days': 3},
    {'name': 'Course Completion', 'desc': 'Provisional completion cert', 'icon': Icons.assignment_turned_in, 'fee': 100, 'days': 7},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final history = ds.getStudentCertificates(uid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.card_membership, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Certificates', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Request and download academic certificates', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildAvailableCertificates(ds, uid),
              const SizedBox(height: 24),
              _buildRequestHistory(history),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvailableCertificates(DataService ds, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Certificates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16, runSpacing: 16,
            children: _certTypes.map((c) => SizedBox(
              width: 320,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppCardStyles.flat,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(c['icon'] as IconData, color: AppColors.accent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c['name'] as String, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15))),
                  ]),
                  const SizedBox(height: 8),
                  Text(c['desc'] as String, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.monetization_on, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text('Fee: Rs. ${c['fee']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.schedule, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text('${c['days']} working days', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ds.requestCertificate(uid, c['name'] as String, c['fee'] as int, c['days'] as int),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      child: const Text('Request Certificate'),
                    ),
                  ),
                ]),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestHistory(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: const Center(child: Text('No certificate requests yet', style: TextStyle(color: AppColors.textLight))),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          ...history.map((r) {
            final status = r['status'] ?? 'pending';
            final isReady = status == 'ready';
            final color = isReady ? Colors.green : status == 'pending' ? Colors.orange : Colors.grey;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(isReady ? Icons.check_circle : Icons.hourglass_empty, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['type'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                  Text('Ref: ${r['certId'] ?? '-'} | ${r['requestDate'] ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
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
