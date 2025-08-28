import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/failure.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, String>> getGoogleAuthUrl() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.googleDriveAuthUrl);
      
      if (response.statusCode == 200) {
        return Right(response.data['authUrl']);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to get auth URL'
        ));
      }
    } catch (e) {
      print('Error getting Google auth URL: $e');
      return Left(ServerFailure(message: 'Failed to get Google auth URL'));
    }
  }



  Future<Either<Failure, GoogleDriveStructure>> getGoogleDriveStructure() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.googleDriveFiles);
      
      if (response.statusCode == 200) {
        final structure = GoogleDriveStructure.fromJson(response.data);
        return Right(structure);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to fetch Google Drive structure'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch Google Drive structure'));
    }
  }

  Future<Either<Failure, List<GoogleDriveFile>>> getGoogleDriveFiles() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.googleDriveFiles);
      
      if (response.statusCode == 200) {
        final List<dynamic> filesData = response.data['files'] ?? [];
        final files = filesData
            .map((file) => GoogleDriveFile.fromJson(file))
            .toList();
        return Right(files);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to fetch Google Drive files'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch Google Drive files'));
    }
  }

  Future<Either<Failure, FolderContents>> getFolderContents(String folderId) async {
    try {
      final endpoint = ApiEndpoints.googleDriveFolderContents.replaceAll('{folderId}', folderId);
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final folderContents = FolderContents.fromJson(response.data);
        return Right(folderContents);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to fetch folder contents'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch folder contents'));
    }
  }

  Future<Either<Failure, List<GoogleDriveFile>>> getMoreGoogleDriveFiles(String pageToken) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.googleDriveFilesMore}?pageToken=$pageToken'
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> filesData = response.data['files'] ?? [];
        final files = filesData
            .map((file) => GoogleDriveFile.fromJson(file))
            .toList();
        return Right(files);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to fetch more Google Drive files'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch more Google Drive files'));
    }
  }

  Future<Either<Failure, String>> disconnectGoogleDrive() async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.googleDriveDisconnect);
      if (response.statusCode == 200) {
        return Right(response.data['message'] ?? 'Google Drive disconnected successfully');
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to disconnect Google Drive'
        ));
      }
    } catch (e) {
      print('Error disconnecting Google Drive: $e');
      return Left(ServerFailure(message: 'Failed to disconnect Google Drive'));
    }
  }

  Future<Either<Failure, GoogleDriveStatus>> getGoogleDriveStatus() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.googleDriveStatus);
      
      if (response.statusCode == 200) {
        return Right(GoogleDriveStatus.fromJson(response.data));
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to get Google Drive status'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get Google Drive status'));
    }
  }

  Future<void> openGoogleAuth() async {
    try {
      final authUrlResult = await getGoogleAuthUrl();
      
      authUrlResult.fold(
        (failure) {
          print('Failed to get auth URL: $failure');
        },
        (authUrl) async {
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            print('Could not launch URL: $authUrl');
          }
        },
      );
    } catch (e) {
      print('Error opening Google auth: $e');
    }
  }

  Future<Either<Failure, bool>> associateGoogleDriveTokens(String accessToken, String refreshToken, String? expiryDate) async {
    try {
      print('[Controller] Associating tokens with backend...');
      print('[Controller] Access token length: ${accessToken.length}');
      print('[Controller] Refresh token length: ${refreshToken.length}');
      print('[Controller] Expiry date: $expiryDate');
      
      final response = await _apiClient.post(
        ApiEndpoints.googleDriveAssociateTokens,
        data: {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiryDate': expiryDate,
        }
      );
      
      print('[Controller] Response status: ${response.statusCode}');
      print('[Controller] Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final isConnected = response.data['isConnected'] ?? false;
        print('[Controller] Is connected: $isConnected');
        return Right(isConnected);
      } else {
        print('[Controller] Error response: ${response.data}');
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to associate Google Drive tokens'
        ));
      }
    } catch (e) {
      print('[Controller] Exception: $e');
      return Left(ServerFailure(message: 'Failed to associate Google Drive tokens: $e'));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> readGoogleDriveFile(String fileId) async {
    try {
      final endpoint = ApiEndpoints.googleDriveFileContent.replaceAll('{fileId}', fileId);
      final response = await _apiClient.post(endpoint, data: {'agencyId': '6893292ae9ad15f9855b1356'});

      if (response.statusCode == 200) {
        print(response.data);
        final list = List<Map<String, dynamic>>.from(response.data); // ✅ force cast
        return Right(list);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to read Google Drive file',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to read Google Drive file'));
    }
  }

  /// Get Google Drive file preview
  Future<Either<Failure, Map<String, dynamic>>> getGoogleDriveFilePreview(String fileId) async {
    try {
      final endpoint = ApiEndpoints.googleDriveFilePreview.replaceAll('{fileId}', fileId);
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: response.data['error'] ?? 'Failed to get Google Drive file preview'
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get Google Drive file preview'));
    }
  }
} 