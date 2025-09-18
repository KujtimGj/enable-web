import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/productModel.dart';
import '../../core/failure.dart';

class ProductController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, List<ProductModel>>> getProductsByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getProducts.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final products = data.map((json) => ProductModel.fromJson(json)).toList();
        return Right(products);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get products',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products: $e'));
    }
  }

  Future<Either<Failure, ProductModel>> getProductById(String productId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/product/single/$productId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(response.data);
        return Right(product);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get product: $e'));
    }
  }

  Future<Either<Failure, ProductModel>> createProduct(Map<String, dynamic> productData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/product/create';
      final response = await _apiClient.post(endpoint, data: productData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final product = ProductModel.fromJson(response.data);
        return Right(product);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to create product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create product: $e'));
    }
  }

  Future<Either<Failure, ProductModel>> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/product/update/$productId';
      final response = await _apiClient.put(endpoint, data: productData);

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(response.data);
        return Right(product);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update product: $e'));
    }
  }

  Future<Either<Failure, bool>> deleteProduct(String productId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/product/delete/$productId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete product',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete product: $e'));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> searchProducts(String query, String agencyId) async {
    try {
      final endpoint = ApiEndpoints.searchProducts;
      final body = {
        'query': query,
        'agencyId': agencyId,
      };

      final response = await _apiClient.post(endpoint, data: body);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> products = data['data']['products'] ?? [];
          return Right(products.cast<Map<String, dynamic>>());
        } else {
          return Left(ServerFailure(
            message: data['message'] ?? 'Search failed',
          ));
        }
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to search products',
        ));
      }
    } catch (e) {
      print('ProductController: Exception in searchProducts: $e');
      return Left(ServerFailure(message: 'Failed to search products: $e'));
    }
  }
}
