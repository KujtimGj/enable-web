import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:enable_web/core/dio_api.dart';
import '../../core/api.dart';
import '../../core/failure.dart';

class SearchModeController {
  final _apiClient = ApiClient();

  Future<Either<Failure, Map<String, dynamic>>> sendSearchWithMode({
    required String userId,
    required String agencyId,
    required String query,
    required String searchMode,
    String? clientId,
    String? conversationId,
  }) async {
    try {
      var body = {
        'query': query.trim(),
        'agencyId': agencyId,
        'searchMode': searchMode,
        'userId': userId,
        if (clientId != null) 'clientId': clientId,
        if (conversationId != null) 'conversationId': conversationId,
      };
      
      // Ensure the body is properly serialized
      final jsonBody = jsonEncode(body);
      final String endpoint = ApiEndpoints.searchModeUrl;
      Response? response;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          response = await _apiClient.post(endpoint, data: body);
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // Re-throw the last error
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        }
      }

      if (response == null) {
        return Left(ServerFailure(message: 'Failed to get response after $maxRetries attempts'));
      }


      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 500) {
        return Left(ServerFailure(message: 'AI service temporarily unavailable. Please try again in a few moments.'));
      } else {
        return Left(ServerFailure(message: response.data));
      }
    } catch (e, stackTrace) {
      print("❌ Exception during search mode API call: $e");
      print("📛 StackTrace: $stackTrace");

      if (e is DioException) {
        print("🧵 Dio error response: ${e.response?.data}");
        print("🧵 Dio status: ${e.response?.statusCode}");
        
        // Check if it's the specific JSON parsing error from backend
        if (e.response?.statusCode == 500) {
          return Left(ServerFailure(message: 'AI service is experiencing technical difficulties. Please try again later.'));
        }
        
        return Left(ServerFailure(message: e.response?.data['message'] ?? 'DioException: No message'));
      }

      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Get all conversations for a user
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserConversations({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final String endpoint = "${ApiEndpoints.searchModeUrl}/conversations/$userId?limit=$limit&offset=$offset";
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['conversations'] != null) {
          return Right(List<Map<String, dynamic>>.from(data['conversations']));
        } else {
          return Left(ServerFailure(message: data['message'] ?? 'Failed to get conversations'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to get conversations: ${response.statusCode}'));
      }
    } catch (e) {
      print("❌ Get conversations error: $e");
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Get a specific conversation
  Future<Either<Failure, Map<String, dynamic>>> getConversation({
    required String conversationId,
  }) async {
    try {
      final String endpoint = "${ApiEndpoints.searchModeUrl}/conversation/$conversationId";
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['conversation'] != null) {
          return Right(data['conversation']);
        } else {
          return Left(ServerFailure(message: data['message'] ?? 'Failed to get conversation'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to get conversation: ${response.statusCode}'));
      }
    } catch (e) {
      print("❌ Get conversation error: $e");
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Update conversation name
  Future<Either<Failure, Map<String, dynamic>>> updateConversationName({
    required String conversationId,
    required String name,
  }) async {
    try {
      final String endpoint = "${ApiEndpoints.searchModeUrl}/conversation/$conversationId/name";
      final response = await _apiClient.put(endpoint, data: {'name': name});
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Right(data);
        } else {
          return Left(ServerFailure(message: data['message'] ?? 'Failed to update conversation name'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to update conversation name: ${response.statusCode}'));
      }
    } catch (e) {
      print("❌ Update conversation name error: $e");
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Delete a conversation
  Future<Either<Failure, Map<String, dynamic>>> deleteConversation({
    required String conversationId,
  }) async {
    try {
      final String endpoint = "${ApiEndpoints.searchModeUrl}/conversation/$conversationId";
      final response = await _apiClient.delete(endpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Right(data);
        } else {
          return Left(ServerFailure(message: data['message'] ?? 'Failed to delete conversation'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to delete conversation: ${response.statusCode}'));
      }
    } catch (e) {
      print("❌ Delete conversation error: $e");
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Get conversation statistics
  Future<Either<Failure, Map<String, dynamic>>> getConversationStats({
    required String userId,
  }) async {
    try {
      final String endpoint = "${ApiEndpoints.searchModeUrl}/conversations/$userId/stats";
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['stats'] != null) {
          return Right(data['stats']);
        } else {
          return Left(ServerFailure(message: data['message'] ?? 'Failed to get conversation stats'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to get conversation stats: ${response.statusCode}'));
      }
    } catch (e) {
      print("❌ Get conversation stats error: $e");
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
