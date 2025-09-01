import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/google_drive_provider.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:enable_web/features/controllers/google_drive_controller.dart';
import 'package:enable_web/core/failure.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/api.dart';

class IngestionProgress {
  final String fileId;
  final String fileName;
  final String status;
  final int? progress;
  final String? message;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? error;

  IngestionProgress({
    required this.fileId,
    required this.fileName,
    required this.status,
    this.progress,
    this.message,
    this.startedAt,
    this.finishedAt,
    this.error,
  });

  factory IngestionProgress.fromJson(Map<String, dynamic> json) {
    return IngestionProgress(
      fileId: json['fileId'] ?? '',
      fileName: json['fileName'] ?? '',
      status: json['status'] ?? 'unknown',
      progress: json['progress'],
      message: json['message'],
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt']) : null,
      error: json['error'],
    );
  }

  IngestionProgress copyWith({
    String? fileId,
    String? fileName,
    String? status,
    int? progress,
    String? message,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? error,
  }) {
    return IngestionProgress(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      error: error ?? this.error,
    );
  }
}

class GoogleDriveFilesScreen extends StatefulWidget {
  const GoogleDriveFilesScreen({super.key});

  @override
  State<GoogleDriveFilesScreen> createState() => _GoogleDriveFilesScreenState();
}

class _GoogleDriveFilesScreenState extends State<GoogleDriveFilesScreen> {
  final GoogleDriveController _controller = GoogleDriveController();

  GoogleDriveStructure? _structure;
  FolderContents? _currentFolder;
  List<Breadcrumb> _breadcrumbs = [];
  bool _isLoading = false;
  String? _error;
  String? _currentFolderId;
  bool _showSharedOnly = false;
  
  // Selection state variables
  Set<String> _selectedItems = {};
  bool _selectAll = false;
  
  // Progress tracking state variables
  Map<String, IngestionProgress> _ingestionProgress = {};
  bool _isTrackingProgress = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoogleDriveStructure();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGoogleDriveStructure() async {
    print('🔍 [loadGoogleDriveStructure] Loading Google Drive structure...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _controller.getGoogleDriveStructure();
      result.fold(
        (failure) {
          print('❌ [loadGoogleDriveStructure] Failed to load structure: ${failure.toString()}');
          setState(() {
            _error =
                failure is ServerFailure
                    ? failure.message
                    : 'Failed to load Google Drive structure';
            _isLoading = false;
          });
        },
        (structure) {
          // Debug logging
          structure.rootItems.forEach((item) {
          });

          setState(() {
            _structure = structure;
            _currentFolder = null;
            _currentFolderId = null;
            _breadcrumbs = [];
            _isLoading = false;
          });
          
        },
      );
    } catch (e) {
      print('❌ [loadGoogleDriveStructure] Exception occurred: $e');
      setState(() {
        _error = 'Failed to load Google Drive structure: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openFolder(String folderId, String folderName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _controller.getFolderContents(folderId);
      result.fold(
        (failure) {
          setState(() {
            _error =
                failure is ServerFailure
                    ? failure.message
                    : 'Failed to open folder';
            _isLoading = false;
          });
        },
        (folderContents) {
          folderContents.contents.forEach((item) {

          });

          setState(() {
            _currentFolder = folderContents;
            _currentFolderId = folderId;
            _breadcrumbs = folderContents.breadcrumbs;
            _isLoading = false;
            // Clear selection when navigating to a new folder
            _clearSelection();
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to open folder: $e';
        _isLoading = false;
      });
    }
  }

  void _goToBreadcrumb(String folderId) {
    if (folderId == 'root') {
      // Go back to root
      setState(() {
        _currentFolder = null;
        _currentFolderId = null;
        _breadcrumbs = [];
        // Clear selection when going back to root
        _clearSelection();
      });
    } else {
      // Navigate to specific folder
      _openFolder(folderId, '');
    }
  }

  List<GoogleDriveFile> _filterItems(List<GoogleDriveFile> items) {
    try {
      if (!_showSharedOnly) return items;

      // Debug logging
      items.forEach((item) {

      });

      final sharedItems = items.where((item) => item.isShared).toList();

      return sharedItems;
    } catch (e) {
      print('Error filtering items: $e');
      return items; // Return original items if filtering fails
    }
  }

  Widget _buildBreadcrumbs() {
    if (_breadcrumbs.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 16, color: Colors.blue[600]),
          SizedBox(width: 8),
          ..._breadcrumbs.asMap().entries.map((entry) {
            final index = entry.key;
            final crumb = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _goToBreadcrumb(crumb.id),
                  child: Text(
                    crumb.name,
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                if (index < _breadcrumbs.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFolderItem(GoogleDriveFile folder) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _selectedItems.contains(folder.id),
              onChanged: (bool? value) {
                _toggleItemSelection(folder.id);
              },
            ),
            SizedBox(width: 8),
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
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.share, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      folder.isShared ? Colors.orange[700] : Colors.blue[700],
                ),
              ),
            ),  
            if (folder.isShared)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Shared',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
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
              Text(
                'Owner: ${folder.owner}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (folder.modifiedTime != null)
              Text(
                'Modified: ${_formatDate(DateTime.parse(folder.modifiedTime!))}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: () => _openFolder(folder.id, folder.name),
      ),
    );
  }

  Widget _buildFileItem(GoogleDriveFile file) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _selectedItems.contains(file.id),
              onChanged: (bool? value) {
                _toggleItemSelection(file.id);
              },
            ),
            SizedBox(width: 8),
            _getFileIcon(file.mimeType),
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Shared',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file.size != null)
              Text(_formatFileSize(file.size!), style: TextStyle(fontSize: 12)),
            if (file.isShared)
              Text(
                'Owner: ${file.owner}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (file.modifiedTime != null)
              Text(
                'Modified: ${_formatDate(DateTime.parse(file.modifiedTime!))}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SelectableText(file.id, style: TextStyle(fontSize: 10)),
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _readFileContent(file.id),
              icon: Icon(Icons.upload_outlined),
              tooltip: 'Ingest Data',
            ),
            if (file.webViewLink != null)
              IconButton(
                onPressed: () => _openFileInBrowser(file.webViewLink!),
                icon: Icon(Icons.open_in_new),
                tooltip: 'Open in browser',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Check if Google Drive is connected using the provider
    final googleDriveProvider = Provider.of<GoogleDriveProvider>(
      context,
      listen: false,
    );

    if (!googleDriveProvider.isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/drive2.svg', height: 64, width: 64),
            SizedBox(height: 16),
            Text(
              'Google Drive not connected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      : () => googleDriveProvider.connectGoogleDrive(),
              child: Text('Connect Google Drive'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoogleDriveStructure,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentFolder != null) {
      // Show folder contents
      return Column(
        children: [
          _buildBreadcrumbs(),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentFolder!.folder.name} (${_currentFolder!.totalItems} items)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Select All button
                  ElevatedButton.icon(
                    onPressed: _toggleSelectAll,
                    icon: Icon(_selectAll ? Icons.check_box : Icons.check_box_outline_blank),
                    label: Text(_selectAll ? 'Deselect All' : 'Select All'),
                    style: ElevatedButton.styleFrom(
                    ),
                  ),
                  if (_selectedItems.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        '${_selectedItems.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 8),
                  // Enqueue Selected button
                  if (_selectedItems.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _enqueueSelectedFilesForIngestion,
                      icon: Icon(Icons.queue),
                      label: Text('Enqueue Selected (${_selectedItems.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  if (_selectedItems.isNotEmpty) SizedBox(width: 8),
                  Text(
                    '${_currentFolder!.totalFolders} folders, ${_currentFolder!.totalFiles} files',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  // Shared filter toggle
                  Row(
                    children: [
                      Icon(
                        Icons.share,
                        size: 16,
                        color:
                            _showSharedOnly
                                ? Colors.orange[600]
                                : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      // Text(
                      //   'Shared only',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color:
                      //         _showSharedOnly
                      //             ? Colors.orange[600]
                      //             : Colors.grey[600],
                      //   ),
                      // ),
                      // Switch(
                      //   value: _showSharedOnly,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       _showSharedOnly = value;
                      //     });
                      //   },
                      //   activeColor: Colors.orange[600],
                      // ),
                    ],
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    onPressed:
                        () => _openFolder(
                          _currentFolder!.folder.id,
                          _currentFolder!.folder.name,
                        ),
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh folder',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filterItems(_currentFolder!.contents).length,
              itemBuilder: (context, index) {
                // Sort items to show folders first, then files
                final sortedItems = List<GoogleDriveFile>.from(
                  _filterItems(_currentFolder!.contents),
                )..sort((a, b) {
                  // Folders first
                  if (a.isFolder && !b.isFolder) return -1;
                  if (!a.isFolder && b.isFolder) return 1;
                  // Then sort by name
                  return a.name.compareTo(b.name);
                });

                final item = sortedItems[index];
                if (item.isFolder) {
                  return _buildFolderItem(item);
                } else {
                  return _buildFileItem(item);
                }
              },
            ),
          ),
        ],
      );
    } else if (_structure != null) {
      // Show root structure
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Google Drive (${_structure!.totalFiles + _structure!.totalFolders} items)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Select All button
                  ElevatedButton.icon(
                    onPressed: _toggleSelectAll,
                    icon: Icon(_selectAll ? Icons.check_box : Icons.check_box_outline_blank),
                    label: Text(_selectAll ? 'Deselect All' : 'Select All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectAll ? Colors.red[100] : Colors.blue[100],
                      foregroundColor: _selectAll ? Colors.red[700] : Colors.blue[700],
                    ),
                  ),
                  if (_selectedItems.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        '${_selectedItems.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 8),
                  // Enqueue Selected button
                  if (_selectedItems.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _enqueueSelectedFilesForIngestion,
                      icon: Icon(Icons.queue),
                      label: Text('Enqueue Selected (${_selectedItems.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  if (_selectedItems.isNotEmpty) SizedBox(width: 8),
                  // Shared filter toggle
                  Row(
                    children: [
                      Icon(
                        Icons.share,
                        size: 16,
                        color:
                            _showSharedOnly
                                ? Colors.orange[600]
                                : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Shared only',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              _showSharedOnly
                                  ? Colors.orange[600]
                                  : Colors.grey[600],
                        ),
                      ),
                      Switch(
                        value: _showSharedOnly,
                        onChanged: (value) {
                          setState(() {
                            _showSharedOnly = value;
                          });
                        },
                        activeColor: Colors.orange[600],
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Text(
                    '${_structure!.rootFolders} folders, ${_structure!.rootFiles} files',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    onPressed: _loadGoogleDriveStructure,
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filterItems(_structure!.rootItems).length,
              itemBuilder: (context, index) {
                // Sort items to show folders first, then files
                final sortedItems = List<GoogleDriveFile>.from(
                  _filterItems(_structure!.rootItems),
                )..sort((a, b) {
                  // Folders first
                  if (a.isFolder && !b.isFolder) return -1;
                  if (!a.isFolder && b.isFolder) return 1;
                  // Then sort by name
                  return a.name.compareTo(b.name);
                });

                final item = sortedItems[index];
                if (item.isFolder) {
                  return _buildFolderItem(item);
                } else {
                  return _buildFileItem(item);
                }
              },
            ),
          ),
        ],
      );
    }

    // If we have no structure and no current folder, show a message
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/drive2.svg', height: 64, width: 64),
          SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Try refreshing to load your Google Drive content',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGoogleDriveStructure,
            child: Text('Refresh'),
          ),
        ],
      ),
    );
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
                          _currentFolder != null
                              ? 'Google Drive - ${_currentFolder!.folder.name}'
                              : 'Google Drive Files',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                        SizedBox(height: 20),
          // Progress tracking section
          if (_ingestionProgress.isNotEmpty) _buildProgressSection(),
          SizedBox(height: 16),
          Expanded(child: _buildContent()),
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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
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
      'application/pdf',
    ];
    return textMimeTypes.any((type) => mimeType.contains(type));
  }

  // Selection methods
  void _toggleItemSelection(String itemId) {
    try {
      setState(() {
        if (_selectedItems.contains(itemId)) {
          _selectedItems.remove(itemId);
        } else {
          _selectedItems.add(itemId);
        }
        _updateSelectAllState();
      });
    } catch (e) {
      print('Error toggling item selection: $e');
      // Ensure selection is updated even if setState fails
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
      _updateSelectAllState();
    }
  }

  void _toggleSelectAll() {
    try {
      setState(() {
        if (_selectAll) {
          _selectedItems.clear();
          _selectAll = false;
        } else {
          final currentItems = _getCurrentItems();
          _selectedItems = Set.from(currentItems.map((item) => item.id));
          _selectAll = true;
        }
      });
    } catch (e) {
      print('Error toggling select all: $e');
      // Ensure selection is updated even if setState fails
      if (_selectAll) {
        _selectedItems.clear();
        _selectAll = false;
      } else {
        final currentItems = _getCurrentItems();
        _selectedItems = Set.from(currentItems.map((item) => item.id));
        _selectAll = true;
      }
    }
  }

  void _updateSelectAllState() {
    try {
      final currentItems = _getCurrentItems();
      if (currentItems.isEmpty) {
        _selectAll = false;
      } else {
        _selectAll = _selectedItems.length == currentItems.length;
      }
    } catch (e) {
      print('Error updating select all state: $e');
      // Ensure state is updated even if there's an error
      _selectAll = false;
    }
  }

  List<GoogleDriveFile> _getCurrentItems() {
    try {
      if (_currentFolder != null) {
        return _filterItems(_currentFolder!.contents);
      } else if (_structure != null) {
        return _filterItems(_structure!.rootItems);
      }
      return [];
    } catch (e) {
      print('Error getting current items: $e');
      return [];
    }
  }

    void _clearSelection() {
    try {
      setState(() {
        _selectedItems.clear();
        _selectAll = false;
      });
    } catch (e) {
      print('Error clearing selection: $e');
      // Ensure selection is cleared even if setState fails
      _selectedItems.clear();
      _selectAll = false;
    }
  }

  // Progress tracking methods
  void _startProgressTracking() {
    if (_isTrackingProgress) return;
    
    try {
      setState(() {
        _isTrackingProgress = true;
      });
      
      // Poll for progress every 2 seconds
      _progressTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        try {
          _fetchIngestionProgress();
        } catch (e) {
          print('Error in progress tracking timer: $e');
          // Don't stop tracking on individual errors
        }
      });
    } catch (e) {
      print('Error starting progress tracking: $e');
      setState(() {
        _isTrackingProgress = false;
      });
    }
  }

  void _stopProgressTracking() {
    try {
      _progressTimer?.cancel();
      setState(() {
        _isTrackingProgress = false;
      });
    } catch (e) {
      print('Error stopping progress tracking: $e');
      // Ensure timer is cancelled even if setState fails
      _progressTimer?.cancel();
    }
  }

  Future<void> _fetchIngestionProgress() async {
    if (_ingestionProgress.isEmpty) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      
      if (currentUser?.agencyId == null) return;

      final apiClient = ApiClient();
      final response = await apiClient.get(
        '${ApiEndpoints.batchIngestionProgress}/${currentUser!.agencyId}',
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final recentIngestions = data['recentIngestions'] as List? ?? [];
        
        setState(() {
          for (final ingestion in recentIngestions) {
            try {
              final fileId = ingestion['fileId']?.toString();
              if (fileId != null && fileId.isNotEmpty && _ingestionProgress.containsKey(fileId)) {
                _ingestionProgress[fileId] = _ingestionProgress[fileId]!.copyWith(
                  status: ingestion['status']?.toString() ?? 'unknown',
                  message: _getStatusMessage(ingestion['status']?.toString()),
                  startedAt: ingestion['startedAt'] != null ? DateTime.parse(ingestion['startedAt'].toString()) : null,
                  finishedAt: ingestion['finishedAt'] != null ? DateTime.parse(ingestion['finishedAt'].toString()) : null,
                  error: ingestion['error']?.toString(),
                );
              }
            } catch (e) {
              print('Error updating progress for ingestion: $e');
              // Continue with other ingestions even if one fails
            }
          }
        });
        
        // Check if all ingestions are complete
        final allComplete = _ingestionProgress.values.every((progress) => 
          progress.status == 'succeeded' || progress.status == 'failed' || progress.status == 'skipped'
        );
        
        if (allComplete) {
          _stopProgressTracking();
        }
      }
    } catch (e) {
      print('Error fetching ingestion progress: $e');
    }
  }

  String _getStatusMessage(String? status) {
    if (status == null) return 'Unknown status';
    
    try {
      switch (status.toLowerCase()) {
        case 'queued':
          return 'Queued for processing';
        case 'running':
          return 'Processing file...';
        case 'processing':
          return 'Processing file...';
        case 'uploading':
          return 'Uploading to S3...';
        case 'succeeded':
          return 'Ingestion completed successfully';
        case 'failed':
          return 'Ingestion failed';
        case 'skipped':
          return 'File already ingested';
        default:
          return 'Unknown status: $status';
      }
    } catch (e) {
      print('Error getting status message for status: $status, error: $e');
      return 'Unknown status: $status';
    }
  }

  // Enqueue selected files for ingestion
  Future<void> _enqueueSelectedFilesForIngestion() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select files to enqueue for ingestion'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get the current user's agency ID from the provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser?.agencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agency ID not found. Please ensure you are properly authenticated.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.batchIngestionEnqueue,
        data: {
          'fileIds': _selectedItems.toList(),
          'agencyId': currentUser!.agencyId,
        },
      );

      if (response.statusCode == 202) {
        final data = response.data;
        final queuedCount = data['queued'] ?? 0;
        final skippedCount = data['skipped'] ?? 0;
        final errorCount = data['errors'] ?? 0;

        // Initialize progress tracking for queued files
        final results = data['results'] as List? ?? [];
        for (final result in results) {
          try {
            if (result is Map<String, dynamic> && result['status'] == 'queued') {
              final fileId = result['fileId']?.toString();
              if (fileId != null && fileId.isNotEmpty) {
                final fileName = _getFileNameById(fileId);
                if (fileName.isNotEmpty) {
                  _ingestionProgress[fileId] = IngestionProgress(
                    fileId: fileId,
                    fileName: fileName,
                    status: 'queued',
                    message: 'Queued for processing',
                    startedAt: DateTime.now(),
                  );
                }
              }
            }
          } catch (e) {
            print('Error initializing progress for file result: $e, result: $result');
            // Continue with other files even if one fails
          }
        }

        // Start progress tracking
        _startProgressTracking();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully enqueued $queuedCount files for ingestion. '
              '${skippedCount > 0 ? '$skippedCount skipped (already ingested). ' : ''}'
              '${errorCount > 0 ? '$errorCount errors occurred.' : ''}'
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Don't clear selection yet - keep it to show progress
        // _clearSelection();
      } else {
        throw Exception('Failed to enqueue files: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enqueue files for ingestion: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to get file name by ID
  String _getFileNameById(String fileId) {
    try {
      if (_currentFolder != null) {
        final file = _currentFolder!.contents.firstWhere(
          (item) => item.id == fileId,
          orElse: () => GoogleDriveFile(id: fileId, name: 'Unknown File', mimeType: '', isFolder: false, type: 'file'),
        );
        return file.name.isNotEmpty ? file.name : 'Unknown File';
      } else if (_structure != null) {
        final file = _structure!.rootItems.firstWhere(
          (item) => item.id == fileId,
          orElse: () => GoogleDriveFile(id: fileId, name: 'Unknown File', mimeType: '', isFolder: false, type: 'file'),
        );
        return file.name.isNotEmpty ? file.name : 'Unknown File';
      }
      return 'Unknown File';
    } catch (e) {
      print('Error getting file name for ID $fileId: $e');
      return 'Unknown File';
    }
  }

  // Build progress tracking section
  Widget _buildProgressSection() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ), 
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ingestion Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 12),
            ..._ingestionProgress.values.map((progress) => _buildProgressItem(progress)).toList(),
          ],
        ),
      ),
    );
  }

  // Build individual progress item
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
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  progress.message ?? 'Unknown status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (progress.error != null) ...[
                  SizedBox(height: 4),
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

  Future<void> listenToFileProgress(String fileId, void Function(int percent, String message) onUpdate,) async {
    final uri = Uri.parse(
      'http://https://enable-be-production.up.railway.app/api/v1/google-drive/files/$fileId/progress',
    );
    final request = http.Request('GET', uri);
    final client = http.Client();
    final response = await client.send(request);

    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
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
          },
          onError: (e) {
            print("❌ SSE stream error: $e");
          },
          onDone: () {
            print("✅ SSE stream closed");
            client.close();
          },
        );
  }

  void _readFileContent(String fileId) async {
    try {
      // Show ingestion progress dialog instead of reading content
      final fileName = _getFileNameById(fileId);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Ingest File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to ingest "$fileName" for AI processing?'),
              SizedBox(height: 8),
              Text(
                'This will:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text('• Download the file from Google Drive'),
              Text('• Extract text and images'),
              Text('• Process content with AI agents'),
              Text('• Store results in your knowledge base'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _ingestSingleFile(fileId, fileName);
              },
              child: Text('Start Ingestion'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing ingestion dialog: $e');
      // Fallback to simple ingestion without dialog
      _ingestSingleFile(fileId, 'Unknown File');
    }
  }

  // Ingest a single file with progress tracking
  Future<void> _ingestSingleFile(String fileId, String fileName) async {
    // Get the current user's agency ID from the provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser?.agencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agency ID not found. Please ensure you are properly authenticated.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.batchIngestionEnqueue,
        data: {
          'fileIds': [fileId],
          'agencyId': currentUser!.agencyId,
        },
      );

      if (response.statusCode == 202) {
        final data = response.data;
        final queuedCount = data['queued'] ?? 0;

        if (queuedCount > 0) {
          // Initialize progress tracking for the file
          _ingestionProgress[fileId] = IngestionProgress(
            fileId: fileId,
            fileName: fileName,
            status: 'queued',
            message: 'Queued for processing',
            startedAt: DateTime.now(),
          );

          // Start progress tracking
          _startProgressTracking();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "$fileName" queued for ingestion'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "$fileName" was not queued. It may already be ingested.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to enqueue file: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to queue file for ingestion: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
