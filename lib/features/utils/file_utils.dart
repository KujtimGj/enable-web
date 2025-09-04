import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';

class FileUtils {
  static Widget getFileIcon(String mimeType) {
    IconData iconData;
    Color iconColor;

    if (mimeType.contains('folder')) {
      iconData = Icons.folder;
      iconColor = Colors.amber;
    } else if (mimeType.contains('pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (mimeType.contains('document') || mimeType.contains('word')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      iconData = Icons.slideshow;
      iconColor = Colors.orange;
    } else if (mimeType.contains('text/plain')) {
      iconData = Icons.text_snippet;
      iconColor = Colors.green;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static bool isTextFile(String mimeType) {
    final textMimeTypes = [
      'text/plain',
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    ];
    return textMimeTypes.any((type) => mimeType.contains(type));
  }

  static List<GoogleDriveFile> filterItems(List<GoogleDriveFile> items, {bool showSharedOnly = false}) {
    try {
      
      final allowedItems = items.where((item) {
        if (item.isFolder) return true;
        
        final mimeType = item.mimeType.toLowerCase();
        
        return mimeType.contains('pdf') ||
               mimeType.contains('word') ||
               mimeType.contains('document') ||
               mimeType.contains('text/plain') ||
               mimeType.contains('presentation') ||
               mimeType.contains('powerpoint') ||
               mimeType.contains('application/vnd.openxmlformats-officedocument.wordprocessingml.document') ||
               mimeType.contains('application/vnd.openxmlformats-officedocument.presentationml.presentation') ||
               mimeType.contains('application/pdf');
      }).toList();


      if (showSharedOnly) {
        final beforeSharedFilter = allowedItems.length;
        final sharedItems = allowedItems.where((item) => item.isShared).toList();
        return sharedItems;
      }

      return allowedItems;
    } catch (e) {
      return items; // Return original items if filtering fails
    }
  }
}
