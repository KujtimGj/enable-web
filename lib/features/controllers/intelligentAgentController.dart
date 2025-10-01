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

  /// Parse response to determine if it contains clarifying questions
  bool hasClarifyingQuestions(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'];
      return data.containsKey('requiresFollowUp') && data['requiresFollowUp'] == true;
    }
    return false;
  }

  /// Extract missing information from response
  List<String> getMissingInformation(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'];
      if (data.containsKey('searchResults') && 
          data['searchResults'].containsKey('missingInformation')) {
        return List<String>.from(data['searchResults']['missingInformation']);
      }
    }
    return [];
  }

  /// Get query analysis from response
  Map<String, dynamic>? getQueryAnalysis(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'];
      return data.containsKey('queryAnalysis') ? data['queryAnalysis'] : null;
    }
    return null;
  }

  /// Check if response is a specific client search result
  bool isSpecificClientSearch(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'client_info' && 
             queryAnalysis['specificityLevel'] == 'specific';
    }
    return false;
  }

  /// Check if response is a product database query
  bool isProductDatabaseQuery(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'product_database';
    }
    return false;
  }

  /// Check if response is a client preferences query
  bool isClientPreferencesQuery(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'client_preferences';
    }
    return false;
  }

  /// Check if response is a client past trips query
  bool isClientPastTripsQuery(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'client_past_trips';
    }
    return false;
  }

  /// Check if response is a recommendations query
  bool isRecommendationsQuery(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'recommendations';
    }
    return false;
  }

  /// Check if response is a partnerships query
  bool isPartnershipsQuery(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'partnerships';
    }
    return false;
  }

  /// Check if response is an itinerary creation query
  bool isItineraryCreationQuery(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null) {
      return queryAnalysis['intent'] == 'itinerary_creation';
    }
    return false;
  }

  /// Get client preferences from response
  Map<String, dynamic>? getClientPreferences(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null && queryAnalysis.containsKey('vicPreferences')) {
      return queryAnalysis['vicPreferences'];
    }
    return null;
  }

  /// Get query parameters from response
  Map<String, dynamic>? getQueryParameters(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null && queryAnalysis.containsKey('queryParameters')) {
      return queryAnalysis['queryParameters'];
    }
    return null;
  }

  /// Get client names from response
  List<String> getClientNames(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null && queryAnalysis.containsKey('clientNames')) {
      return List<String>.from(queryAnalysis['clientNames']);
    }
    return [];
  }

  /// Get search terms from response
  List<String> getSearchTerms(Map<String, dynamic> response) {
    final queryAnalysis = getQueryAnalysis(response);
    if (queryAnalysis != null && queryAnalysis.containsKey('searchTerms')) {
      return List<String>.from(queryAnalysis['searchTerms']);
    }
    return [];
  }

  /// Get response type for UI rendering
  String getResponseType(Map<String, dynamic> response) {
    if (hasClarifyingQuestions(response)) {
      return 'clarifying_questions';
    } else if (isSpecificClientSearch(response)) {
      return 'specific_client_search';
    } else if (isProductDatabaseQuery(response)) {
      return 'product_database';
    } else if (isClientPreferencesQuery(response)) {
      return 'client_preferences';
    } else if (isClientPastTripsQuery(response)) {
      return 'client_past_trips';
    } else if (isRecommendationsQuery(response)) {
      return 'recommendations';
    } else if (isPartnershipsQuery(response)) {
      return 'partnerships';
    } else if (isItineraryCreationQuery(response)) {
      return 'itinerary_creation';
    } else {
      return 'general_response';
    }
  }

}
