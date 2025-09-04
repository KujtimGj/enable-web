import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:enable_web/features/models/ingestion_progress.dart';

class GoogleDriveState extends ChangeNotifier {
  // Core state
  GoogleDriveStructure? _structure;
  FolderContents? _currentFolder;
  List<Breadcrumb> _breadcrumbs = [];
  bool _isLoading = false;
  String? _error;
  String? _currentFolderId;
  bool _showSharedOnly = false;
  
  // Selection state
  Set<String> _selectedItems = {};
  bool _selectAll = false;
  
  // Progress tracking state
  Map<String, IngestionProgress> _ingestionProgress = {};
  bool _isTrackingProgress = false;
  Set<String> _ingestedFiles = {};
  bool _isCheckingIngestionStatus = false;
  
  // Pagination state
  int _currentPage = 1;
  int _pageSize = 50;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;
  bool _isLoadingFolders = false;
  List<GoogleDriveFile> _allItems = [];

  // Getters
  GoogleDriveStructure? get structure => _structure;
  FolderContents? get currentFolder => _currentFolder;
  List<Breadcrumb> get breadcrumbs => _breadcrumbs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentFolderId => _currentFolderId;
  bool get showSharedOnly => _showSharedOnly;
  Set<String> get selectedItems => _selectedItems;
  bool get selectAll => _selectAll;
  Map<String, IngestionProgress> get ingestionProgress => _ingestionProgress;
  bool get isTrackingProgress => _isTrackingProgress;
  Set<String> get ingestedFiles => _ingestedFiles;
  bool get isCheckingIngestionStatus => _isCheckingIngestionStatus;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasMoreItems => _hasMoreItems;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingFolders => _isLoadingFolders;
  List<GoogleDriveFile> get allItems => _allItems;

  // Core state methods
  void setStructure(GoogleDriveStructure? structure) {
    _structure = structure;
    notifyListeners();
  }

  void setCurrentFolder(FolderContents? folder) {
    _currentFolder = folder;
    notifyListeners();
  }

  void setBreadcrumbs(List<Breadcrumb> breadcrumbs) {
    _breadcrumbs = breadcrumbs;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setCurrentFolderId(String? folderId) {
    _currentFolderId = folderId;
    notifyListeners();
  }

  void setShowSharedOnly(bool show) {
    _showSharedOnly = show;
    notifyListeners();
  }

  // Selection methods
  void toggleItemSelection(String itemId) {
    try {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
      _updateSelectAllState();
      notifyListeners();
    } catch (e) {
      print('Error toggling item selection: $e');
      // Ensure selection is updated even if setState fails
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
      _updateSelectAllState();
      notifyListeners();
    }
  }

  void toggleSelectAll(List<GoogleDriveFile> currentItems) {
    try {
      if (_selectAll) {
        _selectedItems.clear();
        _selectAll = false;
      } else {
        // Only select files, not folders, and not already ingested
        final fileItems = currentItems.where((item) => 
          !item.isFolder && !_ingestedFiles.contains(item.id)
        ).toList();
        _selectedItems = Set.from(fileItems.map((item) => item.id));
        _selectAll = true;
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling select all: $e');
      // Ensure selection is updated even if setState fails
      if (_selectAll) {
        _selectedItems.clear();
        _selectAll = false;
      } else {
        final fileItems = currentItems.where((item) => 
          !item.isFolder && !_ingestedFiles.contains(item.id)
        ).toList();
        _selectedItems = Set.from(fileItems.map((item) => item.id));
        _selectAll = true;
      }
      notifyListeners();
    }
  }

  void _updateSelectAllState() {
    // This method will be called by the UI component that has access to current items
    // since we don't want to pass currentItems to every call
  }

  void updateSelectAllState(List<GoogleDriveFile> currentItems) {
    try {
      // Only consider files for select all state, excluding ingested files
      final fileItems = currentItems.where((item) => 
        !item.isFolder && !_ingestedFiles.contains(item.id)
      ).toList();
      if (fileItems.isEmpty) {
        _selectAll = false;
      } else {
        _selectAll = _selectedItems.length == fileItems.length;
      }
      notifyListeners();
    } catch (e) {
      print('Error updating select all state: $e');
      // Ensure state is updated even if there's an error
      _selectAll = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    try {
      _selectedItems.clear();
      _selectAll = false;
      notifyListeners();
    } catch (e) {
      print('Error clearing selection: $e');
      // Ensure selection is cleared even if setState fails
      _selectedItems.clear();
      _selectAll = false;
      notifyListeners();
    }
  }

  // Progress tracking methods
  void addIngestionProgress(String fileId, IngestionProgress progress) {
    _ingestionProgress[fileId] = progress;
    notifyListeners();
  }

  void updateIngestionProgress(String fileId, IngestionProgress progress) {
    _ingestionProgress[fileId] = progress;
    notifyListeners();
  }

  void setTrackingProgress(bool tracking) {
    _isTrackingProgress = tracking;
    notifyListeners();
  }

  void markFileAsIngested(String fileId) {
    _ingestedFiles.add(fileId);
    // Remove from selected items if it was selected
    _selectedItems.remove(fileId);
    notifyListeners();
  }

  void markFilesAsIngested(Map<String, bool> ingestionStatus) {
    for (final entry in ingestionStatus.entries) {
      if (entry.value) {
        _ingestedFiles.add(entry.key);
        // Remove from selected items if it was selected
        _selectedItems.remove(entry.key);
      }
    }
    notifyListeners();
  }

  void clearIngestedFiles() {
    _ingestedFiles.clear();
    notifyListeners();
  }

  void setCheckingIngestionStatus(bool checking) {
    _isCheckingIngestionStatus = checking;
    notifyListeners();
  }

  void clearIngestionProgress() {
    _ingestionProgress.clear();
    notifyListeners();
  }

  // Pagination methods
  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void setPageSize(int size) {
    _pageSize = size;
    notifyListeners();
  }

  void setHasMoreItems(bool hasMore) {
    _hasMoreItems = hasMore;
    notifyListeners();
  }

  void setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void setLoadingFolders(bool loading) {
    _isLoadingFolders = loading;
    notifyListeners();
  }

  void setAllItems(List<GoogleDriveFile> items) {
    _allItems = items;
    notifyListeners();
  }

  void addToAllItems(List<GoogleDriveFile> items) {
    _allItems.addAll(items);
    notifyListeners();
  }

  void clearAllItems() {
    _allItems.clear();
    notifyListeners();
  }

  // Reset methods
  void resetToRoot() {
    _currentFolder = null;
    _currentFolderId = null;
    _breadcrumbs = [];
    _allItems.clear();
    _currentPage = 1;
    _hasMoreItems = true;
    clearSelection();
    notifyListeners();
  }

  void resetAll() {
    _structure = null;
    _currentFolder = null;
    _breadcrumbs = [];
    _isLoading = false;
    _error = null;
    _currentFolderId = null;
    _showSharedOnly = false;
    _selectedItems.clear();
    _selectAll = false;
    _ingestionProgress.clear();
    _isTrackingProgress = false;
    _ingestedFiles.clear();
    _currentPage = 1;
    _pageSize = 50;
    _hasMoreItems = true;
    _isLoadingMore = false;
    _isLoadingFolders = false;
    _allItems.clear();
    notifyListeners();
  }
}
