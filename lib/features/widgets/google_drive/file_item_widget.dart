import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:enable_web/features/utils/file_utils.dart';

class FileItemWidget extends StatelessWidget {
  final GoogleDriveFile file;
  final bool isSelected;
  final bool isIngested;
  final VoidCallback onSelectionToggle;
  final VoidCallback onIngest;
  final VoidCallback? onOpenInBrowser;

  const FileItemWidget({
    super.key,
    required this.file,
    required this.isSelected,
    required this.isIngested,
    required this.onSelectionToggle,
    required this.onIngest,
    this.onOpenInBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: isIngested ? null : (bool? value) {
                onSelectionToggle();
              },
            ),
            const SizedBox(width: 8),
            FileUtils.getFileIcon(file.mimeType),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                file.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: file.isShared ? Colors.orange[700] : null,
                ),
              ),
            ),
            if (file.isShared)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff1e1e1e),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Shared',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isIngested)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Ingested',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file.size != null)
              Text(FileUtils.formatFileSize(file.size!), style: const TextStyle(fontSize: 12)),
           if (file.isShared)
              Text(
                'Owner: ${file.owner}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            SelectableText(file.id),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.webViewLink != null && onOpenInBrowser != null)
              IconButton(
                onPressed: onOpenInBrowser,
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open in browser',
              ),
          ],
        ),
      ),
    );
  }
}
