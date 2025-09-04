import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:enable_web/core/dio_api.dart';
import '../../core/api.dart';
import '../../core/failure.dart';

class AIController{
final _apiClient= ApiClient();

Future<Either<Failure, Map<String, dynamic>>> sendChatToAgent({required String userId, required String agencyId, required String query, String? clientId, String? conversationId}) async {
  try {
    var body = {
      'query': query.trim(),
    };
    
    // Ensure the body is properly serialized
    final jsonBody = jsonEncode(body);
    print("🔍 Debug: JSON body: $jsonBody");
    final String endpoint = '${ApiEndpoints.chatWithAgentUrl}/$userId/$agencyId';
    Response? response;
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print("🔍 Debug: Attempt ${retryCount + 1} of $maxRetries");
        response = await _apiClient.post(endpoint, data: body);
        break; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        print("🔍 Debug: Attempt $retryCount failed: $e");
        
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

    print("🔍 Debug: Response status: ${response.statusCode}");
    print("🔍 Debug: Response data: ${response.data}");

    if (response.statusCode == 200) {
      return Right(response.data as Map<String,
          dynamic>);
    } else if (response.statusCode == 500) {
      // Backend error - likely OpenAI API issue
      print("🔍 Debug: Backend returned 500 - likely OpenAI API issue");
      return Left(ServerFailure(message: 'AI service temporarily unavailable. Please try again in a few moments.'));
    } else {
      return Left(ServerFailure(message: response.data));
    }
  } catch (e, stackTrace) {
    print("❌ Exception during chat API call: $e");
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

}}