import 'package:flutter/material.dart';
import 'package:enable_web/features/models/ingestion_progress.dart';

class ProgressSectionWidget extends StatelessWidget {
  final Map<String, IngestionProgress> ingestionProgress;

  const ProgressSectionWidget({
    super.key,
    required this.ingestionProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (ingestionProgress.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ), 
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ingestion Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            ...ingestionProgress.values.map((progress) => _buildProgressItem(progress)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(IngestionProgress progress) {
    Color statusColor;
    IconData statusIcon;
    
    switch (progress.status) {
      case 'queued':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'running':
      case 'processing':
      case 'uploading':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'succeeded':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'skipped':
        statusColor = Colors.grey;
        statusIcon = Icons.skip_next;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  progress.message ?? 'Unknown status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (progress.status == 'running' || progress.status == 'processing' || progress.status == 'uploading')
                  Text(
                    _getElapsedTime(progress.startedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (progress.error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${progress.error}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (progress.status == 'running' || progress.status == 'processing' || progress.status == 'uploading')
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
        ],
      ),
    );
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
}
