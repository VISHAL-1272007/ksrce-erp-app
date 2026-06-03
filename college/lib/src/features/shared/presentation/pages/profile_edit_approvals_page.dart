import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileEditApprovalsPage extends StatefulWidget {
  const ProfileEditApprovalsPage({super.key});
  @override
  State<ProfileEditApprovalsPage> createState() => _ProfileEditApprovalsPageState();
}

class _ProfileEditApprovalsPageState extends State<ProfileEditApprovalsPage> {
  final _remarksCtrl = TextEditingController();

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final uid = ds.currentUserId ?? '';
      final role = ds.currentRole ?? '';
      final pending = ds.getPendingApprovals(uid, role);
      final allRequests = ds.profileEditRequests;
      final processed = allRequests.where((r) {
        final chain = (r['approvalChain'] as List<dynamic>?) ?? [];
        return chain.any((s) {
          final step = s as Map<String, dynamic>;
          return step['approverId'] == uid && (step['status'] == 'approved' || step['status'] == 'rejected');
        });
      }).toList();
      final pendingLen = pending.length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.verified_user, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Profile Edit Approvals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text(_roleDescription(role), style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                ])),
                if (pending.isNotEmpty) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('$pendingLen Pending', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ]),
              const SizedBox(height: 24),
              if (pending.isNotEmpty) ...[
                _sectionHeader('Pending Requests', Icons.hourglass_top, AppColors.accent, pendingLen),
                const SizedBox(height: 12),
                ...pending.map((r) => _pendingCard(ds, r, uid, isMobile)),
                const SizedBox(height: 28),
              ],
              if (pending.isEmpty)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.secondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('No pending requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    const Text('All profile edit requests have been processed', style: TextStyle(color: AppColors.textLight)),
                  ]),
                ),
              if (processed.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader('Recently Processed', Icons.history, AppColors.textMedium, processed.length),
                const SizedBox(height: 12),
                ...processed.take(10).map((r) => _processedCard(r)),
              ],
            ]),
          );
        }),
      );
    });
  }

  Widget _pendingCard(DataService ds, Map<String, dynamic> req, String uid, bool isMobile) {
    final reqName = req['requesterName'] as String? ?? '';
    final reqId = req['requesterId'] as String? ?? '';
    final reqRole = req['requesterRole'] as String? ?? '';
    final requestType = req['requestType'] as String? ?? 'profile_edit';
    final changes = (req['changes'] as Map<String, dynamic>?) ?? {};
    final reason = req['reason'] as String? ?? '';
    final submitted = req['submittedDate'] as String? ?? '';
    final chain = (req['approvalChain'] as List<dynamic>?) ?? [];
    final requestId = req['requestId'] as String? ?? '';
    final initials = reqName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final roleLabel = reqRole == 'student' ? 'Student' : 'Faculty';
    final roleColor = reqRole == 'student' ? AppColors.accent : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 20, backgroundColor: roleColor,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reqName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            Row(children: [
              _tag(roleLabel, roleColor),
              const SizedBox(width: 8),
              Text(reqId, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ]),
          ])),
          Text(submitted, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        ]),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        Row(children: [
          _tag(requestType == 'password_reset' ? 'Password Reset' : 'Profile Edit', const Color(0xFF0EA5E9)),
          const SizedBox(width: 8),
          _tag('Approver: ${req['currentApprover'] ?? '-'}', AppColors.textMedium),
        ]),
        const SizedBox(height: 10),
        const Text('Requested Changes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...changes.entries.map((e) {
          final c = e.value as Map<String, dynamic>;
          final oldVal = c['old']?.toString() ?? '';
          final newVal = c['new']?.toString() ?? '';
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.key, style: const TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(oldVal, style: const TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.lineThrough))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textLight)),
                    Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(newVal, style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)))),
                  ]),
                ])
              : Row(children: [
                  SizedBox(width: 120, child: Text(e.key, style: const TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500))),
                  Expanded(child: Row(children: [
                    Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(oldVal, style: const TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.lineThrough)))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textLight)),
                    Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(newVal, style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)))),
                  ])),
                ]));
        }),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.comment, size: 16, color: AppColors.textLight), const SizedBox(width: 8),
              Expanded(child: Text(reason, style: const TextStyle(color: AppColors.textMedium, fontSize: 13, fontStyle: FontStyle.italic))),
            ])),
        ],
        if (chain.any((s) => (s as Map<String, dynamic>)['status'] == 'approved')) ...[
          const SizedBox(height: 12),
          const Text('Prior Approvals:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: chain.where((s) => (s as Map<String, dynamic>)['status'] == 'approved').map((s) {
            final step = s as Map<String, dynamic>;
            final stepRole = step['role']?.toString() ?? '';
            final stepName = step['approverName']?.toString() ?? '';
            return Chip(avatar: const Icon(Icons.check, size: 14, color: AppColors.secondary),
              label: Text('$stepRole: $stepName', style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
              backgroundColor: AppColors.secondary.withValues(alpha: 0.08), side: BorderSide.none, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact);
          }).toList()),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        if (isMobile)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _remarksCtrl, style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(hintText: 'Add remarks (optional)', filled: true, fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _approveBtn(ds, requestId, uid)),
              const SizedBox(width: 8),
              Expanded(child: _rejectBtn(ds, requestId, uid)),
            ]),
          ])
        else
          Row(children: [
            Expanded(child: TextField(controller: _remarksCtrl, style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(hintText: 'Add remarks (optional)', filled: true, fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border))))),
            const SizedBox(width: 12),
            _approveBtn(ds, requestId, uid),
            const SizedBox(width: 8),
            _rejectBtn(ds, requestId, uid),
          ]),
      ]),
    );
  }

  Widget _approveBtn(DataService ds, String requestId, String uid) {
    return ElevatedButton.icon(
      onPressed: () {
        ds.approveEditRequest(requestId, uid, _remarksCtrl.text.trim());
        _remarksCtrl.clear();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved and forwarded'), backgroundColor: AppColors.secondary));
      },
      icon: const Icon(Icons.check, size: 16), label: const Text('Approve'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  Widget _rejectBtn(DataService ds, String requestId, String uid) {
    return ElevatedButton.icon(
      onPressed: () {
        if (_remarksCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a remark before rejecting')));
          return;
        }
        ds.rejectEditRequest(requestId, uid, _remarksCtrl.text.trim());
        _remarksCtrl.clear();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected'), backgroundColor: Colors.red));
      },
      icon: const Icon(Icons.close, size: 16), label: const Text('Reject'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  Widget _processedCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? '';
    final color = status == 'approved' ? AppColors.secondary : status == 'rejected' ? Colors.red : AppColors.accent;
    final reqName = req['requesterName'] as String? ?? '';
    final reqId = req['requesterId'] as String? ?? '';
    final changes = (req['changes'] as Map<String, dynamic>?) ?? {};
    final submitted = req['submittedDate'] as String? ?? '';
    final statusLabel = status == 'approved' ? 'Approved' : 'Rejected';
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(children: [
        Icon(status == 'approved' ? Icons.check_circle : Icons.cancel, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(reqName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
            const SizedBox(width: 8), Text(reqId, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
          ]),
          Text(changes.keys.join(', '), style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _tag(statusLabel, color),
          const SizedBox(height: 4),
          Text(submitted, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, int count) {
    final countStr = count.toString();
    return Row(children: [
      Icon(icon, color: color, size: 20), const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(countStr, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
    ]);
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));

  String _roleDescription(String role) {
    switch (role) {
      case 'faculty': return 'Review student requests as Mentor / Class Adviser (profile edit and password reset)';
      case 'hod': return 'Review department requests (profile edit and password reset)';
      case 'admin': return 'Final approval for admin-routed requests';
      default: return 'Review profile edit and password reset requests';
    }
  }
}
