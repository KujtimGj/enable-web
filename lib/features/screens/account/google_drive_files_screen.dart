import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/google_drive_provider.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleDriveFilesScreen extends StatefulWidget {
  const GoogleDriveFilesScreen({super.key});

  @override
  State<GoogleDriveFilesScreen> createState() => _GoogleDriveFilesScreenState();
}

class _GoogleDriveFilesScreenState extends State<GoogleDriveFilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final googleDriveProvider = Provider.of<GoogleDriveProvider>(
        context,
        listen: false,
      );
      if (googleDriveProvider.isConnected) {
        googleDriveProvider.loadFiles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: ResponsiveContainer(
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/account'),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/icons/go-back.svg'),
                        Text(
                          'Google Drive Files',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: Consumer<GoogleDriveProvider>(
                  builder: (context, googleDriveProvider, child) {
                    if (!googleDriveProvider.isConnected) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/drive2.svg',
                              height: 64,
                              width: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Google Drive not connected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please connect your Google Drive account to view files',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  googleDriveProvider.isLoading
                                      ? null
                                      : () =>
                                          googleDriveProvider
                                              .connectGoogleDrive(),
                              child: Text('Connect Google Drive'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (googleDriveProvider.isLoading && googleDriveProvider.files.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading Google Drive files...'),
                          ],
                        ),
                      );
                    }

                    if (googleDriveProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading files',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              googleDriveProvider.error!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                googleDriveProvider.clearError();
                                googleDriveProvider.loadFiles();
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (googleDriveProvider.files.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/drive2.svg',
                              height: 64,
                              width: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No files found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your Google Drive appears to be empty',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Header with file count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Google Drive Files (${googleDriveProvider.files.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (googleDriveProvider.lastSync != null)
                                  Text(
                                    'Last sync: ${_formatDate(googleDriveProvider.lastSync!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                SizedBox(width: 16),
                                IconButton(
                                  onPressed:
                                      googleDriveProvider.isLoading
                                          ? null
                                          : () =>
                                              googleDriveProvider.loadFiles(),
                                  icon: Icon(Icons.refresh),
                                  tooltip: 'Refresh files',
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Files list
                        Expanded(
                          child: ListView.builder(
                            itemCount: googleDriveProvider.files.length,
                            itemBuilder: (context, index) {
                              final file = googleDriveProvider.files[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: _getFileIcon(file.mimeType),
                                  title: Text(
                                    file.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (file.size != null)
                                        Text(
                                          _formatFileSize(
                                            file.size!,
                                          ).toString(),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      if (file.modifiedTime != null)
                                        Text(
                                          'Modified: ${_formatDate(DateTime.parse(file.modifiedTime!))}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SelectableText(file.id),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              _readFileContent(file.id);
                                            },
                                            icon: Icon(Icons.upload_outlined),
                                            tooltip: 'Ingest Data',
                                          ),
                                        ],
                                      ),
                                      // Read content button for text files
                                      //   IconButton(
                                      //     onPressed:
                                      //         () => _readFileContent(file.id),
                                      //     icon: Icon(Icons.description),
                                      //     tooltip: 'Read content',
                                      //   ),
                                      if (file.webViewLink != null)
                                        IconButton(
                                          onPressed:
                                              () => _openFileInBrowser(
                                                file.webViewLink!,
                                              ),
                                          icon: Icon(Icons.open_in_new),
                                          tooltip: 'Open in browser',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFileIcon(String mimeType) {
    IconData iconData;
    Color iconColor;

    if (mimeType.contains('folder')) {
      iconData = Icons.folder;
      iconColor = Colors.amber;
    } else if (mimeType.contains('image')) {
      iconData = Icons.image;
      iconColor = Colors.green;
    } else if (mimeType.contains('video')) {
      iconData = Icons.video_file;
      iconColor = Colors.red;
    } else if (mimeType.contains('audio')) {
      iconData = Icons.audio_file;
      iconColor = Colors.purple;
    } else if (mimeType.contains('pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (mimeType.contains('document') || mimeType.contains('word')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (mimeType.contains('presentation') ||
        mimeType.contains('powerpoint')) {
      iconData = Icons.slideshow;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
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

  void _openFileInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file in browser'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isTextFile(String mimeType) {
    final textMimeTypes = [
      'text/plain',
      'text/csv',
      'text/html',
      'text/css',
      'text/javascript',
      'application/json',
      'application/xml',
      'application/javascript',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/pdf'
    ];
    return textMimeTypes.any((type) => mimeType.contains(type));
  }


  Future<void> listenToFileProgress(String fileId, void Function(int percent, String message) onUpdate) async {
    final uri = Uri.parse('http://https://enable-be-production.up.railway.app/api/v1/google-drive/files/$fileId/progress');
    final request = http.Request('GET', uri);
    final client = http.Client();
    final response = await client.send(request);

    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.startsWith("data: ")) {
        final dataString = line.substring(6).trim();
        try {
          final jsonData = json.decode(dataString);
          final percent = jsonData['percent'] ?? 0;
          final message = jsonData['message'] ?? "";
          onUpdate(percent, message);
        } catch (e) {
          print("❌ Failed to parse SSE line: $line");
        }
      }
    }, onError: (e) {
      print("❌ SSE stream error: $e");
    }, onDone: () {
      print("✅ SSE stream closed");
      client.close();
    });
  }

  void _readFileContent(String fileId) async {
    final googleDriveProvider = Provider.of<GoogleDriveProvider>(context, listen: false);

    try {
      final result = await googleDriveProvider.readFileContent(fileId);

      result.fold(
            (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to read file: ${failure.toString()}')),
          );
        },
            (fileList) {
          if (fileList is List && fileList.isNotEmpty) {
            final file = fileList[0];

            final fileName = file['fileName'];
            final content = file['content'];

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(fileName ?? 'File Content'),
                content: SingleChildScrollView(
                  child: SelectableText(
                    content ?? 'No content available',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No file data returned.')),
            );
          }
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading file: $e')),
      );
    }
  }

}
