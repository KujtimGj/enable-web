import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String baseUrl = 'http://localhost:3000/api/v1'; // [[memory:4118946]]
  
  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create a new bookmark
  Future<Map<String, dynamic>> createBookmark({
    required String userId,
    required String agencyId,
    required String itemType,
    required String itemId,
    String? vicId,
    String? notes,
  }) async {
    try {
      print('BookmarkService: createBookmark called');
      final headers = await _getHeaders();
      final body = {
        'userId': userId,
        'agencyId': agencyId,
        'itemType': itemType,
        'itemId': itemId,
        if (vicId != null) 'vicId': vicId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      print('BookmarkService: Request body: $body');
      print('BookmarkService: Headers: $headers');
      print('BookmarkService: URL: $baseUrl/bookmark');

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('BookmarkService: Response status: ${response.statusCode}');
      print('BookmarkService: Response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create bookmark: ${response.body}');
      }
    } catch (e) {
      print('BookmarkService: Error: $e');
      throw Exception('Error creating bookmark: $e');
    }
  }

  // Get user's bookmarks
  Future<Map<String, dynamic>> getUserBookmarks({
    required String userId,
    required String agencyId,
    String? itemType,
    String? vicId,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'userId': userId,
        'agencyId': agencyId,
        if (itemType != null) 'itemType': itemType,
        if (vicId != null) 'vicId': vicId,
      };

      final uri = Uri.parse('$baseUrl/bookmark/user').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get bookmarks: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting bookmarks: $e');
    }
  }

  // Get bookmarks by VIC
  Future<Map<String, dynamic>> getBookmarksByVic({
    required String vicId,
    required String agencyId,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'vicId': vicId,
        'agencyId': agencyId,
      };

      final uri = Uri.parse('$baseUrl/bookmark/vic').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get VIC bookmarks: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting VIC bookmarks: $e');
    }
  }

  // Check if an item is bookmarked
  Future<Map<String, dynamic>> checkBookmarkStatus({
    required String userId,
    required String itemType,
    required String itemId,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'userId': userId,
        'itemType': itemType,
        'itemId': itemId,
      };

      final uri = Uri.parse('$baseUrl/bookmark/check').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check bookmark status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking bookmark status: $e');
    }
  }

  // Update a bookmark
  Future<Map<String, dynamic>> updateBookmark({
    required String bookmarkId,
    String? vicId,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      
      if (vicId != null) body['vicId'] = vicId;
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        Uri.parse('$baseUrl/bookmark/$bookmarkId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update bookmark: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating bookmark: $e');
    }
  }

  // Delete a bookmark
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/bookmark/$bookmarkId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete bookmark: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting bookmark: $e');
    }
  }

  // Get a specific bookmark by ID
  Future<Map<String, dynamic>> getBookmarkById(String bookmarkId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/bookmark/$bookmarkId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get bookmark: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting bookmark: $e');
    }
  }

  // Test endpoint to verify backend connectivity
  Future<Map<String, dynamic>> testBackend() async {
    try {
      print('BookmarkService: Testing backend connectivity...');
      final response = await http.get(
        Uri.parse('$baseUrl/bookmark/test'),
      );

      print('BookmarkService: Test response status: ${response.statusCode}');
      print('BookmarkService: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backend test failed: ${response.body}');
      }
    } catch (e) {
      print('BookmarkService: Backend test error: $e');
      throw Exception('Backend test error: $e');
    }
  }
}
