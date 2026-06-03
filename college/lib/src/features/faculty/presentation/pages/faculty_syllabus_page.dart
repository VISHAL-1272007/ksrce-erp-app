import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../shared/widgets/file_upload_widget.dart';

class FacultySyllabusPage extends StatefulWidget {
  const FacultySyllabusPage({super.key});

  @override
  State<FacultySyllabusPage> createState() => _FacultySyllabusPageState();
}

class _FacultySyllabusPageState extends State<FacultySyllabusPage> {
  final Map<String, String> _uploadedSyllabus = {}; // courseId -> url
  final Map<String, String> _uploadedNames = {};    // courseId -> fileName

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final syllabi = ds.getFacultySyllabus(fid);
      final courses = ds.getFacultyCourses(fid);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.menu_book, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text('Syllabus Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 8),
            Text('${courses.length} courses | ${syllabi.length} syllabi uploaded', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
            const SizedBox(height: 24),
            if (syllabi.isEmpty && courses.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No courses assigned', style: TextStyle(color: AppColors.textLight, fontSize: 16)))),
            ...courses.map((course) {
              final cid = course['courseId'] ?? '';
              final courseSyl = syllabi.where((s) => s['courseId'] == cid).toList();
              if (courseSyl.isEmpty) {
                final hasUpload = _uploadedSyllabus.containsKey(cid);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: AppCardStyles.elevated,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('$cid - ${course['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold))),
                      if (!hasUpload)
                        ElevatedButton.icon(
                          onPressed: () => _showUploadDialog(context, ds, cid, course['courseName'] ?? ''),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload Syllabus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ]),
                    if (hasUpload) ...[
                      const SizedBox(height: 10),
                      FileLink(
                        url: _uploadedSyllabus[cid]!,
                        fileName: _uploadedNames[cid] ?? 'Syllabus PDF',
                        format: 'pdf',
                      ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Syllabus not uploaded', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ),
                  ]),
                );
              }
              final syl = courseSyl.first;
              final units = (syl['units'] as List<dynamic>?) ?? [];
              final progress = ds.getSyllabusProgress(syl);
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: AppCardStyles.elevated,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('$cid - ${course['courseName'] ?? syl['courseName'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('${progress.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress / 100, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                  const SizedBox(height: 16),
                  ...units.map((u) {
                    final totalH = (u['totalHours'] as int?) ?? 1;
                    final compH = (u['completedHours'] as int?) ?? 0;
                    final unitProg = totalH > 0 ? compH / totalH : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text('Unit ${u['unitNumber'] ?? '-'}: ${u['title'] ?? ''}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14))),
                          Text('$compH/$totalH hrs', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                        ]),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: unitProg, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(unitProg >= 1.0 ? Colors.green : AppColors.accent)),
                      ]),
                    );
                  }),
                ]),
              );
            }),
          ]),
        ),
      );
    });
  }

  void _showUploadDialog(BuildContext context, DataService ds, String courseId, String courseName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Upload Syllabus — $courseId', style: const TextStyle(color: AppColors.textDark, fontSize: 18)),
        content: SizedBox(
          width: 400,
          child: FileUploadWidget(
            category: 'syllabus',
            folder: 'ksrce/syllabus/$courseId',
            accept: '.pdf,.doc,.docx',
            label: 'Upload Syllabus PDF',
            onUploaded: (result) {
              setState(() {
                _uploadedSyllabus[courseId] = result.url;
                _uploadedNames[courseId] = result.originalName;
              });
              ds.addUploadedFile({
                'url': result.url,
                'originalName': result.originalName,
                'format': result.format,
                'sizeBytes': result.sizeBytes,
                'category': 'syllabus',
                'uploadedBy': ds.currentUserId ?? '',
                'courseId': courseId,
                'courseName': courseName,
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Syllabus for $courseId uploaded!'), backgroundColor: AppColors.secondary),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
