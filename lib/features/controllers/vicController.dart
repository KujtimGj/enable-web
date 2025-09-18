import 'package:dartz/dartz.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/features/entities/vicModel.dart';
import '../../core/failure.dart';
import 'dart:convert';

class VICController {
  final ApiClient _apiClient = ApiClient();

  // Get VICs by agency ID (placeholder - would need backend endpoint)
  Future<Either<Failure, List<VICModel>>> getVICsByAgencyId(String agencyId) async {
    try {
      // Note: This endpoint would need to be added to the backend
      final endpoint = '/vic/agency/$agencyId';
      print('VICController: Making request to endpoint: $endpoint');
      final response = await _apiClient.get(endpoint);

      print('VICController: Response status: ${response.statusCode}');
      print('VICController: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('VICController: Response data type: ${data.runtimeType}');
        
        // Handle the response data properly for web
        List<dynamic> vicsList;
        if (data is List) {
          vicsList = data;
        } else {
          // If it's not a list, try to convert it
          vicsList = List<dynamic>.from(data);
        }
        
        // Convert each item to Map<String, dynamic> safely
        final vics = <VICModel>[];
        for (int i = 0; i < vicsList.length; i++) {
          try {
            final item = vicsList[i];
            print('VICController: Processing item $i, type: ${item.runtimeType}');
            
            Map<String, dynamic> jsonMap;
            if (item is Map<String, dynamic>) {
              jsonMap = item;
            } else {
              // Convert JSObject to Map using json encode/decode
              final jsonString = jsonEncode(item);
              jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            }
            
            final vic = VICModel.fromJson(jsonMap);
            vics.add(vic);
          } catch (e) {
            print('VICController: Error processing item $i: $e');
            // Skip this item and continue
          }
        }
        
        print('VICController: Successfully parsed ${vics.length} VICs');
        return Right(vics);
      } else {
        print('VICController: Request failed with status ${response.statusCode}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get VICs',
        ));
      }
    } catch (e) {
      print('VICController: Exception in getVICsByAgencyId: $e');
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
        final vic = VICModel.fromJson(response.data as Map<String, dynamic>);
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
        final vic = VICModel.fromJson(response.data as Map<String, dynamic>);
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
        final vic = VICModel.fromJson(response.data as Map<String, dynamic>);
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

  Future<Either<Failure, List<Map<String, dynamic>>>> searchVICs(String query, String agencyId) async {
    try {
      final endpoint = ApiEndpoints.searchVICs;
      final body = {
        'query': query,
        'agencyId': agencyId,
      };

      print('VICController: Making search request to endpoint: $endpoint');
      final response = await _apiClient.post(endpoint, data: body);

      print('VICController: Search response status: ${response.statusCode}');
      print('VICController: Search response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('VICController: Search response data type: ${data.runtimeType}');
        
        // Convert response data to Map safely
        Map<String, dynamic> responseMap;
        if (data is Map<String, dynamic>) {
          responseMap = data;
        } else {
          // Convert JSObject to Map using json encode/decode
          final jsonString = jsonEncode(data);
          responseMap = jsonDecode(jsonString) as Map<String, dynamic>;
        }
        
        if (responseMap['success'] == true && responseMap['data'] != null) {
          final dataSection = responseMap['data'];
          final List<dynamic> vicsList = dataSection['vics'] ?? [];
          
          // Convert each VIC to Map<String, dynamic> safely
          final List<Map<String, dynamic>> vics = <Map<String, dynamic>>[];
          for (int i = 0; i < vicsList.length; i++) {
            try {
              final item = vicsList[i];
              Map<String, dynamic> jsonMap;
              if (item is Map<String, dynamic>) {
                jsonMap = item;
              } else {
                // Convert JSObject to Map using json encode/decode
                final jsonString = jsonEncode(item);
                jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
              }
              vics.add(jsonMap);
            } catch (e) {
              print('VICController: Error processing search result item $i: $e');
              // Skip this item and continue
            }
          }
          
          print('VICController: Successfully parsed ${vics.length} search results');
          return Right(vics);
        } else {
          return Left(ServerFailure(
            message: responseMap['message'] ?? 'Search failed',
          ));
        }
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to search VICs',
        ));
      }
    } catch (e) {
      print('VICController: Exception in searchVICs: $e');
      return Left(ServerFailure(message: 'Failed to search VICs: $e'));
    }
  }
}
