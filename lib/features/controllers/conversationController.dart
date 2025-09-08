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
        
        if (decodedData['success'] == true) {
          final conversations = List<Map<String, dynamic>>.from(decodedData['data']);
          return Right(conversations);
        } else {
          return Left(ServerFailure(message: decodedData['message'] ?? 'Failed to fetch conversations'));
        }
      } else {
        return Left(ServerFailure(message: 'Failed to fetch conversations'));
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      return Left(ServerFailure(message: 'Error fetching conversations: $e'));
    }
  }

}
