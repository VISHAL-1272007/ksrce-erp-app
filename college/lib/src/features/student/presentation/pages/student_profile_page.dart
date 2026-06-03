import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/services/file_upload_service.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});
  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _showEditForm = false;
  bool _showMyRequests = false;
  String? _profilePhotoUrl;
  bool _uploadingPhoto = false;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> student) {
    _phoneCtrl.text = (student['phone'] as String?) ?? '';
    _emailCtrl.text = (student['email'] as String?) ?? '';
    _addressCtrl.text = (student['address'] as String?) ?? '';
    _parentPhoneCtrl.text = (student['parentPhone'] as String?) ?? '';
    _bloodGroupCtrl.text = (student['bloodGroup'] as String?) ?? '';
    _reasonCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      final student = ds.currentStudent ?? {};
      final name = (student['name'] as String?) ?? 'Student';
      final rollNo = (student['studentId'] as String?) ?? ds.currentUserId ?? '';
      final regNo = (student['registerNumber'] as String?) ?? '';
      final dept = (student['department'] as String?) ?? '';
      final year = (student['year'] as String?) ?? '';
      final section = (student['section'] as String?) ?? '';
      final email = (student['email'] as String?) ?? '';
      final phone = (student['phone'] as String?) ?? '';
      final dob = (student['dateOfBirth'] as String?) ?? '';
      final bloodGroup = (student['bloodGroup'] as String?) ?? '';
      final address = (student['address'] as String?) ?? '';
      final parentName = (student['parentName'] as String?) ?? '';
      final parentPhone = (student['parentPhone'] as String?) ?? '';
      final cgpa = ds.currentCGPA;
      final batch = (student['batch'] as String?) ?? '';
      final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
      final myRequests = ds.getMyEditRequests(rollNo);
      final chain = ds.getStudentApprovalChain(rollNo);
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
                _actionBtn(Icons.edit, 'Edit Profile', AppColors.primary, () {
                  setState(() { _showEditForm = !_showEditForm; _showMyRequests = false; });
                  if (_showEditForm) _initControllers(student);
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
              ]),
              const SizedBox(height: 20),
              _profileHeader(isMobile, name, initials, rollNo, regNo, dept, year, section, batch),
              const SizedBox(height: 20),
              if (_showEditForm) ...[_buildEditForm(ds, student, chain), const SizedBox(height: 20)],
              if (_showMyRequests) ...[_buildMyRequests(myRequests), const SizedBox(height: 20)],
              if (isMobile) ...[
                _personalInfo(isMobile, dob, bloodGroup),
                const SizedBox(height: 20),
                _academicInfo(isMobile, rollNo, dept, year, cgpa),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _personalInfo(isMobile, dob, bloodGroup)),
                  const SizedBox(width: 20),
                  Expanded(child: _academicInfo(isMobile, rollNo, dept, year, cgpa)),
                ]),
              const SizedBox(height: 20),
              _contactInfo(email, phone, parentName, parentPhone, address),
              const SizedBox(height: 20),
              _mentorAdviserInfo(ds, rollNo),
              const SizedBox(height: 20),
              _approvalChainInfo(chain),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildEditForm(DataService ds, Map<String, dynamic> student, Map<String, String> chain) {
    final mentorName = chain['mentorName'] ?? 'Mentor';
    final adviserName = chain['classAdviserName'] ?? 'Class Adviser';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text('Request Profile Edit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
          IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _showEditForm = false)),
        ]),
        const SizedBox(height: 6),
        Text('Changes sent to Mentor ($mentorName), then forwarded to Class Adviser ($adviserName) for approval.',
          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 12, children: [
          SizedBox(width: 280, child: _editField(_phoneCtrl, 'Phone Number', Icons.phone)),
          SizedBox(width: 280, child: _editField(_emailCtrl, 'Email', Icons.email)),
          SizedBox(width: 280, child: _editField(_parentPhoneCtrl, 'Parent Phone', Icons.phone_in_talk)),
          SizedBox(width: 280, child: _editField(_bloodGroupCtrl, 'Blood Group', Icons.bloodtype)),
        ]),
        const SizedBox(height: 12),
        _editField(_addressCtrl, 'Address', Icons.location_on),
        const SizedBox(height: 12),
        _editField(_reasonCtrl, 'Reason for change *', Icons.notes),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(
          onPressed: () => _submitStudentRequest(ds, student, chain),
          icon: const Icon(Icons.send, size: 16), label: const Text('Submit Request'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        )),
      ]),
    );
  }

  void _submitStudentRequest(DataService ds, Map<String, dynamic> student, Map<String, String> chain) {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason for the change')));
      return;
    }
    final changes = <String, Map<String, String>>{};
    final fields = {'phone': _phoneCtrl.text, 'email': _emailCtrl.text, 'parentPhone': _parentPhoneCtrl.text, 'bloodGroup': _bloodGroupCtrl.text, 'address': _addressCtrl.text};
    for (final e in fields.entries) {
      final old = (student[e.key] as String?) ?? '';
      if (e.value.trim() != old && e.value.trim().isNotEmpty) changes[e.key] = {'old': old, 'new': e.value.trim()};
    }
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No changes detected')));
      return;
    }
    ds.submitProfileEditRequest({
      'requesterId': student['studentId'], 'requesterName': student['name'] ?? '', 'requesterRole': 'student',
      'departmentId': student['departmentId'] ?? '', 'changes': changes, 'reason': _reasonCtrl.text.trim(),
      'status': 'pending_mentor', 'currentApprover': 'mentor',
      'approvalChain': [
        {'role': 'mentor', 'approverId': chain['mentorId'], 'approverName': chain['mentorName'], 'status': 'pending', 'date': '', 'remarks': ''},
        {'role': 'classAdviser', 'approverId': chain['classAdviserId'], 'approverName': chain['classAdviserName'], 'status': 'pending', 'date': '', 'remarks': ''},
      ],
    });
    setState(() => _showEditForm = false);
    final mName = chain['mentorName'] ?? 'Mentor';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit request submitted to $mName'), backgroundColor: AppColors.secondary));
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

  Widget _mentorAdviserInfo(DataService ds, String studentId) {
    final mentor = ds.getStudentMentor(studentId);
    final adviser = ds.getStudentClassAdviser(studentId);

    if (mentor == null && adviser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.supervisor_account, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Mentor & Class Adviser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        if (mentor != null) _facultyInfoRow(
          mentor, 'Mentor', const Color(0xFF10B981), Icons.person_pin_rounded,
        ),
        if (mentor != null && adviser != null) const Divider(height: 24),
        if (adviser != null) _facultyInfoRow(
          adviser, 'Class Adviser', const Color(0xFF7C3AED), Icons.shield_rounded,
        ),
      ]),
    );
  }

  Widget _facultyInfoRow(Map<String, dynamic> fac, String role, Color color, IconData icon) {
    final name = fac['name'] as String? ?? role;
    final dept = fac['department'] as String? ?? fac['departmentId'] as String? ?? '';
    final phone = fac['phone'] as String? ?? '';
    final email = fac['email'] as String? ?? '';
    final designation = fac['designation'] as String? ?? '';
    final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: 0.1),
        child: Text(initials, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
          child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
        if (designation.isNotEmpty) Text(designation, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        if (dept.isNotEmpty) Text(dept, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(spacing: 14, runSpacing: 4, children: [
          if (phone.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.phone, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(phone, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
          ]),
          if (email.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.email, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(email, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
          ]),
        ]),
      ])),
    ]);
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
          _chainStep('You', 'Student', AppColors.accent), _arrow(),
          _chainStep(chain['mentorName'] ?? '-', 'Mentor', AppColors.primary), _arrow(),
          _chainStep(chain['classAdviserName'] ?? '-', 'Class Adviser', AppColors.secondary),
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
      case 'pending_mentor': return 'Pending Mentor Review';
      case 'pending_classAdviser': return 'Pending Class Adviser';
      default: return s;
    }
  }

  Widget _profileHeader(bool isMobile, String name, String initials, String rollNo, String regNo, String dept, String year, String section, String batch) {
    Widget avatarWidget = Stack(
      children: [
        _profilePhotoUrl != null
          ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(_profilePhotoUrl!))
          : CircleAvatar(radius: 50, backgroundColor: AppColors.accent, child: Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))),
        Positioned(
          bottom: 0, right: 0,
          child: InkWell(
            onTap: _uploadingPhoto ? null : _handlePhotoUpload,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: _uploadingPhoto
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: AppCardStyles.elevated,
      child: isMobile
        ? Column(children: [
            avatarWidget,
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            if (regNo.isNotEmpty) Text('Reg No: $regNo', style: const TextStyle(fontSize: 16, color: AppColors.accent)),
            if (regNo.isNotEmpty) const SizedBox(height: 2),
            Text('Roll No: $rollNo', style: TextStyle(fontSize: regNo.isNotEmpty ? 13 : 16, color: regNo.isNotEmpty ? AppColors.textMedium : AppColors.accent)),
            const SizedBox(height: 4),
            Text('$dept | Year $year | Sec $section${batch.isNotEmpty ? ' | $batch' : ''}', style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
          ])
        : Row(children: [
            avatarWidget,
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              if (regNo.isNotEmpty) Text('Register No: $regNo', style: const TextStyle(fontSize: 16, color: AppColors.accent)),
              if (regNo.isNotEmpty) const SizedBox(height: 2),
              Text('ID: $rollNo', style: TextStyle(fontSize: regNo.isNotEmpty ? 13 : 16, color: regNo.isNotEmpty ? AppColors.textMedium : AppColors.accent)),
              const SizedBox(height: 4),
              Text('$dept | Year $year | Section $section${batch.isNotEmpty ? ' | Batch $batch' : ''}', style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
            ]),
          ]),
    );
  }

  Future<void> _handlePhotoUpload() async {
    final service = FileUploadService();
    final file = await service.pickImage();
    if (file == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await service.uploadImageAndGetUrl(file, folder: 'ksrce/profiles');
      setState(() {
        _profilePhotoUrl = url;
        _uploadingPhoto = false;
      });
      final ds = Provider.of<DataService>(context, listen: false);
      ds.addUploadedFile({
        'url': url,
        'originalName': file.name,
        'format': file.name.split('.').last,
        'sizeBytes': file.size,
        'category': 'profile_photos',
        'uploadedBy': ds.currentUserId ?? '',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.secondary),
      );
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _personalInfo(bool isMobile, String dob, String bloodGroup) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final student = ds.currentStudent ?? {};
      final details = [
        {'label': 'Date of Birth', 'value': dob},
        {'label': 'Blood Group', 'value': bloodGroup},
        {'label': 'Gender', 'value': (student['gender'] as String?) ?? ''},
        {'label': 'Nationality', 'value': (student['nationality'] as String?) ?? ''},
        {'label': 'Religion', 'value': (student['religion'] as String?) ?? ''},
        {'label': 'Community', 'value': (student['community'] as String?) ?? ''},
        {'label': 'Mother Tongue', 'value': (student['motherTongue'] as String?) ?? ''},
        {'label': 'First Graduate', 'value': student['firstGraduate'] == true ? 'Yes' : ''},
        {'label': 'ID Mark 1', 'value': (student['identificationMark1'] as String?) ?? ''},
        {'label': 'ID Mark 2', 'value': (student['identificationMark2'] as String?) ?? ''},
      ];
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.person, color: AppColors.primary, size: 20), SizedBox(width: 8),
            Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
          const SizedBox(height: 16),
          ...details.where((d) => d['value']!.isNotEmpty).map((d) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: isMobile ? 110 : 150, child: Text(d['label']!, style: const TextStyle(color: AppColors.textLight, fontSize: 14))),
              Flexible(child: Text(d['value']!, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
            ]),
          )),
        ]),
      );
    });
  }

  Widget _academicInfo(bool isMobile, String rollNo, String dept, String year, double cgpa) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final student = ds.currentStudent ?? {};
      final cgpaStr = cgpa.toStringAsFixed(1);
      final details = [
        {'label': 'Register Number', 'value': (student['registerNumber'] as String?) ?? ''},
        {'label': 'Student ID', 'value': rollNo},
        {'label': 'Roll Number', 'value': (student['rollNumber'] as String?) ?? ''},
        {'label': 'Department', 'value': dept},
        {'label': 'Program', 'value': (student['programName'] as String?) ?? ''},
        {'label': 'Batch', 'value': (student['batch'] as String?) ?? ''},
        {'label': 'Regulation', 'value': (student['regulation'] as String?) ?? ''},
        {'label': 'Year', 'value': year},
        {'label': 'Semester', 'value': '${student['currentSemester'] ?? ''}'},
        {'label': 'Admission Type', 'value': (student['admissionType'] as String?) ?? ''},
        {'label': 'Admission Date', 'value': (student['admissionDate'] as String?) ?? ''},
        {'label': 'Lateral Entry', 'value': student['lateralEntry'] == true ? 'Yes' : ''},
        {'label': 'Current CGPA', 'value': cgpaStr},
        {'label': 'Arrears', 'value': '${student['arrearCount'] ?? ''}'.replaceAll('0', '')},
        {'label': 'Academic Status', 'value': (student['academicStatus'] as String?) ?? ''},
      ];
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppCardStyles.elevated,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.school, color: AppColors.primary, size: 20), SizedBox(width: 8),
            Text('Academic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
          const SizedBox(height: 16),
          ...details.where((d) => d['value']!.isNotEmpty && d['value'] != '0.0').map((d) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: isMobile ? 110 : 150, child: Text(d['label']!, style: const TextStyle(color: AppColors.textLight, fontSize: 14))),
              Flexible(child: Text(d['value']!, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
            ]),
          )),
        ]),
      );
    });
  }

  Widget _contactInfo(String email, String phone, String parentName, String parentPhone, String address) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final student = ds.currentStudent ?? {};
      final personalEmail = (student['personalEmail'] as String?) ?? '';
      final fatherName = (student['fatherName'] as String?) ?? '';
      final fatherPhone = (student['fatherPhone'] as String?) ?? '';
      final fatherOcc = (student['fatherOccupation'] as String?) ?? '';
      final motherName = (student['motherName'] as String?) ?? '';
      final motherPhone = (student['motherPhone'] as String?) ?? '';
      final motherOcc = (student['motherOccupation'] as String?) ?? '';
      final district = (student['permanentDistrict'] as String?) ?? '';
      final state = (student['permanentState'] as String?) ?? '';
      final pincode = (student['permanentPincode'] as String?) ?? '';
      final residence = (student['residenceType'] as String?) ?? '';
      final busNo = (student['busNo'] as String?) ?? '';
      final busStop = (student['busStop'] as String?) ?? '';
      final hostelRoom = (student['hostelRoomNo'] as String?) ?? '';

      return Column(children: [
        // Contact & Address
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCardStyles.elevated,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.contact_mail, color: AppColors.primary, size: 20), SizedBox(width: 8),
              Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
            const SizedBox(height: 16),
            ...[
              if (email.isNotEmpty) {'label': 'Domain Email', 'value': email, 'icon': Icons.email},
              if (personalEmail.isNotEmpty) {'label': 'Personal Email', 'value': personalEmail, 'icon': Icons.alternate_email},
              if (phone.isNotEmpty) {'label': 'Phone', 'value': phone, 'icon': Icons.phone},
              if (address.isNotEmpty) {'label': 'Address', 'value': address, 'icon': Icons.location_on},
              if (district.isNotEmpty) {'label': 'District', 'value': district, 'icon': Icons.map},
              if (state.isNotEmpty) {'label': 'State', 'value': state, 'icon': Icons.flag},
              if (pincode.isNotEmpty) {'label': 'Pincode', 'value': pincode, 'icon': Icons.pin_drop},
            ].map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
              Icon(d['icon'] as IconData, color: AppColors.primary, size: 18), const SizedBox(width: 8),
              Text('${d['label']}: ', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              Flexible(child: Text(d['value'] as String, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
            ]))),
          ]),
        ),
        const SizedBox(height: 20),

        // Family Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCardStyles.elevated,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.family_restroom, color: AppColors.primary, size: 20), SizedBox(width: 8),
              Text('Family Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
            const SizedBox(height: 16),
            ...[
              if (fatherName.isNotEmpty) {'label': 'Father', 'value': fatherName, 'icon': Icons.person_outline},
              if (fatherPhone.isNotEmpty) {'label': 'Father Phone', 'value': fatherPhone, 'icon': Icons.phone},
              if (fatherOcc.isNotEmpty) {'label': 'Father Occupation', 'value': fatherOcc, 'icon': Icons.work_outline},
              if (motherName.isNotEmpty) {'label': 'Mother', 'value': motherName, 'icon': Icons.person_outline},
              if (motherPhone.isNotEmpty) {'label': 'Mother Phone', 'value': motherPhone, 'icon': Icons.phone},
              if (motherOcc.isNotEmpty) {'label': 'Mother Occupation', 'value': motherOcc, 'icon': Icons.work_outline},
            ].map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
              Icon(d['icon'] as IconData, color: AppColors.primary, size: 18), const SizedBox(width: 8),
              Text('${d['label']}: ', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              Flexible(child: Text(d['value'] as String, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
            ]))),
          ]),
        ),
        const SizedBox(height: 20),

        // Accommodation
        if (residence.isNotEmpty) Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCardStyles.elevated,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.hotel, color: AppColors.primary, size: 20), SizedBox(width: 8),
              Text('Accommodation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
            const SizedBox(height: 16),
            ...[
              {'label': 'Residence Type', 'value': residence, 'icon': Icons.home_work},
              if (busNo.isNotEmpty) {'label': 'Bus Number', 'value': busNo, 'icon': Icons.directions_bus},
              if (busStop.isNotEmpty) {'label': 'Bus Stop', 'value': busStop, 'icon': Icons.location_on},
              if (hostelRoom.isNotEmpty) {'label': 'Hostel Room', 'value': hostelRoom, 'icon': Icons.meeting_room},
            ].map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
              Icon(d['icon'] as IconData, color: AppColors.primary, size: 18), const SizedBox(width: 8),
              Text('${d['label']}: ', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              Flexible(child: Text(d['value'] as String, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
            ]))),
          ]),
        ),
      ]);
    });
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
