import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/delete_confirmation.dart';
import '../../../../core/theme/app_colors.dart';

class AdminStudentManagementPage extends StatefulWidget {
  const AdminStudentManagementPage({super.key});
  @override
  State<AdminStudentManagementPage> createState() => _AdminStudentManagementPageState();
}

class _AdminStudentManagementPageState extends State<AdminStudentManagementPage> {
  String _searchQuery = '';
  String? _filterDept;
  String? _filterYear;
  static const List<String> _defaultCommunities = ['OC', 'BC', 'MBC', 'SC', 'ST'];

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      var allStudents = ds.students;

      // Apply filters
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        allStudents = allStudents.where((s) {
          final name = (s['name'] as String? ?? '').toLowerCase();
          final sid = (s['studentId'] as String? ?? '').toLowerCase();
          final reg = (s['registerNumber'] as String? ?? '').toLowerCase();
          return name.contains(q) || sid.contains(q) || reg.contains(q);
        }).toList();
      }
      if (_filterDept != null) allStudents = allStudents.where((s) => s['departmentId'] == _filterDept).toList();
      if (_filterYear != null) allStudents = allStudents.where((s) => '${s['year']}' == _filterYear).toList();

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.group_add, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Student Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: allStudents.isEmpty
                      ? null
                      : () => _showExportCsvDialog(context, allStudents),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18), label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _showStudentFormDialog(context, ds, null),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${allStudents.length} students enrolled', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 12),
              // Search & Filter Bar
              Wrap(spacing: 10, runSpacing: 10, children: [
                SizedBox(width: isMobile ? double.infinity : 280, child: TextField(
                  decoration: InputDecoration(hintText: 'Search by name, ID, or register no...', prefixIcon: const Icon(Icons.search, size: 18), isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )),
                SizedBox(width: 200, child: DropdownButtonFormField<String>(initialValue: _filterDept, isExpanded: true, isDense: true,
                  decoration: InputDecoration(labelText: 'Department', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: [const DropdownMenuItem(value: null, child: Text('All Depts')), ...ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text(d['departmentCode'] as String? ?? '', style: const TextStyle(fontSize: 13))))],
                  onChanged: (v) => setState(() => _filterDept = v),
                )),
                SizedBox(width: 120, child: DropdownButtonFormField<String>(initialValue: _filterYear, isExpanded: true, isDense: true,
                  decoration: InputDecoration(labelText: 'Year', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: '1', child: Text('1')), DropdownMenuItem(value: '2', child: Text('2')), DropdownMenuItem(value: '3', child: Text('3')), DropdownMenuItem(value: '4', child: Text('4'))],
                  onChanged: (v) => setState(() => _filterYear = v),
                )),
              ]),
              const SizedBox(height: 16),
              ...allStudents.map((s) {
                final deptCode = ds.getDepartmentCode(s['departmentId'] as String? ?? '');
                final sid = s['studentId'] as String? ?? '';
                final regNo = s['registerNumber'] as String? ?? '';
                final residence = s['residenceType'] as String? ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                      child: Text((s['name'] as String? ?? '?')[0], style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 14))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                      Text('$sid${regNo.isNotEmpty ? ' | Reg: $regNo' : ''} | $deptCode | Year ${s['year']} Sec ${s['section']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      if (residence.isNotEmpty) Text('$residence | CGPA: ${s['cgpa'] ?? 'N/A'}', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ])),
                    IconButton(icon: const Icon(Icons.visibility, size: 18, color: AppColors.accent), tooltip: 'View Details',
                      onPressed: () => _showStudentDetailsDialog(context, s)),
                    IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.primary), tooltip: 'Edit Student',
                      onPressed: () => _showStudentFormDialog(context, ds, s)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), tooltip: 'Delete Student',
                      onPressed: () => _confirmDeleteStudent(context, ds, sid, s['name'] as String? ?? '')),
                  ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  // ── Comprehensive Add / Edit Dialog with Tabs ──
  void _showStudentFormDialog(BuildContext context, DataService ds, Map<String, dynamic>? student) {
    final isEdit = student != null;
    final sid = student?['studentId'] as String? ?? '';
    String _s(String key) => (student?[key]?.toString()) ?? '';

    // Personal
    final nameC = TextEditingController(text: _s('name'));
    final dobC = TextEditingController(text: _s('dateOfBirth'));
    final bloodC = TextEditingController(text: _s('bloodGroup'));
    final nationalityC = TextEditingController(text: _s('nationality').isEmpty ? 'Indian' : _s('nationality'));
    final religionC = TextEditingController(text: _s('religion'));
    final communityC = TextEditingController(text: _s('community'));
    final List<String> communityOptions = [
      ..._defaultCommunities,
      ...(((ds.getSetting('communityOptions', _defaultCommunities) as List?) ?? const [])
        .map((e) => e.toString().trim().toUpperCase())
        .where((e) => e.isNotEmpty)),
    ].toSet().toList();
    communityOptions.sort();
    final existingCommunity = _s('community').trim().toUpperCase();
    String selectedCommunity = existingCommunity.isEmpty
      ? (communityOptions.isNotEmpty ? communityOptions.first : 'OC')
      : (communityOptions.contains(existingCommunity) ? existingCommunity : 'Others');
    final motherTongueC = TextEditingController(text: _s('motherTongue'));
    final idMark1C = TextEditingController(text: _s('identificationMark1'));
    final idMark2C = TextEditingController(text: _s('identificationMark2'));
    String gender = _s('gender').isEmpty ? 'Male' : _s('gender');
    bool firstGraduate = student?['firstGraduate'] == true;

    // Contact
    final emailC = TextEditingController(text: _s('email'));
    final personalEmailC = TextEditingController(text: _s('personalEmail'));
    final phoneC = TextEditingController(text: _s('phone'));
    final addressC = TextEditingController(text: _s('address'));
    final districtC = TextEditingController(text: _s('permanentDistrict'));
    final stateC = TextEditingController(text: _s('permanentState').isEmpty ? 'Tamil Nadu' : _s('permanentState'));
    final pincodeC = TextEditingController(text: _s('permanentPincode'));

    // Family
    final fatherNameC = TextEditingController(text: _s('fatherName'));
    final fatherPhoneC = TextEditingController(text: _s('fatherPhone'));
    final fatherOccC = TextEditingController(text: _s('fatherOccupation'));
    final fatherIncomeC = TextEditingController(text: _s('fatherAnnualIncome'));
    final motherNameC = TextEditingController(text: _s('motherName'));
    final motherPhoneC = TextEditingController(text: _s('motherPhone'));
    final motherOccC = TextEditingController(text: _s('motherOccupation'));
    final guardianNameC = TextEditingController(text: _s('guardianName'));
    final guardianPhoneC = TextEditingController(text: _s('guardianPhone'));

    // Academic
    final registerNoC = TextEditingController(text: _s('registerNumber'));
    final rollNoC = TextEditingController(text: _s('rollNumber'));
    String? selectedDeptId = student?['departmentId'] as String?;
    final yearC = TextEditingController(text: _s('year'));
    final sectionC = TextEditingController(text: _s('section'));
    final semesterC = TextEditingController(text: _s('currentSemester'));
    final batchC = TextEditingController(text: _s('batch'));
    final regulationC = TextEditingController(text: _s('regulation').isEmpty ? 'R2021' : _s('regulation'));
    final cgpaC = TextEditingController(text: _s('cgpa'));
    final arrearC = TextEditingController(text: _s('arrearCount'));
    String admissionType = _s('admissionType').isEmpty ? 'Counselling' : _s('admissionType');
    bool lateralEntry = student?['lateralEntry'] == true;

    // Previous Education
    final sslcSchoolC = TextEditingController(text: _s('sslcSchoolName'));
    final sslcBoardC = TextEditingController(text: _s('sslcBoard'));
    final sslcYearC = TextEditingController(text: _s('sslcYearOfPassing'));
    final sslcPctC = TextEditingController(text: _s('sslcPercentage'));
    final hscSchoolC = TextEditingController(text: _s('hscSchoolName'));
    final hscBoardC = TextEditingController(text: _s('hscBoard'));
    final hscYearC = TextEditingController(text: _s('hscYearOfPassing'));
    final hscPctC = TextEditingController(text: _s('hscPercentage'));
    final hscCutoffC = TextEditingController(text: _s('hscCutoffMark'));

    // Accommodation
    String residenceType = _s('residenceType').isEmpty ? 'Day Scholar' : _s('residenceType');
    final busNoC = TextEditingController(text: _s('busNo'));
    final busStopC = TextEditingController(text: _s('busStop'));
    final hostelRoomC = TextEditingController(text: _s('hostelRoomNo'));

    // Documents & Others
    final aadharC = TextEditingController(text: _s('aadharNumber'));
    final abcIdC = TextEditingController(text: _s('abcId'));
    final emisC = TextEditingController(text: _s('emisNumber'));
    final scholarshipNameC = TextEditingController(text: _s('scholarshipName'));
    final scholarshipStatusC = TextEditingController(text: _s('scholarshipStatus'));

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
      Widget _field(TextEditingController c, String label, {IconData? icon, TextInputType? keyType, int maxLines = 1, bool required = false}) {
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(
          controller: c, keyboardType: keyType, maxLines: maxLines,
          decoration: InputDecoration(labelText: required ? '$label *' : label, prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ));
      }

      Widget _row(List<Widget> children) => Padding(padding: const EdgeInsets.only(bottom: 0), child: Row(children: children.expand((w) => [Expanded(child: w), const SizedBox(width: 10)]).toList()..removeLast()));

      Widget _sectionLabel(String label, IconData icon) => Padding(padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(children: [Icon(icon, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary))]));

      // Tab contents
      final personalTab = SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        _sectionLabel('Basic Information', Icons.person),
        _field(nameC, 'Full Name', icon: Icons.person_outline, required: true),
        _row([
          Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(initialValue: gender, isDense: true,
            decoration: InputDecoration(labelText: 'Gender *', prefixIcon: const Icon(Icons.wc, size: 18), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setS(() => gender = v!))),
          _field(dobC, 'Date of Birth (YYYY-MM-DD)', icon: Icons.cake_outlined),
        ]),
        _row([_field(bloodC, 'Blood Group', icon: Icons.bloodtype_outlined), _field(nationalityC, 'Nationality')]),
        _row([
          _field(religionC, 'Religion'),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DropdownButtonFormField<String>(
              initialValue: selectedCommunity,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Community',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                ...communityOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                const DropdownMenuItem(value: 'Others', child: Text('Others')),
              ],
              onChanged: (v) => setS(() {
                selectedCommunity = v ?? selectedCommunity;
                if (selectedCommunity != 'Others') {
                  communityC.text = selectedCommunity;
                }
              }),
            ),
          ),
        ]),
        if (selectedCommunity == 'Others')
          _field(communityC, 'Type Community Name', required: true),
        _row([_field(motherTongueC, 'Mother Tongue'), Padding(padding: const EdgeInsets.only(bottom: 10), child: CheckboxListTile(
          title: const Text('First Graduate', style: TextStyle(fontSize: 13)), value: firstGraduate, dense: true, contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading, onChanged: (v) => setS(() => firstGraduate = v!)))]),
        _field(idMark1C, 'Identification Mark 1'), _field(idMark2C, 'Identification Mark 2'),
      ]));

      final contactTab = SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        _sectionLabel('Contact Details', Icons.contact_mail),
        _row([_field(emailC, 'Domain Email', icon: Icons.email_outlined), _field(personalEmailC, 'Personal Email', icon: Icons.alternate_email)]),
        _field(phoneC, 'Phone Number', icon: Icons.phone_outlined, keyType: TextInputType.phone),
        _field(addressC, 'Address', icon: Icons.home_outlined, maxLines: 2),
        _row([_field(districtC, 'District'), _field(stateC, 'State')]),
        _field(pincodeC, 'Pincode', keyType: TextInputType.number),
        _sectionLabel('Family Information', Icons.family_restroom),
        _row([_field(fatherNameC, 'Father Name'), _field(fatherPhoneC, 'Father Phone', keyType: TextInputType.phone)]),
        _row([_field(fatherOccC, 'Father Occupation'), _field(fatherIncomeC, 'Annual Income', keyType: TextInputType.number)]),
        _row([_field(motherNameC, 'Mother Name'), _field(motherPhoneC, 'Mother Phone', keyType: TextInputType.phone)]),
        _field(motherOccC, 'Mother Occupation'),
        _row([_field(guardianNameC, 'Guardian Name (if any)'), _field(guardianPhoneC, 'Guardian Phone', keyType: TextInputType.phone)]),
      ]));

      final academicTab = SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        _sectionLabel('Current Academic Details', Icons.school),
        _row([_field(registerNoC, 'Register Number', icon: Icons.badge_outlined), _field(rollNoC, 'Roll Number')]),
        _row([
          Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(initialValue: selectedDeptId, isExpanded: true, isDense: true,
            decoration: InputDecoration(labelText: 'Department *', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            items: ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text('${d['departmentCode']}', style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => selectedDeptId = v))),
          _field(batchC, 'Batch (e.g. 2021-2025)'),
        ]),
        _row([_field(yearC, 'Year', keyType: TextInputType.number, required: true), _field(sectionC, 'Section', required: true), _field(semesterC, 'Semester', keyType: TextInputType.number)]),
        _row([_field(regulationC, 'Regulation'), Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(initialValue: admissionType, isDense: true,
          decoration: InputDecoration(labelText: 'Admission Type', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          items: ['Counselling', 'Management', 'Sports Quota', 'NRI'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: (v) => setS(() => admissionType = v!)))]),
        _row([_field(cgpaC, 'CGPA', icon: Icons.grade_outlined, keyType: TextInputType.number), _field(arrearC, 'Arrear Count', keyType: TextInputType.number)]),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: CheckboxListTile(
          title: const Text('Lateral Entry', style: TextStyle(fontSize: 13)), value: lateralEntry, dense: true, contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading, onChanged: (v) => setS(() => lateralEntry = v!))),
        _sectionLabel('Previous Education', Icons.history_edu),
        const Text('SSLC / 10th', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        _field(sslcSchoolC, 'School Name'), _row([_field(sslcBoardC, 'Board'), _field(sslcYearC, 'Year of Passing', keyType: TextInputType.number), _field(sslcPctC, 'Percentage', keyType: TextInputType.number)]),
        const SizedBox(height: 6),
        const Text('HSC / 12th', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        _field(hscSchoolC, 'School Name'), _row([_field(hscBoardC, 'Board'), _field(hscYearC, 'Year of Passing', keyType: TextInputType.number)]),
        _row([_field(hscPctC, 'Percentage', keyType: TextInputType.number), _field(hscCutoffC, 'Cutoff Mark', keyType: TextInputType.number)]),
      ]));

      final accommodationTab = SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        _sectionLabel('Accommodation', Icons.hotel),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(initialValue: residenceType, isDense: true,
          decoration: InputDecoration(labelText: 'Residence Type *', prefixIcon: const Icon(Icons.home_work, size: 18), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          items: ['Day Scholar', 'Hosteller'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setS(() => residenceType = v!))),
        if (residenceType == 'Day Scholar') ...[
          _sectionLabel('Transport Details', Icons.directions_bus),
          _row([_field(busNoC, 'Bus Number', icon: Icons.directions_bus_outlined), _field(busStopC, 'Bus Stop', icon: Icons.location_on_outlined)]),
        ],
        if (residenceType == 'Hosteller') ...[
          _sectionLabel('Hostel Details', Icons.apartment),
          _field(hostelRoomC, 'Hostel Room No', icon: Icons.meeting_room_outlined),
        ],
        _sectionLabel('Documents & IDs', Icons.badge),
        _field(aadharC, 'Aadhar Number', icon: Icons.credit_card),
        _row([_field(abcIdC, 'ABC ID'), _field(emisC, 'EMIS Number')]),
        _sectionLabel('Scholarship', Icons.school_outlined),
        _row([_field(scholarshipNameC, 'Scholarship Name'), _field(scholarshipStatusC, 'Status')]),
      ]));

      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750, maxHeight: 650),
          child: DefaultTabController(length: 4, child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(children: [
                Icon(isEdit ? Icons.edit : Icons.person_add, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(isEdit ? 'Edit Student — $sid' : 'Add New Student', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            // Tabs
            const TabBar(
              labelColor: AppColors.primary, unselectedLabelColor: AppColors.textLight, indicatorColor: AppColors.primary,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), isScrollable: false,
              tabs: [Tab(text: 'Personal'), Tab(text: 'Contact & Family'), Tab(text: 'Academic'), Tab(text: 'Accommodation')],
            ),
            // Tab content
            Expanded(child: TabBarView(children: [personalTab, contactTab, academicTab, accommodationTab])),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(isEdit ? Icons.save : Icons.person_add, size: 18),
                  label: Text(isEdit ? 'Save Changes' : 'Enroll Student'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: () async {
                    if (nameC.text.isEmpty || selectedDeptId == null || yearC.text.isEmpty || sectionC.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields: Name, Department, Year, Section'), backgroundColor: Colors.red));
                      return;
                    }
                    final manualCommunity = communityC.text.trim().toUpperCase();
                    final resolvedCommunity = selectedCommunity == 'Others' ? manualCommunity : selectedCommunity;
                    if (resolvedCommunity.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose or enter a community'), backgroundColor: Colors.red));
                      return;
                    }

                    final isNewCommunity = !communityOptions.contains(resolvedCommunity);
                    if (isNewCommunity) {
                      final addNew = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('New Community Found'),
                          content: Text('"$resolvedCommunity" is not in the community dropdown. Add it for future students?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Not Now')),
                            ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Add Community')),
                          ],
                        ),
                      );

                      if (addNew == true) {
                        final updated = [...communityOptions, resolvedCommunity].toSet().toList()..sort();
                        ds.updateSetting('communityOptions', updated);
                        ds.addNotification({
                          'title': 'Community Master Updated',
                          'message': 'New community "$resolvedCommunity" was added to the student form dropdown.',
                          'recipientRole': 'admin',
                          'type': 'config_update',
                        });
                      } else {
                        ds.addNotification({
                          'title': 'Community Review Needed',
                          'message': 'Student "${nameC.text}" used new community "$resolvedCommunity". Review and add to dropdown if needed.',
                          'recipientRole': 'admin',
                          'type': 'config_review',
                        });
                      }
                    }

                    final data = <String, dynamic>{
                      'name': nameC.text, 'gender': gender, 'dateOfBirth': dobC.text, 'bloodGroup': bloodC.text,
                      'nationality': nationalityC.text, 'religion': religionC.text, 'community': resolvedCommunity,
                      'motherTongue': motherTongueC.text, 'identificationMark1': idMark1C.text, 'identificationMark2': idMark2C.text,
                      'firstGraduate': firstGraduate,
                      'email': emailC.text, 'personalEmail': personalEmailC.text, 'phone': phoneC.text,
                      'address': addressC.text, 'permanentDistrict': districtC.text, 'permanentState': stateC.text, 'permanentPincode': pincodeC.text,
                      'fatherName': fatherNameC.text, 'fatherPhone': fatherPhoneC.text, 'fatherOccupation': fatherOccC.text,
                      'fatherAnnualIncome': int.tryParse(fatherIncomeC.text) ?? 0,
                      'motherName': motherNameC.text, 'motherPhone': motherPhoneC.text, 'motherOccupation': motherOccC.text,
                      'guardianName': guardianNameC.text, 'guardianPhone': guardianPhoneC.text,
                      'parentName': fatherNameC.text, 'parentPhone': fatherPhoneC.text,
                      'registerNumber': registerNoC.text, 'rollNumber': rollNoC.text,
                      'departmentId': selectedDeptId, 'department': ds.getDepartmentName(selectedDeptId!),
                      'programName': 'B.E.', 'regulation': regulationC.text, 'batch': batchC.text,
                      'year': yearC.text, 'section': sectionC.text.toUpperCase(),
                      'currentSemester': int.tryParse(semesterC.text) ?? 1,
                      'admissionType': admissionType, 'lateralEntry': lateralEntry,
                      'cgpa': double.tryParse(cgpaC.text) ?? 0.0, 'arrearCount': int.tryParse(arrearC.text) ?? 0,
                      'sslcSchoolName': sslcSchoolC.text, 'sslcBoard': sslcBoardC.text,
                      'sslcYearOfPassing': int.tryParse(sslcYearC.text) ?? 0, 'sslcPercentage': double.tryParse(sslcPctC.text) ?? 0.0,
                      'hscSchoolName': hscSchoolC.text, 'hscBoard': hscBoardC.text,
                      'hscYearOfPassing': int.tryParse(hscYearC.text) ?? 0, 'hscPercentage': double.tryParse(hscPctC.text) ?? 0.0,
                      'hscCutoffMark': double.tryParse(hscCutoffC.text) ?? 0.0,
                      'residenceType': residenceType, 'busNo': busNoC.text, 'busStop': busStopC.text, 'hostelRoomNo': hostelRoomC.text,
                      'aadharNumber': aadharC.text, 'abcId': abcIdC.text, 'emisNumber': emisC.text,
                      'scholarshipName': scholarshipNameC.text, 'scholarshipStatus': scholarshipStatusC.text,
                    };
                    if (!isEdit) {
                      data['admissionDate'] = DateTime.now().toIso8601String().substring(0, 10);
                      data['academicStatus'] = 'Active';
                      data['placementWilling'] = true;
                      data['placementStatus'] = 'Not Placed';
                      data['skillSet'] = <String>[];
                      data['enrolledCourses'] = <String>[];
                    }
                    if (isEdit) { ds.updateStudent(sid, data); } else { ds.addStudent(data); }
                    Navigator.pop(ctx); setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isEdit ? '${nameC.text} updated successfully' : '${nameC.text} enrolled successfully'),
                      backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
                  },
                ),
              ]),
            ),
          ])),
        ),
      );
    }));
  }

  // ── View Details Dialog ──
  void _showStudentDetailsDialog(BuildContext context, Map<String, dynamic> s) {
    Widget _row(String label, dynamic value) {
      final v = value?.toString() ?? '';
      if (v.isEmpty || v == '0' || v == '0.0' || v == 'null') return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 160, child: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13))),
        Expanded(child: Text(v, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
      ]));
    }
    Widget _section(String title, IconData icon, List<Widget> rows) {
      final filtered = rows.where((w) => w is! SizedBox).toList();
      if (filtered.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 14),
        Row(children: [Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary))]),
        const Divider(height: 12),
        ...filtered,
      ]);
    }

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(16), child: Row(children: [
          const Icon(Icons.person, color: AppColors.primary), const SizedBox(width: 10),
          Expanded(child: Text('${s['name']} — ${s['studentId']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
        ])),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('Personal', Icons.person, [_row('Gender', s['gender']), _row('Date of Birth', s['dateOfBirth']), _row('Blood Group', s['bloodGroup']),
            _row('Nationality', s['nationality']), _row('Religion', s['religion']), _row('Community', s['community']),
            _row('Mother Tongue', s['motherTongue']), _row('First Graduate', s['firstGraduate'] == true ? 'Yes' : ''),
            _row('ID Mark 1', s['identificationMark1']), _row('ID Mark 2', s['identificationMark2'])]),
          _section('Contact', Icons.contact_mail, [_row('Domain Email', s['email']), _row('Personal Email', s['personalEmail']), _row('Phone', s['phone']),
            _row('Address', s['address']), _row('District', s['permanentDistrict']), _row('State', s['permanentState']), _row('Pincode', s['permanentPincode'])]),
          _section('Family', Icons.family_restroom, [_row('Father Name', s['fatherName']), _row('Father Phone', s['fatherPhone']),
            _row('Father Occupation', s['fatherOccupation']), _row('Annual Income', s['fatherAnnualIncome']),
            _row('Mother Name', s['motherName']), _row('Mother Phone', s['motherPhone']), _row('Mother Occupation', s['motherOccupation']),
            _row('Guardian Name', s['guardianName']), _row('Guardian Phone', s['guardianPhone'])]),
          _section('Academic', Icons.school, [_row('Register Number', s['registerNumber']), _row('Roll Number', s['rollNumber']),
            _row('Department', s['department']), _row('Program', s['programName']),
            _row('Batch', s['batch']), _row('Year', s['year']), _row('Section', s['section']), _row('Semester', s['currentSemester']),
            _row('Regulation', s['regulation']), _row('Admission Date', s['admissionDate']), _row('Admission Type', s['admissionType']),
            _row('Lateral Entry', s['lateralEntry'] == true ? 'Yes' : ''), _row('CGPA', s['cgpa']), _row('Arrears', s['arrearCount']),
            _row('Academic Status', s['academicStatus'])]),
          _section('Previous Education', Icons.history_edu, [
            _row('SSLC School', s['sslcSchoolName']), _row('SSLC Board', s['sslcBoard']), _row('SSLC Year', s['sslcYearOfPassing']), _row('SSLC %', s['sslcPercentage']),
            _row('HSC School', s['hscSchoolName']), _row('HSC Board', s['hscBoard']), _row('HSC Year', s['hscYearOfPassing']), _row('HSC %', s['hscPercentage']), _row('HSC Cutoff', s['hscCutoffMark'])]),
          _section('Accommodation', Icons.hotel, [_row('Residence Type', s['residenceType']),
            _row('Bus No', s['busNo']), _row('Bus Stop', s['busStop']), _row('Hostel Room', s['hostelRoomNo'])]),
          _section('Documents', Icons.badge, [_row('Aadhar Number', s['aadharNumber']), _row('ABC ID', s['abcId']), _row('EMIS Number', s['emisNumber']),
            _row('Scholarship', s['scholarshipName']), _row('Scholarship Status', s['scholarshipStatus'])]),
          const SizedBox(height: 16),
        ]))),
      ])),
    ));
  }

  void _confirmDeleteStudent(BuildContext context, DataService ds, String sid, String name) {
    final confirmC = TextEditingController();
    final expectedText = buildDeleteConfirmationText(name);
    bool isValid = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text('Delete Student', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(style: const TextStyle(color: AppColors.textMedium, fontSize: 14), children: [
            const TextSpan(text: 'You are about to permanently delete '),
            TextSpan(text: '$name ($sid)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const TextSpan(text: '. This action cannot be undone.\n\n'),
            const TextSpan(text: 'To confirm, type: ', style: TextStyle(fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Text(expectedText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmC,
            decoration: InputDecoration(
              labelText: 'Type confirmation text',
              prefixIcon: const Icon(Icons.keyboard, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isValid ? Colors.green : AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isValid ? Colors.green : AppColors.primary, width: 2)),
            ),
            onChanged: (v) => setS(() => isValid = isDeleteConfirmationValid(entityName: name, userInput: v)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isValid ? Colors.red : Colors.grey, foregroundColor: Colors.white),
            onPressed: isValid ? () {
              ds.deleteStudent(sid);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$name deleted permanently'), backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
            } : null,
            child: const Text('Delete Permanently'),
          ),
        ],
      );
    }));
  }

  String _csvEscape(dynamic value) {
    final raw = (value ?? '').toString();
    final escaped = raw.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _buildStudentsCsv(List<Map<String, dynamic>> students) {
    final headers = <String>[
      'studentId',
      'name',
      'registerNumber',
      'departmentId',
      'year',
      'section',
      'email',
      'phone',
      'cgpa',
      'academicStatus',
    ];

    final lines = <String>[headers.map(_csvEscape).join(',')];
    for (final s in students) {
      final row = headers.map((h) => _csvEscape(s[h])).join(',');
      lines.add(row);
    }
    return lines.join('\n');
  }

  void _showExportCsvDialog(
    BuildContext context,
    List<Map<String, dynamic>> students,
  ) {
    final csv = _buildStudentsCsv(students);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.table_view, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Export CSV (${students.length} students)'),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this CSV and paste into Excel / Google Sheets.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'CSV copied (${students.length} students). Paste into Excel/Sheets.',
                  ),
                  backgroundColor: AppColors.secondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
