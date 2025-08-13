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
      'query': query,
      if (clientId != null) 'clientId': clientId,
      if (conversationId != null) 'conversationId': conversationId,
    };
    final String endpoint = '${ApiEndpoints.chatWithAgentUrl}/$userId/$agencyId';

    final response = await _apiClient.post(endpoint, data: body);

    if (response.statusCode == 200) {
      return Right(response.data as Map<String,
          dynamic>);
    } else {
      return Left(ServerFailure(message: response.data));
    }
  } catch (e, stackTrace) {
    print("❌ Exception during chat API call: $e");
    print("📛 StackTrace: $stackTrace");

    if (e is DioException) {
      print("🧵 Dio error response: ${e.response?.data}");
      print("🧵 Dio status: ${e.response?.statusCode}");
      return Left(ServerFailure(message: e.response?.data['message'] ?? 'DioException: No message'));
    }

    return Left(ServerFailure(message: e.toString()));
  }

}}