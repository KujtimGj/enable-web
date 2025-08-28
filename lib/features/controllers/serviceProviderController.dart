import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/serviceProviderModel.dart';
import '../../core/failure.dart';

class ServiceProviderController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, List<ServiceProviderModel>>> getServiceProvidersByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getServiceProviders.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final serviceProviders = data.map((json) => ServiceProviderModel.fromJson(json)).toList();
        return Right(serviceProviders);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get service providers',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get service providers: $e'));
    }
  }

  Future<Either<Failure, ServiceProviderModel>> getServiceProviderById(String serviceProviderId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/service-provider/single/$serviceProviderId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final serviceProvider = ServiceProviderModel.fromJson(response.data);
        return Right(serviceProvider);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get service provider',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get service provider: $e'));
    }
  }

  Future<Either<Failure, ServiceProviderModel>> createServiceProvider(Map<String, dynamic> serviceProviderData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/service-provider/create';
      final response = await _apiClient.post(endpoint, data: serviceProviderData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final serviceProvider = ServiceProviderModel.fromJson(response.data);
        return Right(serviceProvider);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to create service provider',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create service provider: $e'));
    }
  }

  Future<Either<Failure, ServiceProviderModel>> updateServiceProvider(String serviceProviderId, Map<String, dynamic> serviceProviderData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/service-provider/update/$serviceProviderId';
      final response = await _apiClient.put(endpoint, data: serviceProviderData);

      if (response.statusCode == 200) {
        final serviceProvider = ServiceProviderModel.fromJson(response.data);
        return Right(serviceProvider);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update service provider',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update service provider: $e'));
    }
  }

  Future<Either<Failure, bool>> deleteServiceProvider(String serviceProviderId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/service-provider/delete/$serviceProviderId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete service provider',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete service provider: $e'));
    }
  }
}
