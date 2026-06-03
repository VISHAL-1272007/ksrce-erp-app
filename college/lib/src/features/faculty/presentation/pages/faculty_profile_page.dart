import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyProfilePage extends StatefulWidget {
  const FacultyProfilePage({super.key});
  @override
  State<FacultyProfilePage> createState() => _FacultyProfilePageState();
}

class _FacultyProfilePageState extends State<FacultyProfilePage> {
  bool _showEditForm = false;
  bool _showMyRequests = false;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _qualifCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _qualifCtrl.dispose();
    _specCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> fac) {
    _phoneCtrl.text = (fac['phone'] as String?) ?? '';
    _emailCtrl.text = (fac['email'] as String?) ?? '';
    _qualifCtrl.text = (fac['qualification'] as String?) ?? '';
    _specCtrl.text = (fac['specialization'] as String?) ?? '';
    _reasonCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final fac = ds.currentFaculty ?? {};
      final name = (fac['name'] as String?) ?? 'Faculty';
      final facId = (fac['facultyId'] as String?) ?? ds.currentUserId ?? '';
      final dept = (fac['department'] as String?) ?? '';
      final designation = (fac['designation'] as String?) ?? '';
      final qualification = (fac['qualification'] as String?) ?? '';
      final specialization = (fac['specialization'] as String?) ?? '';
      final email = (fac['email'] as String?) ?? '';
      final phone = (fac['phone'] as String?) ?? '';
      final joinDate = (fac['joiningDate'] as String?) ?? '';
      final experience = (fac['experience'] as String?) ?? '';
      final isHOD = (fac['isHOD'] == true);
      final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
      final myRequests = ds.getMyEditRequests(facId);
      final chain = ds.getFacultyApprovalChain(facId);
      final pendingCount = myRequests.where((r) => r['status'] != 'approved' && r['status'] != 'rejected').length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                if (!isHOD) ...[
                  _actionBtn(Icons.edit, 'Edit Profile', AppColors.primary, () {
                    setState(() { _showEditForm = !_showEditForm; _showMyRequests = false; });
                    if (_showEditForm) _initControllers(fac);
                  }),
                  const SizedBox(width: 10),
                  Stack(children: [
                    _actionBtn(Icons.history, 'My Requests', AppColors.accent, () {
                      setState(() { _showMyRequests = !_showMyRequests; _showEditForm = false; });
                    }),
                    if (pendingCount > 0)
                      Positioned(top: 0, right: 0, child: Container(
                        width: 18, height: 18, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(9)),
                        alignment: Alignment.center,
                        child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )),
                  ]),
                ],
              ]),
              const SizedBox(height: 20),
              _profileHeader(isMobile, name, initials, facId, dept, designation, isHOD),
              const SizedBox(height: 20),
              if (_showEditForm && !isHOD) ...[_buildEditForm(ds, fac, chain), const SizedBox(height: 20)],
              if (_showMyRequests && !isHOD) ...[_buildMyRequests(myRequests), const SizedBox(height: 20)],
              if (isMobile) ...[
                _professionalInfo(isMobile, qualification, specialization, experience, joinDate),
                const SizedBox(height: 20),
                _contactInfo(email, phone),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _professionalInfo(isMobile, qualification, specialization, experience, joinDate)),
                  const SizedBox(width: 20),
                  Expanded(child: _contactInfo(email, phone)),
                ]),
              const SizedBox(height: 20),
              if (!isHOD) _approvalChainInfo(chain),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildEditForm(DataService ds, Map<String, dynamic> fac, Map<String, String> chain) {
    final hodName = chain['hodName'] ?? 'HOD';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_note, color: AppColors.primary, size: 22), const SizedBox(width: 10),
          const Expanded(child: Text('Request Profile Edit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
          IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _showEditForm = false)),
        ]),
        const SizedBox(height: 6),
        Text('Changes sent to HOD ($hodName), then forwarded to Admin for approval.',
          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 12, children: [
          SizedBox(width: 280, child: _editField(_phoneCtrl, 'Phone Number', Icons.phone)),
          SizedBox(width: 280, child: _editField(_emailCtrl, 'Email', Icons.email)),
          SizedBox(width: 280, child: _editField(_qualifCtrl, 'Qualification', Icons.school)),
          SizedBox(width: 280, child: _editField(_specCtrl, 'Specialization', Icons.category)),
        ]),
        const SizedBox(height: 12),
        _editField(_reasonCtrl, 'Reason for change *', Icons.notes),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(
          onPressed: () => _submitFacultyRequest(ds, fac, chain),
          icon: const Icon(Icons.send, size: 16), label: const Text('Submit Request'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        )),
      ]),
    );
  }

  void _submitFacultyRequest(DataService ds, Map<String, dynamic> fac, Map<String, String> chain) {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason for the change')));
      return;
    }
    final changes = <String, Map<String, String>>{};
    final fields = {'phone': _phoneCtrl.text, 'email': _emailCtrl.text, 'qualification': _qualifCtrl.text, 'specialization': _specCtrl.text};
    for (final e in fields.entries) {
      final old = (fac[e.key] as String?) ?? '';
      if (e.value.trim() != old && e.value.trim().isNotEmpty) changes[e.key] = {'old': old, 'new': e.value.trim()};
    }
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No changes detected')));
      return;
    }
    ds.submitProfileEditRequest({
      'requesterId': fac['facultyId'], 'requesterName': fac['name'] ?? '', 'requesterRole': 'faculty',
      'departmentId': fac['departmentId'] ?? '', 'changes': changes, 'reason': _reasonCtrl.text.trim(),
      'status': 'pending_hod', 'currentApprover': 'hod',
      'approvalChain': [
        {'role': 'hod', 'approverId': chain['hodId'], 'approverName': chain['hodName'], 'status': 'pending', 'date': '', 'remarks': ''},
        {'role': 'admin', 'approverId': 'ADMIN', 'approverName': 'Admin', 'status': 'pending', 'date': '', 'remarks': ''},
      ],
    });
    setState(() => _showEditForm = false);
    final hName = chain['hodName'] ?? 'HOD';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit request submitted to HOD ($hName)'), backgroundColor: AppColors.secondary));
  }

  Widget _buildMyRequests(List<Map<String, dynamic>> requests) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history, color: AppColors.accent, size: 22), const SizedBox(width: 10),
          const Text('My Edit Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _showMyRequests = false)),
        ]),
        const SizedBox(height: 12),
        if (requests.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No edit requests yet', style: TextStyle(color: AppColors.textLight)))),
        ...requests.map((r) => _requestCard(r)),
      ]),
    );
  }

  Widget _requestCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? '';
    final color = status == 'approved' ? AppColors.secondary : status == 'rejected' ? Colors.red : AppColors.accent;
    final icon = status == 'approved' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.hourglass_top;
    final changes = (req['changes'] as Map<String, dynamic>?) ?? {};
    final chainList = (req['approvalChain'] as List<dynamic>?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18), const SizedBox(width: 8),
          Text(_statusLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Text(req['submittedDate'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        ...changes.entries.map((e) {
          final c = e.value as Map<String, dynamic>;
          final oldVal = c['old']?.toString() ?? '';
          final newVal = c['new']?.toString() ?? '';
          return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
            _tag(e.key, AppColors.primary), const SizedBox(width: 8),
            Text(oldVal, style: const TextStyle(color: AppColors.textLight, fontSize: 12, decoration: TextDecoration.lineThrough)),
            const Text(' > ', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
            Text(newVal, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
          ]));
        }),
        if ((req['reason'] ?? '').toString().isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('Reason: ${req["reason"]}', style: const TextStyle(color: AppColors.textMedium, fontSize: 12, fontStyle: FontStyle.italic))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: chainList.map((s) {
          final step = s as Map<String, dynamic>;
          final sc = step['status'] == 'approved' ? AppColors.secondary : step['status'] == 'rejected' ? Colors.red : AppColors.textLight;
          final si = step['status'] == 'approved' ? Icons.check : step['status'] == 'rejected' ? Icons.close : Icons.schedule;
          final stepRole = step['role']?.toString() ?? '';
          final stepStatus = step['status'] == 'pending' ? ' (pending)' : '';
          return Chip(avatar: Icon(si, size: 14, color: sc), label: Text('$stepRole$stepStatus', style: TextStyle(color: sc, fontSize: 11)),
            backgroundColor: sc.withValues(alpha: 0.08), side: BorderSide.none, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact);
        }).toList()),
      ]),
    );
  }

  Widget _approvalChainInfo(Map<String, String> chain) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.verified_user, color: AppColors.primary, size: 20), SizedBox(width: 8),
          Text('Edit Approval Chain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
        const SizedBox(height: 12),
        Row(children: [
          _chainStep('You', 'Faculty', AppColors.accent), _arrow(),
          _chainStep(chain['hodName'] ?? '-', 'HOD', AppColors.primary), _arrow(),
          _chainStep('Admin', 'Admin', AppColors.secondary),
        ]),
      ]),
    );
  }

  Widget _chainStep(String name, String role, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(role, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _arrow() => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textLight));

  String _statusLabel(String s) {
    switch (s) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'pending_hod': return 'Pending HOD Review';
      case 'pending_admin': return 'Pending Admin Review';
      default: return s;
    }
  }

  Widget _profileHeader(bool isMobile, String name, String initials, String facId, String dept, String designation, bool isHOD) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: AppCardStyles.elevated,
      child: isMobile
        ? Column(children: [
            CircleAvatar(radius: 50, backgroundColor: AppColors.primary, child: Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            if (isHOD) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: const Text('Head of Department', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(height: 4),
            Text(facId, style: const TextStyle(fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('$dept | $designation', style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
          ])
        : Row(children: [
            CircleAvatar(radius: 50, backgroundColor: AppColors.primary, child: Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                if (isHOD) ...[const SizedBox(width: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('HOD', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)))],
              ]),
              const SizedBox(height: 4),
              Text(facId, style: const TextStyle(fontSize: 16, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text('$dept | $designation', style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
            ]),
          ]),
    );
  }

  Widget _professionalInfo(bool isMobile, String qualification, String specialization, String experience, String joinDate) {
    final details = [
      if (qualification.isNotEmpty) {'label': 'Qualification', 'value': qualification},
      if (specialization.isNotEmpty) {'label': 'Specialization', 'value': specialization},
      if (experience.isNotEmpty) {'label': 'Experience', 'value': experience},
      if (joinDate.isNotEmpty) {'label': 'Joined', 'value': joinDate},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.work, color: AppColors.primary, size: 20), SizedBox(width: 8),
          Text('Professional Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
        const SizedBox(height: 16),
        ...details.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(width: isMobile ? 110 : 150, child: Text(d['label']!, style: const TextStyle(color: AppColors.textLight, fontSize: 14))),
            Flexible(child: Text(d['value']!, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
          ]),
        )),
      ]),
    );
  }

  Widget _contactInfo(String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.contact_mail, color: AppColors.primary, size: 20), SizedBox(width: 8),
          Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
        const SizedBox(height: 16),
        if (email.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [const Icon(Icons.email, color: AppColors.primary, size: 18), const SizedBox(width: 8),
            const Text('Email: ', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
            Flexible(child: Text(email, style: const TextStyle(color: AppColors.textDark, fontSize: 14)))])),
        if (phone.isNotEmpty) Row(children: [const Icon(Icons.phone, color: AppColors.primary, size: 18), const SizedBox(width: 8),
          const Text('Phone: ', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
          Text(phone, style: const TextStyle(color: AppColors.textDark, fontSize: 14))]),
      ]),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(controller: ctrl, style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18),
        labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13), filled: true, fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
      ));
  }

  Widget _tag(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), textStyle: const TextStyle(fontSize: 13)));
  }
}
