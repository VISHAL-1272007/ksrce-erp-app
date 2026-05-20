// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/theme/app_colors.dart';

/// A reusable file upload widget with drag-and-drop styling, progress, and result display.
class FileUploadWidget extends StatefulWidget {
  final String? category;
  final String? folder;
  final String accept;
  final String label;
  final void Function(UploadResult result)? onUploaded;
  final bool showPreview;

  const FileUploadWidget({
    super.key,
    this.category,
    this.folder,
    this.accept = '*/*',
    this.label = 'Upload File',
    this.onUploaded,
    this.showPreview = true,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final _uploadService = FileUploadService();
  bool _isUploading = false;
  double _progress = 0;
  UploadResult? _lastResult;
  String? _error;

  Future<void> _handleUpload() async {
    final file = await _uploadService.pickFile(accept: widget.accept);
    if (file == null) return;
    await _uploadFile(file);
  }

  Future<void> _uploadFile(PlatformFile file) async {
    setState(() {
      _isUploading = true;
      _progress = 0;
      _error = null;
      _lastResult = null;
    });

    try {
      final result = await _uploadService.uploadFile(
        file,
        folder: widget.folder ?? 'ksrce/${widget.category ?? "general"}',
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() {
        _lastResult = result;
        _isUploading = false;
      });
      widget.onUploaded?.call(result);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload area
          InkWell(
            onTap: _isUploading ? null : _handleUpload,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: _isUploading
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isUploading
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: _isUploading
                  ? _buildUploading()
                  : _buildUploadPrompt(),
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _error = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Success result
          if (_lastResult != null && widget.showPreview)
            _buildResult(_lastResult!),
        ],
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_upload_outlined,
              size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Click to browse files',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getAcceptLabel(),
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildUploading() {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: _progress > 0 ? _progress : null,
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Uploading... ${(_progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            minHeight: 4,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(UploadResult result) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              FileUploadService.getFileIcon(result.format),
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    const Text('Uploaded successfully!',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.originalName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${result.format.toUpperCase()} • ${result.formattedSize}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new,
                    color: AppColors.primary, size: 20),
                tooltip: 'Open in browser',
                onPressed: () => launchUrl(Uri.parse(result.url)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.textLight, size: 18),
                tooltip: 'Copy link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                      backgroundColor: AppColors.secondary,
                      duration: Duration(seconds: 2),
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

  String _getAcceptLabel() {
    if (widget.accept == '*/*') return 'All file types supported';
    if (widget.accept == 'image/*') return 'JPG, PNG, GIF, WebP';
    if (widget.accept.contains('.pdf')) return 'PDF, DOC, XLS, PPT, TXT, CSV';
    return widget.accept;
  }
}

/// A compact file link display widget for showing uploaded files.
class FileLink extends StatelessWidget {
  final String url;
  final String fileName;
  final String? format;
  final String? size;

  const FileLink({
    super.key,
    required this.url,
    required this.fileName,
    this.format,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ext = format ?? _getExt(fileName);
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FileUploadService.getFileIcon(ext),
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (size != null) ...[
              const SizedBox(width: 6),
              Text(size!, style: const TextStyle(
                  color: AppColors.textLight, fontSize: 11)),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  String _getExt(String name) {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
