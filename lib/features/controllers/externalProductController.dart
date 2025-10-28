import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/externalProductModel.dart';
import '../../core/failure.dart';

class ExternalProductController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, List<ExternalProductModel>>> getExternalProductsByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getExternalProducts.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final externalProducts = data.map((json) => ExternalProductModel.fromJson(json)).toList();
        return Right(externalProducts);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get external products',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get external products: $e'));
    }
  }

  Future<Either<Failure, ExternalProductModel>> getExternalProductById(String externalProductId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/external-product/single/$externalProductId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final externalProduct = ExternalProductModel.fromJson(response.data);
        return Right(externalProduct);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get external product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get external product: $e'));
    }
  }

  Future<Either<Failure, ExternalProductModel>> createExternalProduct(Map<String, dynamic> externalProductData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/external-product/create';
      final response = await _apiClient.post(endpoint, data: externalProductData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final externalProduct = ExternalProductModel.fromJson(response.data);
        return Right(externalProduct);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to create external product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create external product: $e'));
    }
  }

  Future<Either<Failure, ExternalProductModel>> updateExternalProduct(String externalProductId, Map<String, dynamic> externalProductData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/external-product/update/$externalProductId';
      final response = await _apiClient.put(endpoint, data: externalProductData);

      if (response.statusCode == 200) {
        final externalProduct = ExternalProductModel.fromJson(response.data);
        return Right(externalProduct);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update external product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update external product: $e'));
    }
  }

  Future<Either<Failure, bool>> deleteExternalProduct(String externalProductId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/external-product/delete/$externalProductId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete external product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete external product: $e'));
    }
  }

  // Save external product from Google Places
  Future<Either<Failure, ExternalProductModel>> saveExternalProductFromPlaces({
    required Map<String, dynamic> place,
    required String userId,
    required String agencyId,
  }) async {
    try {
      final endpoint = '/external-product/save';
      final response = await _apiClient.post(
        endpoint,
        data: {
          'place': place,
          'userId': userId,
          'agencyId': agencyId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final externalProduct = ExternalProductModel.fromJson(response.data['externalProduct']);
        return Right(externalProduct);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to save external product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to save external product: $e'));
    }
  }
}
