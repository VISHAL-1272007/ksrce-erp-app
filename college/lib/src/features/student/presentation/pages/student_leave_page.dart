import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentLeavePage extends StatefulWidget {
  const StudentLeavePage({super.key});

  @override
  State<StudentLeavePage> createState() => _StudentLeavePageState();
}

class _StudentLeavePageState extends State<StudentLeavePage> {
  String _leaveType = 'Medical Leave';
  final _reasonController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final uid = ds.currentUserId ?? '';
      final leaveHistory = ds.getUserLeave(uid);
      final balances = ds.getUserLeaveBalance(uid);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.event_busy, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Leave Applications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Apply for leave and track your leave history', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              _buildLeaveBalance(balances),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _buildLeaveHistory(leaveHistory)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildApplyLeaveForm(ds, uid)),
              ]),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLeaveBalance(List<Map<String, dynamic>> balances) {
    if (balances.isEmpty) {
      return Row(children: [
        _leaveCard('Medical', '0', '10', Colors.redAccent),
        const SizedBox(width: 16),
        _leaveCard('Personal', '0', '5', Colors.orange),
        const SizedBox(width: 16),
        _leaveCard('On Duty', '0', 'Unlimited', Colors.blue),
      ]);
    }
    return Row(
      children: balances.map((b) {
        final type = b['leaveType'] ?? '';
        final used = b['used']?.toString() ?? '0';
        final total = b['total']?.toString() ?? '-';
        final color = type.toString().contains('Medical') ? Colors.redAccent : type.toString().contains('Personal') ? Colors.orange : Colors.blue;
        return Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _leaveCard(type.toString(), used, total, color),
        ));
      }).toList(),
    );
  }

  Widget _leaveCard(String label, String used, String total, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 8),
        RichText(text: TextSpan(children: [
          TextSpan(text: used, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          if (total != '-') TextSpan(text: '/$total', style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
        ])),
        const SizedBox(height: 4),
        Text(total == '-' ? 'Days' : 'Used/Total', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
      ]),
    );
  }

  Widget _buildLeaveHistory(List<Map<String, dynamic>> history) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          if (history.isEmpty) const Center(child: Text('No leave records', style: TextStyle(color: AppColors.textLight))),
          ...history.map((l) {
            final status = l['status'] ?? 'pending';
            final isApproved = status == 'approved';
            final color = isApproved ? Colors.green : status == 'rejected' ? Colors.redAccent : Colors.orange;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(isApproved ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.hourglass_empty, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l['leaveType'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
                  Text('${l['fromDate'] ?? ''} to ${l['toDate'] ?? ''} (${l['days'] ?? '-'} days)', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                  Text(l['reason'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                ])),
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

  Widget _buildApplyLeaveForm(DataService ds, String uid) {
    final types = ['Medical Leave', 'Personal Leave', 'On Duty', 'Emergency Leave'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 20),
          const Text('Leave Type', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: AppCardStyles.flat,
            child: DropdownButton<String>(
              value: _leaveType, isExpanded: true, dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textDark), underline: const SizedBox(),
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _leaveType = v!),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('From Date', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 8),
              _dateField('Select start date', _fromDate, (d) => setState(() => _fromDate = d)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('To Date', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 8),
              _dateField('Select end date', _toDate, (d) => setState(() => _toDate = d)),
            ])),
          ]),
          const SizedBox(height: 16),
          const Text('Reason', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController, maxLines: 4,
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Describe the reason for leave...',
              hintStyle: const TextStyle(color: AppColors.textLight),
              filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_fromDate != null && _toDate != null && _reasonController.text.isNotEmpty) {
                  final days = _toDate!.difference(_fromDate!).inDays + 1;
                  ds.applyLeave({
                    'userId': uid,
                    'leaveType': _leaveType,
                    'fromDate': _fromDate!.toIso8601String().substring(0, 10),
                    'toDate': _toDate!.toIso8601String().substring(0, 10),
                    'days': days,
                    'reason': _reasonController.text,
                  });
                  _reasonController.clear();
                  setState(() { _fromDate = null; _toDate = null; });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application submitted')));
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Submit Leave Application'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String hint, DateTime? value, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: AppCardStyles.flat,
        child: Row(children: [
          Expanded(child: Text(
            value != null ? '${value.day}/${value.month}/${value.year}' : hint,
            style: TextStyle(color: value != null ? AppColors.textDark : AppColors.textLight, fontSize: 13),
          )),
          const Icon(Icons.calendar_today, color: AppColors.textLight, size: 18),
        ]),
      ),
    );
  }
}
