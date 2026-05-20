import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentLibraryPage extends StatelessWidget {
  const StudentLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final allBooks = ds.getStudentLibrary(uid);
      final issued = ds.getStudentIssuedBooks(uid);
      final returned = ds.getStudentReturnedBooks(uid);
      final overdue = ds.getStudentOverdueBooks(uid);
      final fines = ds.getStudentLibraryFines(uid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.local_library, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Library', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Book Issues, Returns & Search', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildLibrarySummary(issued.length, returned.length, overdue, fines),
              const SizedBox(height: 24),
              _buildBooksIssued(allBooks),
              if (fines > 0) ...[
                const SizedBox(height: 24),
                _buildFineNotice(fines, overdue),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLibrarySummary(int issuedCount, int returnedCount, int overdueCount, double fines) {
    return Row(
      children: [
        _summaryCard('Books Issued', '$issuedCount', AppColors.primary, Icons.book),
        const SizedBox(width: 16),
        _summaryCard('Returned', '$returnedCount', Colors.green, Icons.assignment_return),
        const SizedBox(width: 16),
        _summaryCard('Overdue', '$overdueCount', Colors.redAccent, Icons.warning),
        const SizedBox(width: 16),
        _summaryCard('Total Fine', 'Rs. ${fines.toStringAsFixed(0)}', Colors.orange, Icons.money),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
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

  Widget _buildBooksIssued(List<Map<String, dynamic>> books) {
    if (books.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: const Center(child: Text('No books issued', style: TextStyle(color: AppColors.textLight))),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Book Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          ...books.map((b) {
            final status = b['status'] ?? 'issued';
            final isOverdue = status == 'overdue';
            final color = isOverdue ? Colors.redAccent : status == 'returned' ? Colors.grey : Colors.green;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.menu_book, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b['title'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                  Text('by ${b['author'] ?? '-'}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  Text('Issue: ${b['issueDate'] ?? '-'} | Due: ${b['dueDate'] ?? '-'}', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                ])),
                if (b['fine'] != null && (b['fine'] as num) > 0)
                  Padding(padding: const EdgeInsets.only(right: 10),
                    child: Text('Fine: Rs. ${b['fine']}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(status.toString().toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFineNotice(double fines, int overdueCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.warning, color: Colors.redAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Overdue Fine Notice', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('You have $overdueCount overdue book(s). Current fine: Rs. ${fines.toStringAsFixed(0)}. Please return immediately.', style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
        ])),
      ]),
    );
  }
}
