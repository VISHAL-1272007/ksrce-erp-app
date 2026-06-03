import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../shared/widgets/file_upload_widget.dart';

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> _submittedFiles = {}; // assignmentId -> fileUrl

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAssignments(List<Map<String, dynamic>> all, String tab) {
    switch (tab) {
      case 'Pending': return all.where((a) => a['status'] == 'pending').toList();
      case 'Completed': return all.where((a) => a['status'] != 'pending').toList();
      default: return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final studentId = ds.currentUserId ?? '';
      final allAssignments = ds.getStudentAssignmentsFiltered(studentId);
      int pending = allAssignments.where((a) => a['status'] == 'pending').length;
      int submitted = allAssignments.where((a) => a['status'] == 'submitted').length;
      int evaluated = allAssignments.where((a) => a['status'] == 'evaluated' || a['status'] == 'late').length;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.assignment, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Assignments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Manage your assignments and submissions', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              _buildSummaryRow(isMobile, pending, submitted, evaluated, allAssignments.length),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textLight,
                  tabs: const [Tab(text: 'Pending'), Tab(text: 'Completed'), Tab(text: 'All')],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: ['Pending', 'Completed', 'All'].map((tab) {
                    final filtered = _filterAssignments(allAssignments, tab);
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No assignments found', style: TextStyle(color: AppColors.textLight)));
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildAssignmentCard(filtered[index], isMobile),
                    );
                  }).toList(),
                ),
              ),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildSummaryRow(bool isMobile, int pending, int submitted, int evaluated, int total) {
    final cards = [
      _summaryCard('Pending', '$pending', Colors.orange, Icons.hourglass_empty),
      _summaryCard('Submitted', '$submitted', Colors.blue, Icons.upload_file),
      _summaryCard('Evaluated', '$evaluated', Colors.green, Icons.grading),
      _summaryCard('Total', '$total', AppColors.accent, Icons.assignment),
    ];
    if (isMobile) {
      return Wrap(spacing: 12, runSpacing: 12, children: cards.map((c) => SizedBox(width: (MediaQuery.of(context).size.width - 44) / 2, child: c)).toList());
    }
    return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList());
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.raised,
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> a, bool isMobile) {
    final status = a['status'] as String? ?? 'pending';
    final assignmentId = a['assignmentId'] as String? ?? '';
    final hasSubmission = _submittedFiles.containsKey(assignmentId) || a['submissionUrl'] != null;
    Color statusColor = status == 'pending' ? Colors.orange : status == 'submitted' ? Colors.blue : status == 'late' ? Colors.redAccent : Colors.green;
    IconData statusIcon = status == 'pending' ? Icons.hourglass_empty : status == 'submitted' ? Icons.upload_file : Icons.check_circle;
    final statusLabel = status[0].toUpperCase() + status.substring(1);

    return InkWell(
      onTap: () => _showAssignmentDetails(a),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: status == 'pending' ? Colors.orange.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(a['title'] as String? ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15))),
            if (hasSubmission) ...[
              const Icon(Icons.attach_file, color: AppColors.secondary, size: 16),
              const SizedBox(width: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _iconText(Icons.book, '${a['courseCode'] ?? ''} - ${a['courseName'] ?? ''}'),
            _iconText(Icons.calendar_today, 'Due: ${a['dueDate'] ?? ''}'),
            if (a['obtainedMarks'] != null) _iconText(Icons.grade, 'Marks: ${a['obtainedMarks']}/${a['maxMarks'] ?? ''}'),
            if (a['feedback'] != null) _iconText(Icons.comment, a['feedback'] as String),
          ]),
          if (status == 'pending' && !hasSubmission)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: const [
                Icon(Icons.touch_app, color: AppColors.accent, size: 14),
                SizedBox(width: 4),
                Text('Tap to submit', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
        ]),
      ),
    );
  }

  void _showAssignmentDetails(Map<String, dynamic> a) {
    final status = a['status'] as String? ?? 'pending';
    final assignmentId = a['assignmentId'] as String? ?? '';
    final submittedUrl = _submittedFiles[assignmentId] ?? a['submissionUrl'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(a['title'] as String? ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('${a['courseCode'] ?? ''} - ${a['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textMedium, fontSize: 14)),
            const SizedBox(height: 12),
            if (a['description'] != null) ...[
              const Text('Description', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(a['description'] as String, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 16),
            ],
            Row(children: [
              _detailChip(Icons.calendar_today, 'Due: ${a['dueDate'] ?? '-'}', Colors.orange),
              const SizedBox(width: 8),
              _detailChip(Icons.grade, 'Max: ${a['maxMarks'] ?? '-'}', AppColors.primary),
              if (a['obtainedMarks'] != null) ...[
                const SizedBox(width: 8),
                _detailChip(Icons.check, 'Got: ${a['obtainedMarks']}', AppColors.secondary),
              ],
            ]),
            if (a['feedback'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.comment, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Feedback: ${a['feedback']}', style: const TextStyle(color: AppColors.textDark, fontSize: 13))),
                ]),
              ),
            ],
            // Show submitted file
            if (submittedUrl != null) ...[
              const SizedBox(height: 20),
              const Text('Submitted File', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              FileLink(
                url: submittedUrl,
                fileName: a['submissionFileName'] as String? ?? 'Submission',
                format: a['submissionFormat'] as String?,
              ),
            ],
            // Upload area for pending assignments
            if (status == 'pending' && submittedUrl == null) ...[
              const SizedBox(height: 20),
              const Text('Submit Assignment', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              FileUploadWidget(
                category: 'assignments',
                folder: 'ksrce/assignments/$assignmentId',
                accept: '.pdf,.doc,.docx,.ppt,.pptx,.zip,.rar,.jpg,.png,.txt',
                label: 'Upload your assignment',
                onUploaded: (result) {
                  final ds = Provider.of<DataService>(context, listen: false);
                  setState(() => _submittedFiles[assignmentId] = result.url);
                  // Update the assignment data
                  a['submissionUrl'] = result.url;
                  a['submissionFileName'] = result.originalName;
                  a['submissionFormat'] = result.format;
                  a['status'] = 'submitted';
                  // Save to uploaded files
                  ds.addUploadedFile({
                    'url': result.url,
                    'originalName': result.originalName,
                    'format': result.format,
                    'sizeBytes': result.sizeBytes,
                    'category': 'assignments',
                    'uploadedBy': ds.currentUserId ?? '',
                    'assignmentId': assignmentId,
                    'assignmentTitle': a['title'] ?? '',
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Assignment "${a['title']}" submitted successfully!'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textLight, size: 16),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
    ]);
  }
}
