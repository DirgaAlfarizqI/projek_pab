import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/theme/app_theme.dart';

class ImagePickerField extends StatefulWidget {
  final String label;
  final String? initialImagePath;
  final ValueChanged<String?> onImageChanged;

  const ImagePickerField({
    super.key,
    required this.label,
    this.initialImagePath,
    required this.onImageChanged,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  String? _currentPath;
  bool _isProcessing = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialImagePath;
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        return;
      }

      String savedPath = picked.path;
      if (!kIsWeb) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final photosDir = Directory('${appDir.path}/tanijagung_photos');
          if (!await photosDir.exists()) {
            await photosDir.create(recursive: true);
          }
          final ext = picked.path.contains('.')
              ? picked.path.split('.').last
              : 'jpg';
          final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final savedFile = await File(picked.path)
              .copy('${photosDir.path}/$fileName');
          savedPath = savedFile.path;
        } catch (_) {
          // Gunakan path asli dari cache image_picker apabila direktori dokumen gagal diakses
          savedPath = picked.path;
        }
      }

      if (mounted) {
        setState(() {
          _currentPath = savedPath;
          _isProcessing = false;
        });
        widget.onImageChanged(savedPath);
      }
    } on PlatformException catch (e) {
      String msg = 'Gagal mengakses kamera atau galeri.';
      final code = e.code.toLowerCase();
      if (code.contains('denied') || code.contains('permission')) {
        msg = 'Izin kamera/galeri ditolak. Silakan aktifkan izin kamera atau penyimpanan di Pengaturan Android Anda.';
      } else if (code.contains('camera_access') ||
          code.contains('no_available_camera')) {
        msg = 'Kamera tidak tersedia pada perangkat ini.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorText = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorText = 'Kamera tidak tersedia atau terjadi kesalahan saat mengambil gambar.';
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _currentPath = null;
      _errorText = null;
    });
    widget.onImageChanged(null);
  }

  bool _fileExists(String path) {
    if (kIsWeb) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _currentPath != null && _currentPath!.trim().isNotEmpty;
    final canRenderFile = hasImage && _fileExists(_currentPath!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasImage) ...[
                if (canRenderFile)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_currentPath!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildFallbackPreview(),
                    ),
                  )
                else
                  _buildFallbackPreview(),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickAndSaveImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Ganti via Kamera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickAndSaveImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Ganti via Galeri'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.dangerRed,
                      ),
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus Foto'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickAndSaveImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text(
                          'Kamera',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickAndSaveImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Galeri',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackPreview() {
    final fileName = _currentPath!.split(RegExp(r'[/\\]')).last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, color: AppTheme.darkGreen, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGreen,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
