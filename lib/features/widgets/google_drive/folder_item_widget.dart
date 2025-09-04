import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:enable_web/features/utils/file_utils.dart';

class FolderItemWidget extends StatelessWidget {
  final GoogleDriveFile folder;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelectionToggle;

  const FolderItemWidget({
    super.key,
    required this.folder,
    required this.isSelected,
    required this.onTap,
    required this.onSelectionToggle,
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
              onChanged: (bool? value) {
                onSelectionToggle();
              },
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                Icon(
                  Icons.folder,
                  color: folder.isShared ? Colors.orange[600] : Colors.blue[600],
                  size: 32,
                ),
                if (folder.isShared)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: folder.isShared ? Colors.orange[700] : Colors.blue[700],
                ),
              ),
            ),  
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (folder.itemCount != null)
              Text(
                '${folder.itemCount} items',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (folder.isShared)
              SelectableText(
                'Owner: ${folder.owner} ${folder.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (folder.modifiedTime != null)
              Text(
                'Modified: ${FileUtils.formatDate(DateTime.parse(folder.modifiedTime!))}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }
}
