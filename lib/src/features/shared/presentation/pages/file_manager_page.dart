// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/data_service.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/theme/app_colors.dart';

/// File Manager page — upload, view, and manage files stored as Cloudinary links.
class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key});
  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  String _filterCategory = 'All';
  bool _showMyFilesOnly = false;
  bool _showConfigPanel = false;
  final _cloudNameCtrl = TextEditingController();
  final _presetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final svc = FileUploadService();
    _cloudNameCtrl.text = svc.cloudName;
    _presetCtrl.text = svc.uploadPreset;
  }

  @override
  void dispose() {
    _cloudNameCtrl.dispose();
    _presetCtrl.dispose();
    super.dispose();
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

      final uid = ds.currentUserId ?? '';
      final role = ds.currentRole ?? '';
      final isAdmin = role == 'admin';
      final files = ds.getUploadedFiles(
        userId: _showMyFilesOnly ? uid : null,
        category: _filterCategory != 'All' ? _filterCategory : null,
      );

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.cloud_upload, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('File Manager',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          Text(
                            'Upload files to cloud • Get shareable links',
                            style: TextStyle(
                                color: AppColors.textLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: Icon(
                          _showConfigPanel ? Icons.settings : Icons.settings_outlined,
                          color: _showConfigPanel ? AppColors.primary : AppColors.textLight,
                        ),
                        tooltip: 'Cloudinary Settings',
                        onPressed: () =>
                            setState(() => _showConfigPanel = !_showConfigPanel),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cloudinary config panel (admin only)
                if (_showConfigPanel && isAdmin) ...[
                  _buildConfigPanel(),
                  const SizedBox(height: 20),
                ],

                // Upload section
                _buildUploadSection(ds, uid),
                const SizedBox(height: 24),

                // Filters
                _buildFilters(files.length),
                const SizedBox(height: 16),

                // Files list
                if (files.isEmpty)
                  _buildEmptyState()
                else
                  ...files.map((f) => _buildFileCard(ds, f, uid, isAdmin, isMobile)),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildConfigPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Cloudinary Configuration',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _showConfigPanel = false),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a free account at cloudinary.com → Settings → Upload → Add unsigned preset',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cloudNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cloud Name',
                    hintText: 'your-cloud-name',
                    prefixIcon: const Icon(Icons.cloud_outlined, size: 18),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _presetCtrl,
                  decoration: InputDecoration(
                    labelText: 'Upload Preset',
                    hintText: 'unsigned_preset',
                    prefixIcon: const Icon(Icons.key, size: 18),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  FileUploadService().configure(
                    cloudName: _cloudNameCtrl.text.trim(),
                    uploadPreset: _presetCtrl.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cloudinary configured successfully!'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                  setState(() => _showConfigPanel = false);
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(DataService ds, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Upload New File',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Files are uploaded to Cloudinary and stored as shareable links.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final categories = [
              _UploadCategory('Assignments', Icons.assignment, 'assignments', '.pdf,.doc,.docx,.ppt,.pptx,.txt'),
              _UploadCategory('Certificates', Icons.workspace_premium, 'certificates', 'image/*,.pdf'),
              _UploadCategory('Photos', Icons.photo, 'photos', 'image/*'),
              _UploadCategory('Documents', Icons.description, 'documents', '.pdf,.doc,.docx,.xls,.xlsx,.csv,.txt'),
              _UploadCategory('Other', Icons.folder, 'general', '*/*'),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((cat) => SizedBox(
                width: isMobile ? double.infinity : 160,
                child: _uploadCategoryButton(ds, uid, cat),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _uploadCategoryButton(DataService ds, String uid, _UploadCategory cat) {
    return _UploadCategoryCard(
      category: cat,
      onUploaded: (result) {
        final userName = _getUserName(ds, uid);
        ds.addUploadedFile({
          'url': result.url,
          'originalName': result.originalName,
          'format': result.format,
          'sizeBytes': result.sizeBytes,
          'resourceType': result.resourceType,
          'category': cat.category,
          'uploadedBy': uid,
          'uploaderName': userName,
          if (result.width != null) 'width': result.width,
          if (result.height != null) 'height': result.height,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.originalName} uploaded successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
      },
    );
  }

  String _getUserName(DataService ds, String uid) {
    if (ds.currentStudent != null) return ds.currentStudent!['name'] as String? ?? uid;
    if (ds.currentFaculty != null) return ds.currentFaculty!['name'] as String? ?? uid;
    return uid;
  }

  Widget _buildFilters(int totalCount) {
    final categories = ['All', 'assignments', 'certificates', 'photos', 'documents', 'general'];
    return Row(
      children: [
        Icon(Icons.folder_open, color: AppColors.textMedium, size: 20),
        const SizedBox(width: 8),
        Text('Uploaded Files',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$totalCount',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const Spacer(),
        // My Files toggle
        FilterChip(
          label: const Text('My Files'),
          selected: _showMyFilesOnly,
          onSelected: (v) => setState(() => _showMyFilesOnly = v),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: _showMyFilesOnly ? AppColors.primary : AppColors.textMedium,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterCategory,
              isDense: true,
              style: const TextStyle(color: AppColors.textDark, fontSize: 13),
              items: categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c == 'All' ? 'All Categories' : _capitalize(c)),
              )).toList(),
              onChanged: (v) => setState(() => _filterCategory = v ?? 'All'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(DataService ds, Map<String, dynamic> file, String uid, bool isAdmin, bool isMobile) {
    final url = file['url'] as String? ?? '';
    final name = file['originalName'] as String? ?? 'File';
    final format = file['format'] as String? ?? '';
    final sizeBytes = file['sizeBytes'] as int? ?? 0;
    final category = file['category'] as String? ?? '';
    final uploaderName = file['uploaderName'] as String? ?? '';
    final uploadedAt = file['uploadedAt'] as String? ?? '';
    final resourceType = file['resourceType'] as String? ?? '';
    final canDelete = file['uploadedBy'] == uid || isAdmin;
    final isImage = resourceType == 'image';
    final dateStr = uploadedAt.length >= 10 ? uploadedAt.substring(0, 10) : uploadedAt;
    final timeStr = uploadedAt.length >= 16 ? uploadedAt.substring(11, 16) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // File icon or thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isImage && url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) => Icon(
                        FileUploadService.getFileIcon(format),
                        color: _getCategoryColor(category),
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    FileUploadService.getFileIcon(format),
                    color: _getCategoryColor(category),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _tag(format.toUpperCase(), _getCategoryColor(category)),
                    const SizedBox(width: 6),
                    Text(FileUploadService.formatFileSize(sizeBytes),
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 11)),
                    const SizedBox(width: 6),
                    _tag(_capitalize(category), AppColors.textMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$uploaderName • $dateStr $timeStr',
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 11)),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                color: AppColors.primary,
                tooltip: 'Open file',
                onPressed: () => launchUrl(Uri.parse(url)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                color: AppColors.textLight,
                tooltip: 'Copy link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied!'),
                      backgroundColor: AppColors.secondary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.withValues(alpha: 0.7),
                  tooltip: 'Delete',
                  onPressed: () {
                    ds.deleteUploadedFile(file['fileId'] as String? ?? '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File removed'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 64,
              color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No files uploaded yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Use the upload buttons above to upload files',
              style: TextStyle(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'assignments':
        return AppColors.accent;
      case 'certificates':
        return const Color(0xFF7E57C2);
      case 'photos':
        return AppColors.secondary;
      case 'documents':
        return AppColors.primary;
      default:
        return AppColors.textMedium;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _UploadCategory {
  final String label;
  final IconData icon;
  final String category;
  final String accept;
  const _UploadCategory(this.label, this.icon, this.category, this.accept);
}

class _UploadCategoryCard extends StatefulWidget {
  final _UploadCategory category;
  final void Function(UploadResult result) onUploaded;

  const _UploadCategoryCard({required this.category, required this.onUploaded});
  @override
  State<_UploadCategoryCard> createState() => _UploadCategoryCardState();
}

class _UploadCategoryCardState extends State<_UploadCategoryCard> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return InkWell(
      onTap: _isUploading ? null : _handleUpload,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: _isUploading
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _isUploading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(cat.icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(cat.label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    final svc = FileUploadService();
    final file = await svc.pickFile(accept: widget.category.accept);
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      final result = await svc.uploadFile(
        file,
        folder: 'ksrce/${widget.category.category}',
      );
      widget.onUploaded(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
