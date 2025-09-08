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

// Import refactored components
import 'package:enable_web/features/models/ingestion_progress.dart';
import 'package:enable_web/features/utils/file_utils.dart';
import 'package:enable_web/features/widgets/google_drive/breadcrumbs_widget.dart';
import 'package:enable_web/features/widgets/google_drive/folder_item_widget.dart';
import 'package:enable_web/features/widgets/google_drive/file_item_widget.dart';
import 'package:enable_web/features/widgets/google_drive/progress_section_widget.dart';
import 'package:enable_web/features/widgets/google_drive/pagination_controls_widget.dart';
import 'package:enable_web/features/services/ingestion_service.dart';
import 'package:enable_web/features/state/google_drive_state.dart';

class GoogleDriveFilesScreen extends StatefulWidget {
  const GoogleDriveFilesScreen({super.key});

  @override
  State<GoogleDriveFilesScreen> createState() => _GoogleDriveFilesScreenState();
}

class _GoogleDriveFilesScreenState extends State<GoogleDriveFilesScreen> {
  final GoogleDriveController _controller = GoogleDriveController();
  late GoogleDriveState _state;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _state = GoogleDriveState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoogleDriveStructure();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _state.dispose();
    super.dispose();
  }

  Future<void> _loadGoogleDriveStructure() async {
    print('🔍 [loadGoogleDriveStructure] Loading Google Drive structure...');
    _state.setLoading(true);
    _state.setError(null);

    try {
      final result = await _controller.getGoogleDriveStructure();
      result.fold(
        (failure) {
          print('❌ [loadGoogleDriveStructure] Failed to load structure: ${failure.toString()}');
          _state.setError(
            failure is ServerFailure
                ? failure.message
                : 'Failed to load Google Drive structure'
          );
          _state.setLoading(false);
        },
        (structure) {
          // Debug logging
          structure.rootItems.forEach((item) {
          });

          _state.setStructure(structure);
          _state.setCurrentFolder(null);
          _state.setCurrentFolderId(null);
          _state.setBreadcrumbs([]);
          _state.setLoading(false);

          // Check ingestion status for root items asynchronously (non-blocking)
          _checkIngestionStatusForItemsAsync(structure.rootItems);
        },
      );
    } catch (e) {
      print('❌ [loadGoogleDriveStructure] Exception occurred: $e');
      _state.setError('Failed to load Google Drive structure: $e');
      _state.setLoading(false);
    }
  }

  Future<void> _openFolder(String folderId, String folderName) async {
    _state.setLoading(true);
    _state.setError(null);
    _state.setCurrentPage(1);
    _state.setHasMoreItems(true);
    _state.clearAllItems();

    try {
      // First, load the initial page to get folder metadata and first batch of items
      final result = await _controller.getFolderContents(folderId, page: _state.currentPage, pageSize: _state.pageSize);
      result.fold(
        (failure) {
          _state.setError(
            failure is ServerFailure
                ? failure.message
                : 'Failed to open folder'
          );
          _state.setLoading(false);
        },
        (folderContents) async {
          // Set the current folder first so we can show the folder name
          _state.setCurrentFolder(folderContents);
          _state.setCurrentFolderId(folderId);
          _state.setBreadcrumbs(folderContents.breadcrumbs);
          _state.setAllItems(List.from(folderContents.contents));
          _state.setHasMoreItems(folderContents.pagination?.hasMore ?? false);

          // If there are more items and we don't have enough folders yet, load more pages
          // until we have a reasonable number of folders or all items are loaded
          if (_state.hasMoreItems && _state.allItems.where((item) => item.isFolder).length < 10) {
            await _loadAllFoldersFirst(folderId);
          }

          _state.setLoading(false);
          // Clear selection when navigating to a new folder
          _state.clearSelection();

          // Check ingestion status for folder contents asynchronously (non-blocking)
          _checkIngestionStatusForItemsAsync(folderContents.contents);
        },
      );
    } catch (e) {
      _state.setError('Failed to open folder: $e');
      _state.setLoading(false);
    }
  }

  Future<void> _loadAllFoldersFirst(String folderId) async {
    _state.setLoadingFolders(true);
    
    // Load additional pages until we have a good number of folders or all items are loaded
    int maxPagesToLoad = 5; // Limit to prevent infinite loading
    int pagesLoaded = 1;
    
    while (_state.hasMoreItems && pagesLoaded < maxPagesToLoad) {
      try {
        _state.setCurrentPage(_state.currentPage + 1);
        final result = await _controller.getFolderContents(folderId, page: _state.currentPage, pageSize: _state.pageSize);
        
        result.fold(
          (failure) {
            // Stop loading on failure
            _state.setHasMoreItems(false);
          },
          (folderContents) {
            _state.addToAllItems(folderContents.contents);
            _state.setHasMoreItems(folderContents.pagination?.hasMore ?? false);
            pagesLoaded++;
          },
        );
        
        // Stop if we have enough folders or no more items
        if (_state.allItems.where((item) => item.isFolder).length >= 20 || !_state.hasMoreItems) {
          break;
        }
      } catch (e) {
        print('Error loading additional pages: $e');
        break;
      }
    }
    
    _state.setLoadingFolders(false);
  }

  void _goToBreadcrumb(String folderId) {
    if (folderId == 'root') {
      // Go back to root
      _state.resetToRoot();
    } else {
      // Navigate to specific folder
      _openFolder(folderId, '');
    }
  }


  List<GoogleDriveFile> _getCurrentItems() {
    if (_state.currentFolder != null) {
      final items = FileUtils.filterItems(_state.currentFolder!.contents, showSharedOnly: _state.showSharedOnly);
      return items;
    } else if (_state.structure != null) {
      final items = FileUtils.filterItems(_state.structure!.rootItems, showSharedOnly: _state.showSharedOnly);
      return items;
    }
    return [];
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
            const SizedBox(height: 16),
            const Text(
              'Google Drive not connected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please connect your Google Drive account to view files',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  googleDriveProvider.isLoading
                      ? null
                      : () => googleDriveProvider.connectGoogleDrive(),
              child: const Text('Connect Google Drive'),
            ),
          ],
        ),
      );
    }

    if (_state.isLoading) {
      return const Center(
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

    if (_state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _state.error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoogleDriveStructure,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_state.currentFolder != null) {
      // Show folder contents
      return Column(
        children: [
          BreadcrumbsWidget(
            breadcrumbs: _state.breadcrumbs,
            onBreadcrumbTap: _goToBreadcrumb,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_state.currentFolder!.folder.name} (${_getCurrentItems().length} of ${_state.currentFolder!.totalItems} items)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Showing folders and documents only (PDF, Word, TXT, PPTX)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (_state.isLoadingFolders) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading more folders...',
                          style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  // Select All Files button
                  ElevatedButton.icon(
                    onPressed: () => _state.toggleSelectAll(_getCurrentItems()),
                    icon: Icon(_state.selectAll ? Icons.check_box : Icons.check_box_outline_blank),
                    label: Text(_state.selectAll ? 'Deselect All Files' : 'Select All Files'),
                  ),
                  const SizedBox(width: 8),
                  if (_state.selectedItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_state.selectedItems.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Enqueue Selected button
                  if (_state.selectedItems.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _enqueueSelectedFilesForIngestion,
                      icon: const Icon(Icons.queue),
                      label: Text('Enqueue Selected (${_state.selectedItems.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  if (_state.selectedItems.isNotEmpty) const SizedBox(width: 8),
                  Text(
                    '${_getCurrentItems().where((item) => item.isFolder).length} folders, ${_getCurrentItems().where((item) => !item.isFolder).length} files',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_state.isLoadingFolders) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(Loading more...)',
                      style: TextStyle(fontSize: 10, color: Colors.blue[600], fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (_state.isCheckingIngestionStatus) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Checking ingestion status...',
                          style: TextStyle(fontSize: 10, color: Colors.blue[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Show ingestion status summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getCurrentItems().where((item) => !item.isFolder && _state.ingestedFiles.contains(item.id)).length} ingested',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.upload_outlined,
                          size: 14,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getCurrentItems().where((item) => !item.isFolder && !_state.ingestedFiles.contains(item.id)).length} available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Debug info
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _openFolder(
                      _state.currentFolder!.folder.id,
                      _state.currentFolder!.folder.name,
                    ),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh folder',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pagination controls
          if (_state.currentFolder != null && _state.currentFolder!.pagination != null) ...[
            PaginationControlsWidget(
              pagination: _state.currentFolder!.pagination,
              isLoadingMore: _state.isLoadingMore,
              onPageChange: _goToPage,
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _state.isLoadingMore
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading page...'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _getCurrentItems().length,
                          itemBuilder: (context, index) {
                            // Sort items to show folders first, then files
                            final sortedItems = List<GoogleDriveFile>.from(
                              _getCurrentItems(),
                            )..sort((a, b) {
                              // Folders first
                              if (a.isFolder && !b.isFolder) return -1;
                              if (!a.isFolder && b.isFolder) return 1;
                              // Then sort by name
                              return a.name.compareTo(b.name);
                            });

                            final item = sortedItems[index];
                            if (item.isFolder) {
                              return FolderItemWidget(
                                folder: item,
                                isSelected: _state.selectedItems.contains(item.id),
                                onTap: () => _openFolder(item.id, item.name),
                                onSelectionToggle: () => _state.toggleItemSelection(item.id),
                              );
                            } else {
                              return FileItemWidget(
                                file: item,
                                isSelected: _state.selectedItems.contains(item.id),
                                isIngested: _state.ingestedFiles.contains(item.id),
                                onSelectionToggle: () => _state.toggleItemSelection(item.id),
                                onIngest: () => _readFileContent(item.id),
                                onOpenInBrowser: item.webViewLink != null ? () => _openFileInBrowser(item.webViewLink!) : null,
                              );
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (_state.structure != null) {
      // Show root structure
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Drive (${_getCurrentItems().length} of ${_state.structure!.totalFiles + _state.structure!.totalFolders} items)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Showing folders and documents only (PDF, Word, TXT, PPTX)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  // Select All Files button
                  ElevatedButton.icon(
                    onPressed: () => _state.toggleSelectAll(_getCurrentItems()),
                    icon: Icon(_state.selectAll ? Icons.check_box : Icons.check_box_outline_blank),
                    label: Text(_state.selectAll ? 'Deselect All Files' : 'Select All Files'),
                  ),
                  if (_state.selectedItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        '${_state.selectedItems.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Enqueue Selected button
                  if (_state.selectedItems.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _enqueueSelectedFilesForIngestion,
                      icon: const Icon(Icons.queue),
                      label: Text('Enqueue Selected (${_state.selectedItems.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  if (_state.selectedItems.isNotEmpty) const SizedBox(width: 8),
                  const SizedBox(width: 16),
                  Text(
                    '${_getCurrentItems().where((item) => item.isFolder).length} folders, ${_getCurrentItems().where((item) => !item.isFolder).length} files',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_state.isCheckingIngestionStatus) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Checking ingestion status...',
                          style: TextStyle(fontSize: 10, color: Colors.blue[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Show ingestion status summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getCurrentItems().where((item) => !item.isFolder && _state.ingestedFiles.contains(item.id)).length} ingested',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.upload_outlined,
                          size: 14,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getCurrentItems().where((item) => !item.isFolder && !_state.ingestedFiles.contains(item.id)).length} available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _loadGoogleDriveStructure,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ), 
          const SizedBox(height: 16),
          Expanded(
            child: _state.isLoadingMore
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading page...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _getCurrentItems().length,
                    itemBuilder: (context, index) {
                      // Sort items to show folders first, then files
                      final sortedItems = List<GoogleDriveFile>.from(
                        _getCurrentItems(),
                      )..sort((a, b) {
                        // Folders first
                        if (a.isFolder && !b.isFolder) return -1;
                        if (!a.isFolder && b.isFolder) return 1;
                        // Then sort by name
                        return a.name.compareTo(b.name);
                      });

                      final item = sortedItems[index];
                      if (item.isFolder) {
                        return FolderItemWidget(
                          folder: item,
                          isSelected: _state.selectedItems.contains(item.id),
                          onTap: () => _openFolder(item.id, item.name),
                          onSelectionToggle: () => _state.toggleItemSelection(item.id),
                        );
                      } else {
                        return FileItemWidget(
                          file: item,
                          isSelected: _state.selectedItems.contains(item.id),
                          isIngested: _state.ingestedFiles.contains(item.id),
                          onSelectionToggle: () => _state.toggleItemSelection(item.id),
                          onIngest: () => _readFileContent(item.id),
                          onOpenInBrowser: item.webViewLink != null ? () => _openFileInBrowser(item.webViewLink!) : null,
                        );
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
          const SizedBox(height: 16),
          const Text(
            'No content available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try refreshing to load your Google Drive content',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGoogleDriveStructure,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _state,
      child: Consumer<GoogleDriveState>(
        builder: (context, state, child) {
          return ResponsiveScaffold(
            body: ResponsiveContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
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
                                state.currentFolder != null
                                    ? 'Google Drive - ${state.currentFolder!.folder.name}'
                                    : 'Google Drive Files',
                                textAlign: TextAlign.start,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress tracking section
                    if (state.ingestionProgress.isNotEmpty) 
                      ProgressSectionWidget(ingestionProgress: state.ingestionProgress),
                    const SizedBox(height: 16),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFileInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open file in browser'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Pagination methods
  Future<void> _goToPage(int page) async {
    if (_state.currentFolderId == null || page == _state.currentPage) return;
    
    _state.setLoadingMore(true);
    _state.setCurrentPage(page);
    
    try {
      final result = await _controller.getFolderContents(_state.currentFolderId!, page: page, pageSize: _state.pageSize);
      result.fold(
        (failure) {
          _state.setLoadingMore(false);
          _state.setCurrentPage(page - 1); // Revert on failure
        },
        (folderContents) {
          // Update the current folder with the new page data
          _state.setCurrentFolder(folderContents);
          _state.setAllItems(List.from(folderContents.contents));
          _state.setHasMoreItems(folderContents.pagination?.hasMore ?? false);
          _state.setLoadingMore(false);
          _state.clearSelection(); // Clear selection when changing pages
        },
      );
    } catch (e) {
      _state.setLoadingMore(false);
      _state.setCurrentPage(page - 1); // Revert on failure
    }
  }

  // Progress tracking methods
  void _startProgressTracking() {
    if (_state.isTrackingProgress) return;
    
    try {
      _state.setTrackingProgress(true);
      
      // Poll for progress every 2 seconds
      _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        try {
          _fetchIngestionProgress();
        } catch (e) {
          print('Error in progress tracking timer: $e');
          // Don't stop tracking on individual errors
        }
      });
    } catch (e) {
      print('Error starting progress tracking: $e');
      _state.setTrackingProgress(false);
    }
  }

  void _stopProgressTracking() {
    try {
      _progressTimer?.cancel();
      _state.setTrackingProgress(false);
    } catch (e) {
      print('Error stopping progress tracking: $e');
      // Ensure timer is cancelled even if setState fails
      _progressTimer?.cancel();
    }
  }

  Future<void> _fetchIngestionProgress() async {
    if (_state.ingestionProgress.isEmpty) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      
      if (currentUser?.agencyId == null) return;

      final data = await IngestionService.fetchIngestionProgress(
        context: context,
        agencyId: currentUser!.agencyId,
      );
      
      final recentIngestions = data['recentIngestions'] as List? ?? [];
      
      IngestionService.updateProgressFromResponse(_state.ingestionProgress, recentIngestions);
      
      // Check if all ingestions are complete
      if (IngestionService.areAllIngestionsComplete(_state.ingestionProgress)) {
        _stopProgressTracking();
      }
    } catch (e) {
      print('Error fetching ingestion progress: $e');
    }
  }

  // Enqueue selected files for ingestion
  Future<void> _enqueueSelectedFilesForIngestion() async {
    if (_state.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select files to enqueue for ingestion'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get the current user's agency ID from the provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      _state.setLoading(true);

      final data = await IngestionService.enqueueFilesForIngestion(
        context: context,
        fileIds: _state.selectedItems,
        agencyId: currentUser.agencyId,
      );

      print('🔍 [enqueueSelectedFiles] Response data: $data');

      final queuedCount = data['queued'] ?? 0;
      final skippedCount = data['skipped'] ?? 0;
      final errorCount = data['errors'] ?? 0;

      // Initialize progress tracking for queued files
      final results = data['results'] as List<dynamic>? ?? [];
      print('🔍 [enqueueSelectedFiles] Results array: $results');
      
      final progressMap = IngestionService.initializeProgressFromResults(
        results,
        _getFileNameById,
      );
      
      // Add progress to state
      for (final entry in progressMap.entries) {
        _state.addIngestionProgress(entry.key, entry.value);
      }

      // Handle skipped files
      for (final result in results) {
        final status = result['status']?.toString();
        final fileId = result['fileId']?.toString();
        
        if (status == 'skipped' && fileId != null) {
          final reason = result['reason']?.toString() ?? 'Unknown reason';
          final fileName = _getFileNameById(fileId);
          _markFileAsIngested(fileId, fileName, reason);
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
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('❌ [enqueueSelectedFiles] Error: $e');
      
      String errorMessage = 'Failed to enqueue files for ingestion';
      if (e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied. Please check your permissions.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      _state.setLoading(false);
    }
  }

  // Helper method to get file name by ID
  String _getFileNameById(String fileId) {
    try {
      print('🔍 [getFileNameById] Looking for file ID: $fileId');
      print('🔍 [getFileNameById] Current folder: ${_state.currentFolder != null}');
      print('🔍 [getFileNameById] Structure: ${_state.structure != null}');
      
      if (_state.currentFolder != null) {
        print('🔍 [getFileNameById] Searching in current folder with ${_state.currentFolder!.contents.length} items');
        final file = _state.currentFolder!.contents.firstWhere(
          (item) => item.id == fileId,
          orElse: () => GoogleDriveFile(id: fileId, name: 'Unknown File', mimeType: '', isFolder: false, type: 'file'),
        );
        print('🔍 [getFileNameById] Found file in current folder: ${file.name}');
        return file.name.isNotEmpty ? file.name : 'Unknown File'; 
      } else if (_state.structure != null) {
        print('🔍 [getFileNameById] Searching in structure with ${_state.structure!.rootItems.length} items');
        final file = _state.structure!.rootItems.firstWhere(
          (item) => item.id == fileId,
          orElse: () => GoogleDriveFile(id: fileId, name: 'Unknown File', mimeType: '', isFolder: false, type: 'file'),
        );
        print('🔍 [getFileNameById] Found file in structure: ${file.name}');
        return file.name.isNotEmpty ? file.name : 'Unknown File';
      }
      print('🔍 [getFileNameById] No current folder or structure available');
      return 'Unknown File';
    } catch (e) {
      print('❌ [getFileNameById] Error getting file name for ID $fileId: $e');
      return 'Unknown File';
    }
  }

  // Check ingestion status for a list of items (asynchronous, non-blocking)
  void _checkIngestionStatusForItemsAsync(List<GoogleDriveFile> items) {
    // Run in background without blocking UI
    Future.microtask(() async {
      try {
        // Get only file items (not folders) and filter out already known ingested files
        final fileItems = items.where((item) => 
          !item.isFolder && !_state.ingestedFiles.contains(item.id)
        ).toList();

        if (fileItems.isEmpty) return;

        // Set loading state
        _state.setCheckingIngestionStatus(true);

        // Limit batch size to avoid overwhelming the API
        const int maxBatchSize = 20;
        final batches = <List<GoogleDriveFile>>[];
        
        for (int i = 0; i < fileItems.length; i += maxBatchSize) {
          final end = (i + maxBatchSize < fileItems.length) ? i + maxBatchSize : fileItems.length;
          batches.add(fileItems.sublist(i, end));
        }

        // Get current user's agency ID
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUser = userProvider.user;
        
        if (currentUser?.agencyId == null) {
          _state.setCheckingIngestionStatus(false);
          return;
        }

        print('🔍 [checkIngestionStatusForItemsAsync] Checking ${fileItems.length} files in ${batches.length} batches');

        // Process each batch with a small delay to avoid overwhelming the server
        for (int i = 0; i < batches.length; i++) {
          final batch = batches[i];
          
          try {
            // Check ingestion status for this batch
            final ingestionStatus = await IngestionService.checkFilesIngestionStatus(
              context: context,
              fileIds: batch.map((item) => item.id).toList(),
              agencyId: currentUser!.agencyId,
            );

            // Update state with ingestion status
            _state.markFilesAsIngested(ingestionStatus);

            print('🔍 [checkIngestionStatusForItemsAsync] Processed batch ${i + 1}/${batches.length} with ${ingestionStatus.length} files');

            // Small delay between batches to avoid overwhelming the server
            if (i < batches.length - 1) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
          } catch (e) {
            print('❌ [checkIngestionStatusForItemsAsync] Error in batch ${i + 1}: $e');
            // Continue with next batch even if one fails
          }
        }

        print('🔍 [checkIngestionStatusForItemsAsync] Completed checking ingestion status for all files');
      } catch (e) {
        print('❌ [checkIngestionStatusForItemsAsync] Error checking ingestion status: $e');
        // Don't show error to user as this is a background operation
      } finally {
        // Always clear loading state
        _state.setCheckingIngestionStatus(false);
      }
    });
  }

  // Mark file as already ingested
  void _markFileAsIngested(String fileId, String fileName, String reason) {
    _state.markFileAsIngested(fileId);
    
    print('🔍 [markFileAsIngested] File $fileName marked as ingested: $reason');
    
    // Show user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File "$fileName" was already ingested ($reason)'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
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
          title: const Text('Ingest File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Do you want to ingest this file for AI processing?'),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _ingestSingleFile(fileId, fileName);
              },
              child: const Text('Start Ingestion'),
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
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      _state.setLoading(true);

      final data = await IngestionService.enqueueFilesForIngestion(
        context: context,
        fileIds: {fileId},
        agencyId: currentUser.agencyId,
      );

      final queuedCount = data['queued'] ?? 0;

      if (queuedCount > 0) {
        // Initialize progress tracking for the file
        _state.addIngestionProgress(fileId, IngestionProgress(
          fileId: fileId,
          fileName: fileName,
          status: 'queued',
          message: 'Queued for processing',
          startedAt: DateTime.now(),
        ));

        // Start progress tracking
        _startProgressTracking();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "$fileName" queued for ingestion'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "$fileName" was not queued. It may already be ingested.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [ingestSingleFile] Error: $e');
      
      String errorMessage = 'Failed to queue file for ingestion';
      if (e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied. Please check your permissions.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      _state.setLoading(false);
    }
  }
}