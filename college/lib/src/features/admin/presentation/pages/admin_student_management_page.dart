import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/delete_confirmation.dart';

class AdminStudentManagementPage extends StatefulWidget {
  const AdminStudentManagementPage({super.key});
  @override
  State<AdminStudentManagementPage> createState() => _AdminStudentManagementPageState();
}

class _AdminStudentManagementPageState extends State<AdminStudentManagementPage> {
  String _searchQuery = '';
  String? _filterYear;
  bool _isUploading = false;

  String _yearLabel(int? y) {
    switch (y) {
      case 1: return 'I Year';
      case 2: return 'II Year';
      case 3: return 'III Year';
      case 4: return 'IV Year';
      default: return 'Year $y';
    }
  }

  Color _yearColor(int? y) {
    switch (y) {
      case 1: return const Color(0xFF6C63FF);
      case 2: return const Color(0xFF00B4D8);
      case 3: return const Color(0xFF43AA8B);
      case 4: return const Color(0xFFFF6B6B);
      default: return AppColors.primary;
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _pickAndUploadExcel(DataService ds) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Could not read file data');
        return;
      }

      setState(() => _isUploading = true);

      final excelFile = excel_lib.Excel.decodeBytes(file.bytes!);
      if (excelFile.tables.isEmpty) {
        _showError('No sheets found in Excel file');
        setState(() => _isUploading = false);
        return;
      }

      final sheet = excelFile.tables[excelFile.tables.keys.first]!;
      if (sheet.rows.isEmpty) {
        _showError('Sheet is empty');
        setState(() => _isUploading = false);
        return;
      }

      int headerRowIndex = 0;
      for (int i = 0; i < sheet.rows.length; i++) {
        final rowStrs = sheet.rows[i].map((c) => c?.value?.toString().trim().toLowerCase() ?? '').toList();
        if (rowStrs.any((s) => s.contains('register number') || s.contains('roll no') || s.contains('name of the student'))) {
          headerRowIndex = i;
          break;
        }
      }

      final headers = sheet.rows[headerRowIndex].map((c) => c?.value?.toString().trim() ?? '').toList();
      final parsedStudents = <Map<String, dynamic>>[];

      for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.every((c) => c?.value == null || c!.value.toString().trim().isEmpty)) continue;

        final rowData = <String, String>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowData[headers[j]] = row[j]?.value?.toString().trim() ?? '';
        }

        String getF(List<String> aliases, [String fallback = '']) {
          for (final a in aliases) {
            for (final h in headers) {
              if (h.toLowerCase() == a.toLowerCase() && (rowData[h] ?? '').isNotEmpty) {
                return rowData[h]!;
              }
            }
          }
          // Substring matching as a smart fallback
          for (final a in aliases) {
            for (final h in headers) {
              if (h.toLowerCase().contains(a.toLowerCase()) && (rowData[h] ?? '').isNotEmpty) {
                return rowData[h]!;
              }
            }
          }
          return fallback;
        }

        // Broad case-insensitive list of common header patterns
        var regNo = getF([
          'register number', 'register no', 'reg no', 'reg. no', 'reg.no', 'regno',
          'roll no', 'roll number', 'roll. no', 'roll.no', 'rollno', 'roll_no'
        ]);

        // Smart Guess if empty: pick first cell that looks like a roll number/register number (contains numbers and letters)
        if (regNo.isEmpty) {
          for (final cell in row) {
            final val = cell?.value?.toString().trim() ?? '';
            if (val.length >= 5 && RegExp(r'[A-Za-z]').hasMatch(val) && RegExp(r'\d').hasMatch(val)) {
              regNo = val;
              break;
            }
          }
        }

        // Ultimate fallback: if still empty, pick column 0
        if (regNo.isEmpty && row.isNotEmpty) {
          regNo = row[0]?.value?.toString().trim() ?? '';
        }

        if (regNo.isEmpty) continue;

        var name = getF(['name of the student', 'student name', 'name', 'full name', 'full_name']);
        if (name.isEmpty && row.length > 1) {
          // Guess column 1 is Name
          name = row[1]?.value?.toString().trim() ?? 'Student';
        }

        final initial = getF(['initial of the student', 'initial']);
        if (initial.isNotEmpty && initial.toLowerCase() != 'nan') {
          name = '$name $initial'.trim();
        }

        var email = getF(['student domain email id', 'student personal mail', 'email', 'e-mail', 'email id']);
        if (email.isEmpty || email.toLowerCase() == 'nan') {
          email = '${regNo.toLowerCase()}@ksrce.ac.in';
        }

        var phone = getF(['student number', 'phone', 'mobile', 'contact']);
        if (phone.toLowerCase() == 'nan') phone = '';
        if (phone.endsWith('.0')) phone = phone.substring(0, phone.length - 2);

        var yearStr = getF(['year', 'semester', 'sem']);
        var dept = getF(['department', 'dept', 'branch']);
        var section = getF(['section', 'sec']);

        parsedStudents.add({
          "roll_number": regNo,
          "full_name": name,
          "email": email.toLowerCase(),
          "phone": phone,
          "department": dept.isNotEmpty ? dept : "CSE",
          "year": yearStr.isNotEmpty ? yearStr : "II",
          "section": section.isNotEmpty ? section : "A"
        });
      }

      if (parsedStudents.isEmpty) {
        _showError('No valid student records found in file. Please verify headers.');
        setState(() => _isUploading = false);
        return;
      }

      // Add locally to DataService
      int added = 0;
      int skipped = 0;
      for (final s in parsedStudents) {
        final roll = s['roll_number'];
        final exists = ds.students.any((existing) => existing['roll_no'] == roll);
        if (exists) {
          skipped++;
        } else {
          int yVal = 2;
          final ys = s['year']?.toString().toUpperCase() ?? '';
          if (ys.contains('I') || ys.contains('1')) {
            yVal = ys.contains('IV') || ys.contains('4') ? 4 : ys.contains('III') || ys.contains('3') ? 3 : ys.contains('II') || ys.contains('2') ? 2 : 1;
          } else {
            yVal = int.tryParse(ys) ?? 2;
          }
          final newStudent = {
            "studentId": "STU_${DateTime.now().millisecondsSinceEpoch}_$roll",
            "roll_no": roll,
            "name": s['full_name'],
            "email": s['email'],
            "phone": s['phone'],
            "departmentId": "DEPT_CSEIOT",
            "department_id": "DEPT_CSEIOT",
            "year": yVal,
            "section": s['section'] ?? "A",
            "cgpa": 8.0,
            "user_id": "std_${roll.toLowerCase()}",
            "created_at": DateTime.now().toIso8601String()
          };
          ds.students.add(newStudent);
          added++;
        }
      }

      setState(() => _isUploading = false);

      if (added > 0) {
        await ds.persistAll();
        ds.notifyListeners();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Successfully processed Excel file! Added $added, skipped $skipped duplicates.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('Error uploading: $e');
    }
  }

  void _showAddStudentDialog(BuildContext context, DataService ds) {
    final rollC = TextEditingController();
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final cgpaC = TextEditingController();
    String? selectedDeptId = ds.departments.isNotEmpty ? ds.departments[0]['departmentId'] as String : 'DEPT_003';
    String? selectedYear = '3';
    String? selectedSec = 'A';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Student Manually', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: rollC, decoration: const InputDecoration(labelText: 'Register / Roll Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Student Full Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDeptId,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                    items: ds.departments.map((d) => DropdownMenuItem(value: d['departmentId'] as String, child: Text('${d['departmentCode']} - ${d['departmentName']}', style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setS(() => selectedDeptId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: '1', child: Text('I Year')),
                            DropdownMenuItem(value: '2', child: Text('II Year')),
                            DropdownMenuItem(value: '3', child: Text('III Year')),
                            DropdownMenuItem(value: '4', child: Text('IV Year')),
                          ],
                          onChanged: (v) => setS(() => selectedYear = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSec,
                          decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('Section A')),
                            DropdownMenuItem(value: 'B', child: Text('Section B')),
                            DropdownMenuItem(value: 'C', child: Text('Section C')),
                          ],
                          onChanged: (v) => setS(() => selectedSec = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: cgpaC, decoration: const InputDecoration(labelText: 'Current CGPA', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                final roll = rollC.text.trim();
                final name = nameC.text.trim();
                if (roll.isEmpty || name.isEmpty) {
                  _showError('Roll number and Name are required!');
                  return;
                }
                
                final email = emailC.text.trim().isNotEmpty ? emailC.text.trim() : '${roll.toLowerCase()}@ksrce.ac.in';
                final phone = phoneC.text.trim();
                final cgpaVal = double.tryParse(cgpaC.text.trim()) ?? 8.0;

                final newStudent = {
                  "studentId": "STU_${DateTime.now().millisecondsSinceEpoch}_$roll",
                  "roll_no": roll,
                  "name": name,
                  "email": email,
                  "phone": phone,
                  "departmentId": selectedDeptId ?? "DEPT_003",
                  "department_id": selectedDeptId ?? "DEPT_003",
                  "year": int.tryParse(selectedYear ?? '3') ?? 3,
                  "section": selectedSec ?? "A",
                  "cgpa": cgpaVal,
                  "user_id": "std_${roll.toLowerCase()}",
                  "created_at": DateTime.now().toIso8601String()
                };

                ds.students.add(newStudent);
                ds.notifyListeners();
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Successfully added student $name manually!'),
                  backgroundColor: Colors.green,
                ));
              },
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Filter local students list
      final allStudents = ds.students;
      final filtered = allStudents.where((s) {
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final name = (s['name'] ?? '').toString().toLowerCase();
          final roll = (s['roll_no'] ?? '').toString().toLowerCase();
          final email = (s['email'] ?? '').toString().toLowerCase();
          if (!name.contains(q) && !roll.contains(q) && !email.contains(q)) return false;
        }
        if (_filterYear != null) {
          if ('${s['year']}' != _filterYear) return false;
        }
        return true;
      }).toList();

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 950;
          return Column(children: [
            // Header bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.group, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Student Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            Text(
                              '${filtered.length} of ${allStudents.length} students',
                              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                            ),
                          ])),
                        ]),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Student'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showAddStudentDialog(context, ds),
                            ),
                            if (_isUploading)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            else
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload_file, size: 16),
                                label: const Text('Upload Excel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _pickAndUploadExcel(ds),
                              ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export CSV'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: allStudents.isEmpty ? null : () => _showExportDialog(context, allStudents),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.group, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Student Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Text(
                          '${filtered.length} of ${allStudents.length} students',
                          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                      ])),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showAddStudentDialog(context, ds),
                      ),
                      const SizedBox(width: 10),
                      if (_isUploading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _pickAndUploadExcel(ds),
                        ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Export CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: allStudents.isEmpty ? null : () => _showExportDialog(context, allStudents),
                      ),
                    ]),
            ),

            // Search & filter bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
              color: AppColors.surface,
              child: Row(children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, roll no or email...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: AppColors.background,
                      filled: true,
                    ),
                    onChanged: (v) => setState(() { _searchQuery = v; }),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _filterYear,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: AppColors.background,
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Years')),
                      DropdownMenuItem(value: '1', child: Text('I Year')),
                      DropdownMenuItem(value: '2', child: Text('II Year')),
                      DropdownMenuItem(value: '3', child: Text('III Year')),
                      DropdownMenuItem(value: '4', child: Text('IV Year')),
                    ],
                    onChanged: (v) => setState(() { _filterYear = v; }),
                  ),
                ),
              ]),
            ),

            // Body
            Expanded(child: _buildBody(filtered, ds)),
          ]);
        }),
      );
    });
  }

  Widget _buildBody(List<Map<String, dynamic>> filtered, DataService ds) {
    if (filtered.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_search, size: 64, color: AppColors.textLight.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty || _filterYear != null
              ? 'No students match the filters'
              : 'No students found in database',
          style: const TextStyle(color: AppColors.textLight, fontSize: 15),
        ),
      ]));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 950;
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: AppColors.border,
                dataTableTheme: DataTableThemeData(
                  headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
                  dataRowColor: WidgetStateProperty.all(AppColors.surface),
                ),
              ),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 24,
                horizontalMargin: 24,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                dataTextStyle: const TextStyle(color: AppColors.textDark, fontSize: 13),
                columns: [
                  const DataColumn(label: Text('REG. NO.')),
                  const DataColumn(label: Text('STUDENT NAME')),
                  if (!isMobile) const DataColumn(label: Text('EMAIL ID')),
                  if (!isMobile) const DataColumn(label: Text('PHONE')),
                  const DataColumn(label: Text('DEPT')),
                  const DataColumn(label: Text('YEAR & SEC')),
                  if (!isMobile) const DataColumn(label: Text('CGPA')),
                  const DataColumn(label: Text('ACTIONS')),
                ],
                rows: filtered.map((s) {
                  final year = s['year'] as int?;
                  return DataRow(
                    cells: [
                      DataCell(Text((s['roll_no'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text((s['name'] ?? 'Unknown').toString())),
                      if (!isMobile) DataCell(Text((s['email'] ?? '').toString())),
                      if (!isMobile) DataCell(Text((s['phone'] ?? '').toString())),
                      DataCell(Text((s['department_id'] ?? '').toString().replaceAll('DEPT_', ''))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _yearColor(year).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text(year != null ? _yearLabel(year) : '—', style: TextStyle(color: _yearColor(year), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('Sec: ${(s['section'] ?? '').toString()}'),
                        ],
                      )),
                      if (!isMobile) DataCell(Text((s['cgpa'] ?? '-').toString())),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: AppColors.accent, size: 18),
                            tooltip: 'View Details',
                            onPressed: () => _showStudentDetails(context, s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            tooltip: 'Delete Student',
                            onPressed: () => _confirmDeleteStudent(context, ds, s['studentId'] ?? s['id'] ?? '', s['name'] ?? ''),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> s) {
    Widget row(String label, dynamic value) {
      final v = value?.toString() ?? '';
      if (v.isEmpty || v == 'null') return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );
    }

    final name = (s['name'] ?? 'Unknown').toString();
    final year = s['year'] as int?;
    final yColor = _yearColor(year);

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [yColor.withValues(alpha: 0.15), AppColors.surface]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: yColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(child: Text(
                  name.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase(),
                  style: TextStyle(color: yColor, fontWeight: FontWeight.bold, fontSize: 18),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text((s['roll_no'] ?? '').toString(), style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
              ])),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Academic', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Divider(),
              row('Register No', s['roll_no']),
              row('Department', (s['department_id'] ?? '').toString().replaceAll('DEPT_', '').replaceAll('_', ' ')),
              row('Year', year != null ? _yearLabel(year) : null),
              row('Section', s['section']),
              row('CGPA', s['cgpa']),
              const SizedBox(height: 12),
              const Text('Contact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Divider(),
              row('Email', s['email']),
              row('Phone', s['phone']),
              const SizedBox(height: 12),
              const Text('System', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Divider(),
              row('Student ID', s['studentId'] ?? s['id']),
              row('User ID', s['user_id']),
              row('Created', s['created_at']?.toString().substring(0, 10)),
            ]),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ]),
          ),
        ]),
      ),
    ));
  }

  void _showExportDialog(BuildContext context, List<Map<String, dynamic>> students) {
    final headers = ['roll_no', 'name', 'email', 'phone', 'department_id', 'year', 'section', 'cgpa'];
    final lines = <String>[headers.join(',')];
    for (final s in students) {
      lines.add(headers.map((h) => '"${(s[h] ?? '').toString().replaceAll('"', '""')}"').join(','));
    }
    final csv = lines.join('\n');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(children: [
        const Icon(Icons.table_view, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Export CSV (${students.length} students)'),
      ]),
      content: SizedBox(
        width: 600,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Copy and paste into Excel or Google Sheets.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
            child: SingleChildScrollView(
              child: SelectableText(csv, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11)),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy CSV'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (!context.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('CSV copied — ${students.length} students'),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
            ));
          },
        ),
      ],
    ));
  }

  void _confirmDeleteStudent(BuildContext context, DataService ds, String studentId, String name) {
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
            TextSpan(text: '$name ($studentId)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
              ds.deleteStudent(studentId);
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
}
