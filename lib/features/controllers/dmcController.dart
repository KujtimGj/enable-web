import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/dmcModel.dart';
import '../../core/failure.dart';

class DMCController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, List<DMC>>> getDMCsByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getDMCs.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final dmcs = data.map((json) => DMC.fromJson(json)).toList();
        return Right(dmcs);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get DMCs',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get DMCs: $e'));
    }
  }

  Future<Either<Failure, DMC>> getDMCById(String dmcId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/dmc/single/$dmcId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final dmc = DMC.fromJson(response.data);
        return Right(dmc);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get DMC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get DMC: $e'));
    }
  }

  Future<Either<Failure, DMC>> createDMC(Map<String, dynamic> dmcData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/dmc/create';
      final response = await _apiClient.post(endpoint, data: dmcData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dmc = DMC.fromJson(response.data);
        return Right(dmc);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to create DMC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create DMC: $e'));
    }
  }

  Future<Either<Failure, DMC>> updateDMC(String dmcId, Map<String, dynamic> dmcData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/dmc/update/$dmcId';
      final response = await _apiClient.put(endpoint, data: dmcData);

      if (response.statusCode == 200) {
        final dmc = DMC.fromJson(response.data);
        return Right(dmc);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update DMC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update DMC: $e'));
    }
  }

  Future<Either<Failure, bool>> deleteDMC(String dmcId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/dmc/delete/$dmcId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete DMC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete DMC: $e'));
    }
  }
}
