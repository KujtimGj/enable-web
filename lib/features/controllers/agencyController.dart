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
      print('📤 Sending to backend: $body');

      final endpoint = ApiEndpoints.registerAgency.replaceFirst(ApiEndpoints.baseUrl, '');
      print('🌐 POST $endpoint');

      final response = await _apiClient.post(endpoint, data: body);

      print('✅ Status Code: ${response.statusCode}');
      print('✅ Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final agency = AgencyModel.fromJson(response.data);
        return Right(agency);
      } else {
        return Left(ServerFailure(message: "❌ Failure: ${response.data}"));
      }
    } on DioException catch (e) {
      print('❌ DioException');
      print('↪ status: ${e.response?.statusCode}');
      print('↪ data: ${e.response?.data}');
      print('↪ headers: ${e.response?.headers}');
      return Left(ServerFailure(message: "Dio error: ${e.response?.data ?? e.message}"));
    } catch (e) {
      print('❌ Unknown error: $e');
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

  Future<Either<Failure, List<ProductModel>>> getAgencyProducts(String agencyId) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('${ApiEndpoints.baseUrl}/agency/products/$agencyId');
      if (response.statusCode == 200) {
        // Parse the response data as a list of products
        final List<dynamic> data = response.data;
        final products = data.map((json) => ProductModel.fromJson(json)).toList();
        return Right(products);
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

  Future<Either<Failure, List<Map<String, dynamic>>>> getExperiencesByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getExperiences.replaceFirst('{agencyId}', agencyId);
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get experiences',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get experiences: $e'));
    }
  }
}
