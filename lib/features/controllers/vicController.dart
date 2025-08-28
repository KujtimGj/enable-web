import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/vicModel.dart';
import '../../core/failure.dart';

class VICController {
  final ApiClient _apiClient = ApiClient();

  // Get VICs by agency ID (placeholder - would need backend endpoint)
  Future<Either<Failure, List<VICModel>>> getVICsByAgencyId(String agencyId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/vic/$agencyId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final vics = data.map((json) => VICModel.fromJson(json)).toList();
        return Right(vics);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get VICs',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get VICs: $e'));
    }
  }

  // Get VIC by ID (placeholder - would need backend endpoint)
  Future<Either<Failure, VICModel>> getVICById(String vicId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/vic/single/$vicId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final vic = VICModel.fromJson(response.data);
        return Right(vic);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get VIC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get VIC: $e'));
    }
  }

  // Create new VIC (placeholder - would need backend endpoint)
  Future<Either<Failure, VICModel>> createVIC(Map<String, dynamic> vicData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/vic/create';
      final response = await _apiClient.post(endpoint, data: vicData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final vic = VICModel.fromJson(response.data);
        return Right(vic);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to create VIC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create VIC: $e'));
    }
  }

  // Update existing VIC (placeholder - would need backend endpoint)
  Future<Either<Failure, VICModel>> updateVIC(String vicId, Map<String, dynamic> vicData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/vic/update/$vicId';
      final response = await _apiClient.put(endpoint, data: vicData);

      if (response.statusCode == 200) {
        final vic = VICModel.fromJson(response.data);
        return Right(vic);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update VIC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update VIC: $e'));
    }
  }

  // Delete VIC (placeholder - would need backend endpoint)
  Future<Either<Failure, bool>> deleteVIC(String vicId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/vic/delete/$vicId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete VIC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete VIC: $e'));
    }
  }
}
