import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/failure.dart';
import 'package:enable_web/features/utils/vic_mention_utils.dart';
import 'package:flutter/material.dart';

class IntelligentAgentController {
  final _apiClient = ApiClient();

  /// Send an intelligent query that automatically determines intent and handles VIC mentions
  Future<Either<Failure, Map<String, dynamic>>> sendIntelligentQuery({
    required String userId,
    required String agencyId,
    required String query,
    required String searchMode,
    String? clientId,
    String? existingConversationId,
    BuildContext? context,
  }) async {
    try {
      print("🧠 Intelligent Agent: Processing query: $query");
      
      // If context is provided, extract VIC mentions and enhance the query
      String enhancedQuery = query;
      Map<String, dynamic> vicMentions = {};
      
      if (context != null) {
        try {
          vicMentions = await VICMentionUtils.extractVICMentionsAndPreferences(query, context);
          enhancedQuery = vicMentions['enhancedQuery'] ?? query;
          print("🧠 Intelligent Agent: Enhanced query with VIC preferences: $enhancedQuery");
        } catch (e) {
          print("⚠️ Intelligent Agent: Error extracting VIC mentions: $e");
          // Continue with original query if VIC mention extraction fails
        }
      }

      var body = {
        'query': enhancedQuery.trim(),
        'agencyId': agencyId,
        'userId': userId,
        'searchMode': searchMode,
        if (clientId != null) 'clientId': clientId,
        if (existingConversationId != null) 'conversationId': existingConversationId,
      };
      
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
        final data = response.data as Map<String, dynamic>;
        // Add VIC mention information to the response
        if (vicMentions.isNotEmpty) {
          data['vicMentions'] = vicMentions;
        }
        return Right(data);
      } else if (response.statusCode == 500) {
        return Left(ServerFailure(message: 'AI service temporarily unavailable. Please try again in a few moments.'));
      } else {
        return Left(ServerFailure(message: response.data));
      }
    } catch (e, stackTrace) {
      print("❌ Exception during intelligent agent API call: $e");
      print("📛 StackTrace: $stackTrace");

      if (e is DioException) {
        print("🧵 Dio error response: ${e.response?.data}");
        print("🧵 Dio status: ${e.response?.statusCode}");
        
        if (e.response?.statusCode == 500) {
          return Left(ServerFailure(message: 'AI service is experiencing technical difficulties. Please try again later.'));
        }
        
        return Left(ServerFailure(message: e.response?.data['message'] ?? 'DioException: No message'));
      }

      return Left(ServerFailure(message: e.toString()));
    }
  }

}
