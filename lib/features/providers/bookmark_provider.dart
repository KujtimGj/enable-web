import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/bookmark_service.dart';

class BookmarkModel {
  final String id;
  final String userId;
  final String agencyId;
  final String itemType;
  final String itemId;
  final String? vicId;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic item; // The actual item data
  final dynamic vic; // VIC data if assigned

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.agencyId,
    required this.itemType,
    required this.itemId,
    this.vicId,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.item,
    this.vic,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      agencyId: json['agencyId'] ?? '',
      itemType: json['itemType'] ?? '',
      itemId: json['itemId'] ?? '',
      vicId: json['vicId']?['_id'] ?? json['vicId'],
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      item: json['item'],
      vic: json['vicId'] is Map ? json['vicId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'agencyId': agencyId,
      'itemType': itemType,
      'itemId': itemId,
      'vicId': vicId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'item': item,
      'vic': vic,
    };
  }
}

class BookmarkProvider extends ChangeNotifier {
  final BookmarkService _bookmarkService = BookmarkService();
  
  List<BookmarkModel> _bookmarks = [];
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _bookmarkStatusCache = {}; // Cache for bookmark status
  
  // Multi-select state
  Set<String> _selectedItems = {}; // Set of "itemType_itemId" keys
  bool _isMultiSelectMode = false;

  // Getters
  List<BookmarkModel> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get selectedItems => _selectedItems;
  bool get isMultiSelectMode => _isMultiSelectMode;
  int get selectedCount => _selectedItems.length;

  // Check if an item is bookmarked (with caching)
  bool isItemBookmarked(String itemType, String itemId) {
    final key = '${itemType}_$itemId';
    return _bookmarkStatusCache[key] ?? false;
  }

  // Get bookmark for a specific item
  BookmarkModel? getBookmarkForItem(String itemType, String itemId) {
    try {
      return _bookmarks.firstWhere(
        (bookmark) => bookmark.itemType == itemType && bookmark.itemId == itemId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get bookmarks by type
  List<BookmarkModel> getBookmarksByType(String itemType) {
    return _bookmarks.where((bookmark) => bookmark.itemType == itemType).toList();
  }

  // Get bookmarks by VIC
  List<BookmarkModel> getBookmarksByVic(String vicId) {
    return _bookmarks.where((bookmark) => bookmark.vicId == vicId).toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Get current user data
  Future<Map<String, String?>> _getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        return {
          'userId': userMap['_id'] ?? userMap['id'],
          'agencyId': userMap['agencyId'],
        };
      }
      return {};
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  // Create a bookmark
  Future<bool> createBookmark({
    required String itemType,
    required String itemId,
    String? vicId,
    String? notes,
  }) async {
    try {
      print('BookmarkProvider: createBookmark called for $itemType:$itemId');
      _setLoading(true);
      _setError(null);

      final userData = await _getCurrentUserData();
      final userId = userData['userId'];
      final agencyId = userData['agencyId'];
      

      if (userId == null || agencyId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _bookmarkService.createBookmark(
        userId: userId,
        agencyId: agencyId,
        itemType: itemType,
        itemId: itemId,
        vicId: vicId,
        notes: notes,
      );

      print('BookmarkProvider: Service response: $response');

      if (response['bookmark'] != null) {
        final newBookmark = BookmarkModel.fromJson(response['bookmark']);
        _bookmarks.add(newBookmark);
        
        // Update cache
        final key = '${itemType}_$itemId';
        _bookmarkStatusCache[key] = true;
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create bookmark: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a bookmark
  Future<bool> deleteBookmark(String bookmarkId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _bookmarkService.deleteBookmark(bookmarkId);
      
      // Remove from local list
      final bookmark = _bookmarks.firstWhere((b) => b.id == bookmarkId);
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
      
      // Update cache
      final key = '${bookmark.itemType}_${bookmark.itemId}';
      _bookmarkStatusCache[key] = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete bookmark: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle bookmark (create if not exists, delete if exists)
  Future<bool> toggleBookmark({
    required String itemType,
    required String itemId,
    String? vicId,
    String? notes,
  }) async {
    try {
      final existingBookmark = getBookmarkForItem(itemType, itemId);
      
      if (existingBookmark != null) {
        // Delete existing bookmark
        return await deleteBookmark(existingBookmark.id);
      } else {
        // Create new bookmark
        return await createBookmark(
          itemType: itemType,
          itemId: itemId,
          vicId: vicId,
          notes: notes,
        );
      }
    } catch (e) {
      _setError('Failed to toggle bookmark: $e');
      return false;
    }
  }

  // Update a bookmark
  Future<bool> updateBookmark({
    required String bookmarkId,
    String? vicId,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _bookmarkService.updateBookmark(
        bookmarkId: bookmarkId,
        vicId: vicId,
        notes: notes,
      );

      if (response['bookmark'] != null) {
        final updatedBookmark = BookmarkModel.fromJson(response['bookmark']);
        final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
        
        if (index != -1) {
          _bookmarks[index] = updatedBookmark;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update bookmark: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch user's bookmarks
  Future<void> fetchUserBookmarks({String? itemType, String? vicId}) async {
    try {
      _setLoading(true);
      _setError(null);

      final userData = await _getCurrentUserData();
      final userId = userData['userId'];
      final agencyId = userData['agencyId'];

      if (userId == null || agencyId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _bookmarkService.getUserBookmarks(
        userId: userId,
        agencyId: agencyId,
        itemType: itemType,
        vicId: vicId,
      );

      if (response['bookmarks'] != null) {
        _bookmarks = (response['bookmarks'] as List)
            .map((json) => BookmarkModel.fromJson(json))
            .toList();
        
        // Update cache
        _bookmarkStatusCache.clear();
        for (final bookmark in _bookmarks) {
          final key = '${bookmark.itemType}_${bookmark.itemId}';
          _bookmarkStatusCache[key] = true;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to fetch bookmarks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check bookmark status for multiple items
  Future<void> checkBookmarkStatuses(List<Map<String, String>> items) async {
    try {
      final userData = await _getCurrentUserData();
      final userId = userData['userId'];

      if (userId == null) return;

      for (final item in items) {
        final itemType = item['itemType']!;
        final itemId = item['itemId']!;
        final key = '${itemType}_$itemId';

        // Skip if already cached
        if (_bookmarkStatusCache.containsKey(key)) continue;

        try {
          final response = await _bookmarkService.checkBookmarkStatus(
            userId: userId,
            itemType: itemType,
            itemId: itemId,
          );

          _bookmarkStatusCache[key] = response['isBookmarked'] ?? false;
        } catch (e) {
          print('Error checking bookmark status for $key: $e');
          _bookmarkStatusCache[key] = false;
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error checking bookmark statuses: $e');
    }
  }

  // Multi-select methods
  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode) {
      _selectedItems.clear();
    }
    notifyListeners();
  }

  void toggleItemSelection(String itemType, String itemId) {
    final key = '${itemType}_$itemId';
    if (_selectedItems.contains(key)) {
      _selectedItems.remove(key);
    } else {
      _selectedItems.add(key);
    }
    notifyListeners();
  }

  bool isItemSelected(String itemType, String itemId) {
    final key = '${itemType}_$itemId';
    return _selectedItems.contains(key);
  }

  void selectAllItems(List<Map<String, String>> items) {
    _selectedItems.clear();
    for (final item in items) {
      final key = '${item['itemType']}_${item['itemId']}';
      _selectedItems.add(key);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }

  List<Map<String, String>> getSelectedItemsData() {
    return _selectedItems.map((key) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final itemType = parts[0];
        final itemId = parts.sublist(1).join('_'); // Handle IDs with underscores
        return {'itemType': itemType, 'itemId': itemId};
      }
      return {'itemType': '', 'itemId': ''};
    }).where((item) => item['itemType']!.isNotEmpty && item['itemId']!.isNotEmpty).toList();
  }

  // Bulk bookmark operations
  Future<bool> bulkCreateBookmarks({
    String? vicId,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final selectedItemsData = getSelectedItemsData();
      if (selectedItemsData.isEmpty) {
        _setError('No items selected');
        return false;
      }

      final userData = await _getCurrentUserData();
      final userId = userData['userId'];
      final agencyId = userData['agencyId'];

      if (userId == null || agencyId == null) {
        throw Exception('User not authenticated');
      }

      // Create bookmarks for all selected items
      final results = await Future.wait(
        selectedItemsData.map((item) => _bookmarkService.createBookmark(
          userId: userId,
          agencyId: agencyId,
          itemType: item['itemType']!,
          itemId: item['itemId']!,
          vicId: vicId,
          notes: notes,
        )),
      );

      // Update local state
      for (final result in results) {
        if (result['bookmark'] != null) {
          final newBookmark = BookmarkModel.fromJson(result['bookmark']);
          _bookmarks.add(newBookmark);
          
          // Update cache
          final key = '${newBookmark.itemType}_${newBookmark.itemId}';
          _bookmarkStatusCache[key] = true;
        }
      }

      // Clear selection and exit multi-select mode
      _selectedItems.clear();
      _isMultiSelectMode = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create bookmarks: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> bulkDeleteBookmarks() async {
    try {
      _setLoading(true);
      _setError(null);

      final selectedItemsData = getSelectedItemsData();
      if (selectedItemsData.isEmpty) {
        _setError('No items selected');
        return false;
      }

      // Find existing bookmarks for selected items
      final bookmarksToDelete = <BookmarkModel>[];
      for (final item in selectedItemsData) {
        final bookmark = getBookmarkForItem(item['itemType']!, item['itemId']!);
        if (bookmark != null) {
          bookmarksToDelete.add(bookmark);
        }
      }

      // Delete bookmarks
      await Future.wait(
        bookmarksToDelete.map((bookmark) => _bookmarkService.deleteBookmark(bookmark.id)),
      );

      // Update local state
      for (final bookmark in bookmarksToDelete) {
        _bookmarks.removeWhere((b) => b.id == bookmark.id);
        
        // Update cache
        final key = '${bookmark.itemType}_${bookmark.itemId}';
        _bookmarkStatusCache[key] = false;
      }

      // Clear selection and exit multi-select mode
      _selectedItems.clear();
      _isMultiSelectMode = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete bookmarks: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Test backend connectivity
  Future<bool> testBackend() async {
    try {
      print('BookmarkProvider: Testing backend connectivity...');
      final result = await _bookmarkService.testBackend();
      print('BookmarkProvider: Backend test result: $result');
      return true;
    } catch (e) {
      print('BookmarkProvider: Backend test failed: $e');
      _setError('Backend test failed: $e');
      return false;
    }
  }

  // Clear all data
  void clear() {
    _bookmarks.clear();
    _bookmarkStatusCache.clear();
    _selectedItems.clear();
    _isMultiSelectMode = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
