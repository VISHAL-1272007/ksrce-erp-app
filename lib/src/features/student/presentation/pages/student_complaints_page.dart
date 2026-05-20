// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/services/file_upload_service.dart';

class StudentComplaintsPage extends StatefulWidget {
  const StudentComplaintsPage({super.key});

  @override
  State<StudentComplaintsPage> createState() => _StudentComplaintsPageState();
}

class _StudentComplaintsPageState extends State<StudentComplaintsPage> {
  String _selectedCategory = 'infrastructure';
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final List<UploadResult> _attachedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded) {
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
      final complaintsList = ds.complaints;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.report_problem, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Complaints & Grievances', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              const Text('Submit and track your complaints', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              if (isMobile) ...[
                _buildComplaintsList(complaintsList),
                const SizedBox(height: 24),
                _buildNewComplaintForm(ds),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildComplaintsList(complaintsList)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildNewComplaintForm(ds)),
                ]),
            ]),
          );
        }),
      );
    });
  }

  Widget _buildComplaintsList(List<Map<String, dynamic>> complaintsList) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('My Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        if (complaintsList.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No complaints filed', style: TextStyle(color: AppColors.textLight))))
        else
          ...complaintsList.map((c) {
            final status = c['status'] as String? ?? 'pending';
            Color statusColor;
            IconData statusIcon;
            String statusLabel;
            switch (status) {
              case 'inProgress': statusColor = Colors.blue; statusIcon = Icons.autorenew; statusLabel = 'In Progress'; break;
              case 'resolved': statusColor = Colors.green; statusIcon = Icons.check_circle; statusLabel = 'Resolved'; break;
              default: statusColor = Colors.orange; statusIcon = Icons.hourglass_empty; statusLabel = 'Pending';
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(c['complaintId'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(c['title'] as String? ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(c['description'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(c['category'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today, color: AppColors.textLight, size: 14),
                  const SizedBox(width: 4),
                  Text(c['submittedDate'] as String? ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  if (c['response'] != null) ...[
                    const SizedBox(width: 12),
                    Flexible(child: Text('Response: ${c['response']}', style: const TextStyle(color: AppColors.secondary, fontSize: 11))),
                  ],
                ]),
                // Show attachments if any
                if (c['attachments'] != null && (c['attachments'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: (c['attachments'] as List).map((att) {
                    final a = att as Map<String, dynamic>;
                    return InkWell(
                      onTap: () => launchUrl(Uri.parse(a['url'] as String)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(FileUploadService.getFileIcon(a['format'] as String? ?? ''), size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(a['name'] as String? ?? 'File', style: const TextStyle(color: AppColors.primary, fontSize: 11, decoration: TextDecoration.underline)),
                          const SizedBox(width: 2),
                          const Icon(Icons.open_in_new, size: 10, color: AppColors.primary),
                        ]),
                      ),
                    );
                  }).toList()),
                ],
              ]),
            );
          }),
      ]),
    );
  }

  Widget _buildNewComplaintForm(DataService ds) {
    final categories = ['infrastructure', 'academic', 'library', 'hostel', 'transport', 'other'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('File New Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 20),
        const Text('Category', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: AppCardStyles.flat,
          child: DropdownButton<String>(
            value: _selectedCategory, isExpanded: true, dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textDark), underline: const SizedBox(),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Subject', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectController,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Brief subject of complaint', hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Description', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          style: const TextStyle(color: AppColors.textDark),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe your complaint in detail...', hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 16),
        // ── Attachment Section ──
        const Text('Attachments (optional)', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const SizedBox(height: 8),
        if (_attachedFiles.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: _attachedFiles.map((f) {
            return Chip(
              avatar: Icon(FileUploadService.getFileIcon(f.format), size: 16, color: AppColors.primary),
              label: Text(f.originalName, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => setState(() => _attachedFiles.remove(f)),
              backgroundColor: AppColors.background,
              side: BorderSide(color: AppColors.border),
            );
          }).toList()),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: () async {
            final service = FileUploadService();
            final file = await service.pickFile(accept: '.pdf,.doc,.docx,.jpg,.jpeg,.png,.gif');
            if (file == null) return;
            try {
              final result = await service.uploadFile(file, folder: 'ksrce/complaints');
              setState(() => _attachedFiles.add(result));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${result.originalName} attached'), backgroundColor: AppColors.secondary, duration: const Duration(seconds: 2)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
              );
            }
          },
          icon: const Icon(Icons.attach_file, size: 16),
          label: Text(_attachedFiles.isEmpty ? 'Attach Evidence' : 'Add More Files', style: const TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_subjectController.text.isNotEmpty && _descController.text.isNotEmpty) {
                final attachments = _attachedFiles.map((f) => {
                  'url': f.url,
                  'name': f.originalName,
                  'format': f.format,
                  'size': f.sizeBytes,
                }).toList();
                ds.addComplaint({
                  'title': _subjectController.text,
                  'description': _descController.text,
                  'category': _selectedCategory,
                  if (attachments.isNotEmpty) 'attachments': attachments,
                });
                // Also save to uploaded files
                for (final f in _attachedFiles) {
                  ds.addUploadedFile({
                    'url': f.url,
                    'originalName': f.originalName,
                    'format': f.format,
                    'sizeBytes': f.sizeBytes,
                    'category': 'complaints',
                    'uploadedBy': ds.currentUserId ?? '',
                  });
                }
                _subjectController.clear();
                _descController.clear();
                setState(() => _attachedFiles.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complaint submitted successfully!'), backgroundColor: AppColors.secondary),
                );
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Submit Complaint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),
    );
  }
}
