import 'dart:convert';

import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/agency.dart';
import 'package:dartz/dartz.dart';
import 'package:enable_web/features/entities/dmcModel.dart';
import 'package:enable_web/features/entities/productModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/failure.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class AgencyController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, Map<String, dynamic>>> uploadFileToAgency(PlatformFile file, String agencyId,) async {
    try {

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
        'agencyId': agencyId,
      });

      final response = await _apiClient.postMultipart(
        ApiEndpoints.uploadFileToAgency,
        formData: formData,
      );


      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to upload file',
        ));
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return Left(ServerFailure(
          message: 'API endpoint not found. Please check if the backend routes are properly configured.',
        ));
      }
      return Left(ServerFailure(message: 'Failed to upload file'));
    }
  }

  Future<Either<Failure, List<AgencyFile>>> getAgencyFiles(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getAgencyFiles.replaceFirst('{agencyId}', agencyId);

      final response = await _apiClient.get(endpoint);


      if (response.statusCode == 200) {
        final List<dynamic> filesJson = response.data['files'] ?? [];
        final files = filesJson
            .map((fileJson) => AgencyFile.fromJson(fileJson))
            .toList();
        return Right(files);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to get agency files',
        ));
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return Left(ServerFailure(
          message: 'API endpoint not found. Please check if the backend routes are properly configured.',
        ));
      }
      return Left(ServerFailure(message: 'Failed to get agency files'));
    }
  }

  Future<Either<Failure, AgencyModel>> createAgency(AgencyModel agencyModel) async {
    try {
      var body = agencyModel.toJson();

      final endpoint = ApiEndpoints.registerAgency.replaceFirst(ApiEndpoints.baseUrl, '');

      final response = await _apiClient.post(endpoint, data: body);

      if (response.statusCode == 200) {
        final agency = AgencyModel.fromJson(response.data);
        return Right(agency);
      } else {
        return Left(ServerFailure(message: "❌ Failure: ${response.data}"));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(message: "Dio error: ${e.response?.data ?? e.message}"));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, AgencyModel>> loginAgency(String email, String password) async {
    try {
      final endpoint = ApiEndpoints.loginUrl.replaceFirst(ApiEndpoints.baseUrl, '');
      final body = {
        'email': email.trim(),
        'password': password.trim(),
      };

      final response = await _apiClient.post(endpoint, data: body);
      final decodedData = response.data;

      if (response.statusCode == 200) {
        final agencyJson = decodedData['agency'];
        final token = decodedData['token'];

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('agency', jsonEncode(agencyJson));
        prefs.setString('token', token);

        final agencyModel = AgencyModel.fromJson(agencyJson);
        return Right(agencyModel);
      } else {
        return Left(ServerFailure(message: decodedData['message'] ?? 'Login failed'));
      }
    } catch (e) {
      if (e is DioException) {
        return Left(ServerFailure(message: e.response?.data.toString() ?? 'Login failed'));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }


  Future<Either<Failure, String>> deleteAgencyFile(String agencyId, String fileId,) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteAgencyFile
            .replaceFirst('{agencyId}', agencyId)
            .replaceFirst('{fileId}', fileId),
      );

      if (response.statusCode == 200) {
        return Right(response.data['message'] ?? 'File deleted successfully');
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to delete file',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete file'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getAgencyProducts(
    String agencyId, {
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('${ApiEndpoints.baseUrl}/agency/products/$agencyId?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        // Handle both old format (direct array) and new format (with pagination)
        if (response.data is List) {
          // Old format - backward compatibility
          final List<dynamic> data = response.data;
          return Right({
            'products': data.map((json) => ProductModel.fromJson(json)).toList(),
            'pagination': {
              'currentPage': 1,
              'totalPages': 1,
              'totalCount': data.length,
              'limit': data.length,
              'hasMore': false,
            }
          });
        } else {
          // New format with pagination
          final List<dynamic> productsJson = response.data['products'];
          return Right({
            'products': productsJson.map((json) => ProductModel.fromJson(json)).toList(),
            'pagination': response.data['pagination'],
          });
        }
      } else {
        print("Failure: ${response.data}");
        return Left(ServerFailure(message: 'Failed to fetch products: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Error occurred: $e'));
    }
  }

  Future<Either<Failure,List<DMC>>> getDMCs(String agencyId) async{
    try{
      final apiClient = ApiClient();
      final response = await apiClient.get('${ApiEndpoints.baseUrl}/dmc/$agencyId');
      if(response.statusCode==200){
        final List<dynamic> data = response.data;
        final dmcs = data.map((json)=>DMC.fromJson(json)).toList();
        return Right(dmcs);
      }else{
        print("Failure: ${response.data}");
        return Left(ServerFailure(message: "Failed to fetch DMCs: ${response.statusCode}"));
      }
    }catch(e){
      return Left(ServerFailure(message: "Error occured: $e"));
    }
  }

  Future<Either<Failure, Map<String, int>>> getDocumentCount(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getDocumentCount.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        return Right({
          'dmcCount': data['dmcCount'] ?? 0,
          'productCount': data['productCount'] ?? 0,
          'experienceCount': data['experienceCount'] ?? 0,
          'externalProductCount': data['externalProductCount'] ?? 0,
          'serviceProviderCount': data['serviceProviderCount'] ?? 0,
        });
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get document count',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get document count: $e'));
    }
  }

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

  Future<Either<Failure, List<Map<String, dynamic>>>> getExternalProductsByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getExternalProducts.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get external products',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get external products: $e'));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getServiceProvidersByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getServiceProviders.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get service providers',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get service providers: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getExperiencesByAgencyId(
    String agencyId, {
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final endpoint = '${ApiEndpoints.getExperiences.replaceFirst('{agencyId}', agencyId)}?page=$page&limit=$limit';

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        // Handle both old format (direct array) and new format (with pagination)
        if (response.data is List) {
          // Old format - backward compatibility
          final List<dynamic> data = response.data;
          return Right({
            'experiences': data.cast<Map<String, dynamic>>(),
            'pagination': {
              'currentPage': 1,
              'totalPages': 1,
              'totalCount': data.length,
              'limit': data.length,
              'hasMore': false,
            }
          });
        } else {
          // New format with pagination
          return Right({
            'experiences': (response.data['experiences'] as List).cast<Map<String, dynamic>>(),
            'pagination': response.data['pagination'],
          });
        }
      } else {
        print('AgencyController: Error response: ${response.data}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get experiences',
        ));
      }
    } catch (e) {
      print('AgencyController: Exception in getExperiencesByAgencyId: $e');
      return Left(ServerFailure(message: 'Failed to get experiences: $e'));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> searchExperiences(String query, String agencyId) async {
    try {
      final endpoint = ApiEndpoints.searchExperiences;
      final body = {
        'query': query,
        'agencyId': agencyId,
      };

      final response = await _apiClient.post(endpoint, data: body);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> experiences = data['data']['experiences'] ?? [];
          return Right(experiences.cast<Map<String, dynamic>>());
        } else {
          return Left(ServerFailure(
            message: data['message'] ?? 'Search failed',
          ));
        }
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to search experiences',
        ));
      }
    } catch (e) {
      print('AgencyController: Exception in searchExperiences: $e');
      return Left(ServerFailure(message: 'Failed to search experiences: $e'));
    }
  }
}
