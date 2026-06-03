import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentFeesPage extends StatelessWidget {
  const StudentFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final fees = ds.getStudentFees(uid);
      final total = ds.getStudentTotalFees(uid);
      final paid = ds.getStudentPaidFees(uid);
      final pending = ds.getStudentPendingFees(uid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.payment, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Fee Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Academic Year 2025-26', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildFeeSummary(total, paid, pending),
              const SizedBox(height: 24),
              _buildFeeBreakdown(fees),
              const SizedBox(height: 24),
              if (pending > 0) _buildPayButton(pending),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFeeSummary(double total, double paid, double pending) {
    return Row(
      children: [
        _feeCard('Total Fee', 'Rs. ${total.toStringAsFixed(0)}', AppColors.primary, Icons.account_balance),
        const SizedBox(width: 16),
        _feeCard('Paid', 'Rs. ${paid.toStringAsFixed(0)}', Colors.green, Icons.check_circle),
        const SizedBox(width: 16),
        _feeCard('Pending', 'Rs. ${pending.toStringAsFixed(0)}', Colors.redAccent, Icons.pending),
      ],
    );
  }

  Widget _feeCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeBreakdown(List<Map<String, dynamic>> fees) {
    if (fees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: const Center(child: Text('No fee records found', style: TextStyle(color: AppColors.textLight))),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fee Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          ...fees.map((f) {
            final status = (f['status'] ?? 'pending').toString();
            final isPaid = status.toLowerCase() == 'paid';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(isPaid ? Icons.check_circle : Icons.pending, color: isPaid ? Colors.green : Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f['description'] ?? f['feeType'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('Semester: ${f['semester'] ?? '-'}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Rs. ${f['amount'] ?? 0}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Paid: Rs. ${f['paid'] ?? 0}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                    if ((f['pending'] as num?) != null && (f['pending'] as num) > 0)
                      Text('Due: Rs. ${f['pending']}', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ]),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPayButton(double pending) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.payment, size: 20),
        label: Text('Pay Pending Fees - Rs. ${pending.toStringAsFixed(0)}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
