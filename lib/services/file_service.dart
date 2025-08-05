import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

enum FileType { image, pdf, document, resume, coverLetter }

class FileUploadResult {
  final String url;
  final String fileName;
  final int fileSize;
  final String fileType;

  FileUploadResult({
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
  });
}

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final _supabase = SupabaseService();
  final _imagePicker = ImagePicker();

  // Upload file to Supabase storage
  Future<FileUploadResult> uploadFile({
    required String filePath,
    required String bucket,
    required String fileName,
    FileType? fileType,
  }) async {
    try {
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;
      final fileExtension = filePath.split('.').last.toLowerCase();

      // Upload to Supabase storage
      await _supabase.client.storage
          .from(bucket)
          .uploadBinary(fileName, fileBytes);

      // Get public URL
      final publicUrl = _supabase.client.storage
          .from(bucket)
          .getPublicUrl(fileName);

      return FileUploadResult(
        url: publicUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileExtension,
      );
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  // Upload profile image
  Future<FileUploadResult> uploadProfileImage(String userId, String imagePath) async {
    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.${imagePath.split('.').last}';
      
      return await uploadFile(
        filePath: imagePath,
        bucket: 'profiles',
        fileName: fileName,
        fileType: FileType.image,
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  // Upload resume
  Future<FileUploadResult> uploadResume(String userId, String resumePath) async {
    try {
      final fileName = 'resume_${userId}_${DateTime.now().millisecondsSinceEpoch}.${resumePath.split('.').last}';
      
      return await uploadFile(
        filePath: resumePath,
        bucket: 'resumes',
        fileName: fileName,
        fileType: FileType.resume,
      );
    } catch (e) {
      throw Exception('Failed to upload resume: ${e.toString()}');
    }
  }

  // Upload cover letter
  Future<FileUploadResult> uploadCoverLetter(String userId, String coverLetterPath) async {
    try {
      final fileName = 'cover_letter_${userId}_${DateTime.now().millisecondsSinceEpoch}.${coverLetterPath.split('.').last}';
      
      return await uploadFile(
        filePath: coverLetterPath,
        bucket: 'documents',
        fileName: fileName,
        fileType: FileType.coverLetter,
      );
    } catch (e) {
      throw Exception('Failed to upload cover letter: ${e.toString()}');
    }
  }

  // Pick image from gallery or camera
  Future<String?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      return image?.path;
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  // Pick document file
  Future<String?> pickDocument({
    List<String>? allowedExtensions,
    FileType type = FileType.document,
  }) async {
    try {
      FilePickerResult? result;
      
      switch (type) {
        case FileType.pdf:
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );
          break;
        case FileType.document:
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx'],
            allowMultiple: false,
          );
          break;
        default:
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
          );
      }

      return result?.files.single.path;
    } catch (e) {
      throw Exception('Failed to pick document: ${e.toString()}');
    }
  }

  // Download file
  Future<void> downloadFile(String url, String savePath) async {
    try {
      final response = await _supabase.client.storage
          .from('public')
          .download(url);
      
      final file = File(savePath);
      await file.writeAsBytes(response);
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String bucket, String fileName) async {
    try {
      await _supabase.client.storage
          .from(bucket)
          .remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  // Get file info
  Future<Map<String, dynamic>?> getFileInfo(String bucket, String fileName) async {
    try {
      final response = await _supabase.client.storage
          .from(bucket)
          .list(path: fileName);
      
      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      throw Exception('Failed to get file info: ${e.toString()}');
    }
  }

  // Validate file size (in bytes)
  bool validateFileSize(String filePath, int maxSizeInMB) {
    try {
      final file = File(filePath);
      final fileSizeInBytes = file.lengthSync();
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
      
      return fileSizeInBytes <= maxSizeInBytes;
    } catch (e) {
      return false;
    }
  }

  // Validate file type
  bool validateFileType(String filePath, List<String> allowedExtensions) {
    try {
      final extension = filePath.split('.').last.toLowerCase();
      return allowedExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }

  // Get file size in readable format
  String getReadableFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    
    if (i >= suffixes.length) i = suffixes.length - 1;
    
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Compress image
  Future<String?> compressImage(String imagePath, {int quality = 85}) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return null;

      // For now, return the original path
      // In a real implementation, you would use an image compression library
      return imagePath;
    } catch (e) {
      throw Exception('Failed to compress image: ${e.toString()}');
    }
  }

  // Create thumbnail for image
  Future<String?> createThumbnail(String imagePath, {int width = 200, int height = 200}) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return null;

      // For now, return the original path
      // In a real implementation, you would create a thumbnail
      return imagePath;
    } catch (e) {
      throw Exception('Failed to create thumbnail: ${e.toString()}');
    }
  }

  // Upload multiple files
  Future<List<FileUploadResult>> uploadMultipleFiles({
    required List<String> filePaths,
    required String bucket,
    required String prefix,
  }) async {
    try {
      final results = <FileUploadResult>[];
      
      for (int i = 0; i < filePaths.length; i++) {
        final filePath = filePaths[i];
        final fileName = '${prefix}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.${filePath.split('.').last}';
        
        final result = await uploadFile(
          filePath: filePath,
          bucket: bucket,
          fileName: fileName,
        );
        
        results.add(result);
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to upload multiple files: ${e.toString()}');
    }
  }

  // Get storage usage for user
  Future<Map<String, dynamic>> getStorageUsage(String userId) async {
    try {
      int totalSize = 0;
      int fileCount = 0;
      
      // Check different buckets
      final buckets = ['profiles', 'resumes', 'documents'];
      final usage = <String, dynamic>{};
      
      for (final bucket in buckets) {
        try {
          final files = await _supabase.client.storage
              .from(bucket)
              .list();
          
          int bucketSize = 0;
          int bucketCount = 0;
          
          for (final file in files) {
            if (file['name'].toString().contains(userId)) {
              final size = file['metadata']?['size'] ?? 0;
              bucketSize += size as int;
              bucketCount++;
            }
          }
          
          usage[bucket] = {
            'size': bucketSize,
            'count': bucketCount,
            'readableSize': getReadableFileSize(bucketSize),
          };
          
          totalSize += bucketSize;
          fileCount += bucketCount;
        } catch (e) {
          usage[bucket] = {
            'size': 0,
            'count': 0,
            'readableSize': '0 B',
          };
        }
      }
      
      usage['total'] = {
        'size': totalSize,
        'count': fileCount,
        'readableSize': getReadableFileSize(totalSize),
      };
      
      return usage;
    } catch (e) {
      throw Exception('Failed to get storage usage: ${e.toString()}');
    }
  }

  // Clean up old files
  Future<void> cleanupOldFiles(String userId, {int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final buckets = ['profiles', 'resumes', 'documents'];
      
      for (final bucket in buckets) {
        try {
          final files = await _supabase.client.storage
              .from(bucket)
              .list();
          
          final filesToDelete = <String>[];
          
          for (final file in files) {
            if (file['name'].toString().contains(userId)) {
              final createdAt = DateTime.parse(file['created_at']);
              if (createdAt.isBefore(cutoffDate)) {
                filesToDelete.add(file['name']);
              }
            }
          }
          
          if (filesToDelete.isNotEmpty) {
            await _supabase.client.storage
                .from(bucket)
                .remove(filesToDelete);
          }
        } catch (e) {
          // Continue with other buckets if one fails
        }
      }
    } catch (e) {
      throw Exception('Failed to cleanup old files: ${e.toString()}');
    }
  }
}