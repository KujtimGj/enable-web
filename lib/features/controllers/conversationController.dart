import 'package:dartz/dartz.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/failure.dart';

class ConversationController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, List<Map<String, dynamic>>>> getConversationsByAgencyId(String agencyId) async {
    try {
      final response = await _apiClient.get('/conversation/$agencyId');
      
      if (response.statusCode == 200) {
        final decodedData = response.data;
        
        if (decodedData['success'] == true && decodedData['data'] != null) {
          // Handle the case where data might be a List or Map
          List<Map<String, dynamic>> conversations;
          if (decodedData['data'] is List) {
            conversations = List<Map<String, dynamic>>.from(decodedData['data']);
          } else {
            // If it's not a list, try to convert it
            conversations = List<Map<String, dynamic>>.from([decodedData['data']]);
          }
          return Right(conversations);
        } else {
          return Left(ServerFailure(message: decodedData['message'] ?? 'No conversations found'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to fetch conversations'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Error fetching conversations: $e'));
    }
  }

  // Get last 3 conversations by userId (optimized for home screen)
  Future<Either<Failure, List<Map<String, dynamic>>>> getLastConversationsByUserId(String userId) async {
    try {
      final response = await _apiClient.get('/conversation/user/$userId/latest');
      
      if (response.statusCode == 200) {
        final decodedData = response.data;
        
        if (decodedData['success'] == true && decodedData['data'] != null) {
          // Handle the case where data might be a List or Map
          List<Map<String, dynamic>> conversations;
          if (decodedData['data'] is List) {
            conversations = List<Map<String, dynamic>>.from(decodedData['data']);
          } else {
            // If it's not a list, try to convert it
            conversations = List<Map<String, dynamic>>.from([decodedData['data']]);
          }
          return Right(conversations);
        } else {
          return Left(ServerFailure(message: decodedData['message'] ?? 'No conversations found'));
        }
      } else {
        print('ConversationController: Request failed with status ${response.statusCode}');
        return Left(ServerFailure(message: 'Failed to fetch latest conversations'));
      }
    } catch (e) {
      print('ConversationController: Error fetching latest conversations: $e');
      return Left(ServerFailure(message: 'Error fetching latest conversations: $e'));
    }
  }

}
