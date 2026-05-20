import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../shared/widgets/file_upload_widget.dart';

class FacultyAssignmentsPage extends StatefulWidget {
  const FacultyAssignmentsPage({super.key});

  @override
  State<FacultyAssignmentsPage> createState() => _FacultyAssignmentsPageState();
}

class _FacultyAssignmentsPageState extends State<FacultyAssignmentsPage> {

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final fid = ds.currentUserId ?? '';
      final facCourses = ds.getFacultyCourses(fid);
      final courseIds = facCourses.map((c) => c['courseId'] as String).toSet();
      final assignments = ds.assignments.where((a) => courseIds.contains(a['courseId'])).toList();
      assignments.sort((a, b) => (b['createdDate'] ?? '').compareTo(a['createdDate'] ?? ''));
      final pending = assignments.where((a) => a['status'] == 'pending').length;
      final submitted = assignments.where((a) => a['status'] == 'submitted').length;
      final graded = assignments.where((a) => a['status'] == 'graded').length;

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateAssignment(context, ds, facCourses),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Create Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.assignment_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('Assignments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3))),
              ]),
              const SizedBox(height: 24),
              // Stats
              if (isMobile)
                Column(children: [
                  Row(children: [
                    Expanded(child: _statCard('Total', '${assignments.length}', Icons.assignment_rounded, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Pending', '$pending', Icons.pending_rounded, const Color(0xFFF97316))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('Submitted', '$submitted', Icons.upload_file_rounded, const Color(0xFF06B6D4))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Graded', '$graded', Icons.grading_rounded, const Color(0xFF10B981))),
                  ]),
                ])
              else
                Row(children: [
                  Expanded(child: _statCard('Total', '${assignments.length}', Icons.assignment_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Pending', '$pending', Icons.pending_rounded, const Color(0xFFF97316))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Submitted', '$submitted', Icons.upload_file_rounded, const Color(0xFF06B6D4))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Graded', '$graded', Icons.grading_rounded, const Color(0xFF10B981))),
                ]),
              const SizedBox(height: 28),
              _buildAssignmentList(assignments, ds, isMobile),
            ]),
          );
        }),
      );
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.statCard(color),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildAssignmentList(List<Map<String, dynamic>> assignments, DataService ds, bool isMobile) {
    if (assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: AppCardStyles.elevated,
        child: Center(child: Column(children: [
          Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('No assignments yet', style: TextStyle(color: AppColors.textMedium, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Tap the + button to create one', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ])),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.list_alt_rounded, size: 18, color: AppColors.textMedium),
          const SizedBox(width: 8),
          const Text('Assignment List', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        ...assignments.asMap().entries.map((entry) {
          final a = entry.value;
          final status = (a['status'] as String?) ?? 'pending';
          final statusColor = status == 'graded' ? const Color(0xFF10B981)
              : status == 'submitted' ? const Color(0xFF06B6D4)
              : const Color(0xFFF97316);
          final title = a['title'] as String? ?? '';
          final courseId = a['courseId'] as String? ?? '';
          final dueDate = a['dueDate'] as String? ?? '-';
          final maxMarks = a['maxMarks']?.toString() ?? '-';
          final marks = a['marks']?.toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.15)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showAssignmentDetails(context, a, ds),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.assignment_rounded, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text('$courseId  •  Due: $dueDate  •  Max: $maxMarks', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    if (marks != null) ...[
                      const SizedBox(height: 2),
                      Text('Marks: $marks/$maxMarks', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  // Grade & delete actions
                  if (status == 'submitted')
                    IconButton(
                      icon: const Icon(Icons.grading_rounded, size: 18),
                      color: const Color(0xFF10B981),
                      tooltip: 'Grade',
                      onPressed: () => _showGradeDialog(context, a, ds),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        ds.deleteAssignment(a['assignmentId'] as String? ?? '');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment deleted'), backgroundColor: Color(0xFFF43F5E)));
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Row(children: [
                        Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                      ])),
                    ],
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                  ),
                ]),
              ),
            ),
          );
        }),
      ]),
    );
  }

  void _showAssignmentDetails(BuildContext context, Map<String, dynamic> a, DataService ds) {
    final status = (a['status'] as String?) ?? 'pending';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(a['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('${a['courseId'] ?? ''} — ${a['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textMedium, fontSize: 14)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('Due: ${a['dueDate'] ?? '-'}', const Color(0xFFF97316)),
            _chip('Max: ${a['maxMarks'] ?? '-'}', const Color(0xFF3B82F6)),
            _chip('Status: $status', status == 'graded' ? const Color(0xFF10B981) : status == 'submitted' ? const Color(0xFF06B6D4) : const Color(0xFFF97316)),
            if (a['marks'] != null) _chip('Marks: ${a['marks']}/${a['maxMarks'] ?? '-'}', const Color(0xFF10B981)),
            if (a['createdDate'] != null) _chip('Created: ${a['createdDate']}', AppColors.textMedium),
          ]),
          if (a['description'] != null && (a['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            Text(a['description'] as String, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
          ],
          if (a['feedback'] != null && (a['feedback'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Faculty Feedback', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
              ),
              child: Text(a['feedback'] as String, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
            ),
          ],
          if (a['submissionUrl'] != null) ...[
            const SizedBox(height: 16),
            const Text('Student Submission', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            FileLink(
              url: a['submissionUrl'] as String,
              fileName: a['submissionFileName'] as String? ?? 'Submission',
              format: a['submissionFormat'] as String?,
            ),
          ],
          if (a['referenceUrl'] != null) ...[
            const SizedBox(height: 16),
            const Text('Reference Material', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            FileLink(
              url: a['referenceUrl'] as String,
              fileName: a['referenceName'] as String? ?? 'Reference',
              format: a['referenceFormat'] as String?,
            ),
          ],
          const SizedBox(height: 20),
          // Action buttons
          Row(children: [
            if (status == 'submitted')
              Expanded(child: ElevatedButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); _showGradeDialog(context, a, ds); },
                icon: const Icon(Icons.grading_rounded, size: 16),
                label: const Text('Grade Submission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            if (status == 'submitted') const SizedBox(width: 12),
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  void _showGradeDialog(BuildContext context, Map<String, dynamic> a, DataService ds) {
    final marksCtrl = TextEditingController(text: a['marks']?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: a['feedback']?.toString() ?? '');
    final maxMarks = int.tryParse(a['maxMarks']?.toString() ?? '100') ?? 100;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.grading_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Grade Assignment', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background, borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.assignment_rounded, size: 16, color: AppColors.textMedium),
                const SizedBox(width: 8),
                Expanded(child: Text(a['title'] ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: marksCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Marks (out of $maxMarks)',
                labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Feedback (optional)',
                labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              final marks = int.tryParse(marksCtrl.text);
              if (marks == null || marks < 0 || marks > maxMarks) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Enter valid marks (0–$maxMarks)'),
                  backgroundColor: const Color(0xFFF43F5E),
                ));
                return;
              }
              ds.updateAssignment(a['assignmentId'] as String? ?? '', {
                'status': 'graded',
                'marks': marks,
                'feedback': feedbackCtrl.text.isNotEmpty ? feedbackCtrl.text : null,
                'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
                'gradedBy': ds.currentUserId ?? '',
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Graded: ${a['title']} — $marks/$maxMarks'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
              ));
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Save Grade'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  void _showCreateAssignment(BuildContext context, DataService ds, List<Map<String, dynamic>> courses) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxMarksCtrl = TextEditingController(text: '100');
    final dueDateCtrl = TextEditingController();
    String? selectedCourseId = courses.isNotEmpty ? courses.first['courseId'] as String : null;
    UploadResult? attachedFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Create Assignment', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCourseId,
                  decoration: _inputDeco('Course'),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                  items: courses.map((c) => DropdownMenuItem(value: c['courseId'] as String,
                    child: Text('${c['courseId']} - ${c['courseName']}'))).toList(),
                  onChanged: (v) => setDlgState(() => selectedCourseId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, style: const TextStyle(color: AppColors.textDark), maxLines: 3, decoration: _inputDeco('Description')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: maxMarksCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Max Marks'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: dueDateCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Due Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) dueDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                    },
                  )),
                ]),
                const SizedBox(height: 16),
                const Text('Reference Material (optional)', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(height: 8),
                if (attachedFile != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background, borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Icon(FileUploadService.getFileIcon(attachedFile!.format), color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(attachedFile!.originalName, style: const TextStyle(color: AppColors.textDark, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted), onPressed: () => setDlgState(() => attachedFile = null)),
                    ]),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final svc = FileUploadService();
                      final file = await svc.pickFile(accept: '.pdf,.doc,.docx,.ppt,.pptx,.jpg,.png');
                      if (file == null) return;
                      try {
                        final result = await svc.uploadFile(file, folder: 'ksrce/assignments/references');
                        setDlgState(() => attachedFile = result);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFF43F5E)));
                      }
                    },
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: const Text('Attach File'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (titleCtrl.text.isEmpty || selectedCourseId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Title and course are required'),
                    backgroundColor: Color(0xFFF43F5E),
                  ));
                  return;
                }
                final courseName = courses.firstWhere(
                  (c) => c['courseId'] == selectedCourseId,
                  orElse: () => <String, dynamic>{},
                )['courseName'] as String? ?? '';

                final assignment = <String, dynamic>{
                  'courseId': selectedCourseId,
                  'courseName': courseName,
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'maxMarks': int.tryParse(maxMarksCtrl.text) ?? 100,
                  'dueDate': dueDateCtrl.text.isNotEmpty ? dueDateCtrl.text : null,
                  'createdBy': ds.currentUserId ?? '',
                };
                if (attachedFile != null) {
                  assignment['referenceUrl'] = attachedFile!.url;
                  assignment['referenceName'] = attachedFile!.originalName;
                  assignment['referenceFormat'] = attachedFile!.format;
                }
                ds.addAssignment(assignment);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Assignment "${titleCtrl.text}" created!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}
