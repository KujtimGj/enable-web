import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/failure.dart';
import 'package:enable_web/features/entities/dropbox.dart';

class DropboxController {
  final ApiClient _apiClient = ApiClient();

  /// Get Dropbox OAuth URL for authentication
  Future<Either<Failure, String>> getDropboxAuthUrl() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dropboxAuthUrl);
      if (response.statusCode == 200) {
        print(response.data);
        return Right(response.data['authUrl']);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to get Dropbox auth URL'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get Dropbox auth URL'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> handleDropboxCallback(String code) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.dropboxCallback}?code=$code'
      );
      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to connect Dropbox'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to connect Dropbox'));
    }
  }

  Future<Either<Failure, List<DropboxFile>>> getDropboxFiles() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dropboxFiles);
      if (response.statusCode == 200) {
        final List<dynamic> filesData = response.data['files'] ?? [];
        final files = filesData
            .map((file) => DropboxFile.fromJson(file))
            .toList();
        return Right(files);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to fetch Dropbox files'
        ));
      }
    } catch (e) {
      print('Error getting Dropbox files: $e');
      return Left(ServerFailure(message: 'Failed to fetch Dropbox files'));
    }
  }

  Future<Either<Failure, bool>> associateDropboxTokens(String tokenId) async {

    try {
      final response = await _apiClient.post(
        ApiEndpoints.dropboxAssociateTokens,
        data: {'tokenId': tokenId}
      );
      if (response.statusCode == 200) {
        return Right(response.data['isConnected'] ?? false);
      } else {
        print(response.statusCode);
        print(response.data);
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to associate Dropbox tokens'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to associate Dropbox tokens'));
    }
  }

  Future<Either<Failure, DropboxStatus>> getDropboxStatus() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dropboxStatus);
      if (response.statusCode == 200) {
        return Right(DropboxStatus.fromJson(response.data));
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to get Dropbox status'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get Dropbox status'));
    }
  }
} 