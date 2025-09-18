import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:enable_web/features/utils/file_utils.dart';
import 'package:enable_web/features/models/ingestion_progress.dart';

class FileItemWidget extends StatelessWidget {
  final GoogleDriveFile file;
  final bool isSelected;
  final bool isIngested;
  final VoidCallback onSelectionToggle;
  final VoidCallback onIngest;
  final VoidCallback? onOpenInBrowser;
  final IngestionProgress? ingestionProgress;

  const FileItemWidget({
    super.key,
    required this.file,
    required this.isSelected,
    required this.isIngested,
    required this.onSelectionToggle,
    required this.onIngest,
    this.onOpenInBrowser,
    this.ingestionProgress,
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
            // Always show ingestion status badge for files
            const SizedBox(width: 8),
            _buildIngestionStatusBadge(),
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
            // Always show ingestion status information
            _buildIngestionStatusInfo(),
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

  Widget _buildIngestionStatusBadge() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool showProgressIndicator = false;
    
    // Determine status based on ingestion progress and ingested state
    if (ingestionProgress != null) {
      // File is currently being processed
      switch (ingestionProgress!.status) {
        case 'queued':
          statusColor = Colors.orange[600]!;
          statusIcon = Icons.schedule;
          statusText = 'Queued';
          break;
        case 'running':
        case 'processing':
          statusColor = Colors.blue[600]!;
          statusIcon = Icons.sync;
          statusText = 'Processing';
          showProgressIndicator = true;
          break;
        case 'uploading':
          statusColor = Colors.purple[600]!;
          statusIcon = Icons.cloud_upload;
          statusText = 'Uploading';
          showProgressIndicator = true;
          break;
        case 'succeeded':
          statusColor = Colors.green[600]!;
          statusIcon = Icons.check_circle;
          statusText = 'Completed';
          break;
        case 'failed':
          statusColor = Colors.red[600]!;
          statusIcon = Icons.error;
          statusText = 'Failed';
          break;
        case 'skipped':
          statusColor = Colors.grey[600]!;
          statusIcon = Icons.skip_next;
          statusText = 'Skipped';
          break;
        default:
          statusColor = Colors.grey[600]!;
          statusIcon = Icons.help;
          statusText = 'Unknown';
      }
    } else if (isIngested) {
      // File has been ingested previously
      statusColor = Colors.green[600]!;
      statusIcon = Icons.check_circle;
      statusText = 'Ingested';
    } else {
      // File is available for ingestion
      statusColor = Colors.blue[100]!;
      statusIcon = Icons.upload_outlined;
      statusText = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgressIndicator)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              statusIcon,
              size: 12,
              color: Colors.white,
            ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return Colors.orange[600]!;
      case 'running':
      case 'processing':
        return Colors.blue[600]!;
      case 'uploading':
        return Colors.purple[600]!;
      case 'succeeded':
        return Colors.green[600]!;
      case 'failed':
        return Colors.red[600]!;
      case 'skipped':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getElapsedTime(DateTime? startedAt) {
    if (startedAt == null) return '';
    
    final now = DateTime.now();
    final elapsed = now.difference(startedAt);
    
    if (elapsed.inSeconds < 60) {
      return '${elapsed.inSeconds}s elapsed';
    } else if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s elapsed';
    } else {
      return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m elapsed';
    }
  }

  Widget _buildIngestionStatusInfo() {
    if (ingestionProgress != null && ingestionProgress!.message != null) {
      // Show active progress information
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ingestionProgress!.message!,
            style: TextStyle(
              fontSize: 11,
              color: _getStatusColor(ingestionProgress!.status),
              fontWeight: FontWeight.w500,
            ),
          ),
          // Show elapsed time for running processes
          if (ingestionProgress!.status == 'running' || 
              ingestionProgress!.status == 'processing' || 
              ingestionProgress!.status == 'uploading')
            Text(
              _getElapsedTime(ingestionProgress!.startedAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      );
    } else if (isIngested) {
      // Show ingested status
      return Text(
        'File has been processed and is available for AI queries',
        style: TextStyle(
          fontSize: 11,
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      // Show available for ingestion status
      return Text(
        'Click to ingest this file for AI processing',
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}
