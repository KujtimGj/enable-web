import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/features/models/ingestion_progress.dart';

class IngestionService {
  static Future<Map<String, dynamic>> enqueueFilesForIngestion({
    required BuildContext context,
    required Set<String> fileIds,
    required String agencyId,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    print('🔍 [enqueueFilesForIngestion] User: ${currentUser?.email}');
    print('🔍 [enqueueFilesForIngestion] Agency ID: $agencyId');
    print('🔍 [enqueueFilesForIngestion] Is Authenticated: ${userProvider.isAuthenticated}');
    print('🔍 [enqueueFilesForIngestion] Token: ${userProvider.token != null ? "Present" : "Missing"}');
    
    if (currentUser == null) {
      throw Exception('User data not found. Please log in again.');
    }

    if (agencyId.isEmpty) {
      throw Exception('Agency ID not found. Please ensure you are properly authenticated.');
    }

    if (!userProvider.isAuthenticated || userProvider.token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    print('🔍 [enqueueFilesForIngestion] Making API request to: ${ApiEndpoints.batchIngestionEnqueue}');
    print('🔍 [enqueueFilesForIngestion] Request data: ${{
      'fileIds': fileIds.toList(),
      'agencyId': agencyId,
    }}');

    final apiClient = ApiClient();
    final response = await apiClient.post(
      ApiEndpoints.batchIngestionEnqueue,
      data: {
        'fileIds': fileIds.toList(),
        'agencyId': agencyId,
      },
    );

    print('🔍 [enqueueFilesForIngestion] Response status: ${response.statusCode}');
    print('🔍 [enqueueFilesForIngestion] Response data: ${response.data}');
    
    if (response.statusCode == 202) {
      final data = response.data;
      
      // Validate response structure
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected Map but got ${data.runtimeType}');
      }
      
      // Ensure results array exists
      if (!data.containsKey('results')) {
        print('⚠️ [enqueueFilesForIngestion] Warning: response missing results array');
        data['results'] = [];
      }
      
      return data;
    } else {
      throw Exception('Failed to enqueue files: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchIngestionProgress({
    required BuildContext context,
    required String agencyId,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser?.agencyId == null) {
      throw Exception('Agency ID not found');
    }

    final apiClient = ApiClient();
    final response = await apiClient.get(
      '${ApiEndpoints.batchIngestionProgress}/$agencyId',
    );
    
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to fetch progress: ${response.statusCode}');
    }
  }

  static String getStatusMessage(String? status) {
    if (status == null) return 'Unknown status';
    
    try {
      switch (status.toLowerCase()) {
        case 'queued':
          return 'Queued for processing';
        case 'running':
          return 'Processing file...';
        case 'processing':
          return 'Processing file...';
        case 'uploading':
          return 'Uploading to S3...';
        case 'succeeded':
          return 'Ingestion completed successfully';
        case 'failed':
          return 'Ingestion failed';
        case 'skipped':
          return 'File already ingested';
        case 'ingested':
          return 'Ingestion completed successfully';
        case 'pending':
          return 'Queued for processing';
        default:
          return 'Unknown status: $status';
      }
    } catch (e) {
      print('Error getting status message for status: $status, error: $e');
      return 'Unknown status: $status';
    }
  }

  static Map<String, IngestionProgress> initializeProgressFromResults(
    List<dynamic> results,
    String Function(String) getFileNameById,
  ) {
    final progressMap = <String, IngestionProgress>{};
    
    // Safety check for empty results
    if (results.isEmpty) {
      print('⚠️ [initializeProgressFromResults] Results is empty');
      return progressMap;
    }
    
    for (final result in results) {
      try {
        print('🔍 [initializeProgressFromResults] Processing result: $result');
        
        // Safety check for result type
        if (result == null) {
          print('⚠️ [initializeProgressFromResults] Skipping null result');
          continue;
        }
        
        if (result is! Map) {
          print('⚠️ [initializeProgressFromResults] Skipping non-Map result: ${result.runtimeType}');
          continue;
        }
        
        final status = result['status']?.toString();
        final fileId = result['fileId']?.toString();
        
        if (fileId != null && fileId.isNotEmpty) {
          final fileName = getFileNameById(fileId);
          print('🔍 [initializeProgressFromResults] File ID: $fileId, Status: $status, Name: $fileName');
          
          if (status == 'queued') {
            if (fileName.isNotEmpty) {
              progressMap[fileId] = IngestionProgress(
                fileId: fileId,
                fileName: fileName,
                status: 'queued',
                message: 'Queued for processing',
                startedAt: DateTime.now(),
              );
            }
          }
        }
      } catch (e) {
        print('❌ [initializeProgressFromResults] Error initializing progress for file result: $e, result: $result');
        // Continue with other files even if one fails
      }
    }
    
    return progressMap;
  }

  static void updateProgressFromResponse(
    Map<String, IngestionProgress> progressMap,
    List<dynamic> recentIngestions,
  ) {
    for (final ingestion in recentIngestions) {
      try {
        final fileId = ingestion['fileId']?.toString();
        if (fileId != null && fileId.isNotEmpty && progressMap.containsKey(fileId)) {
          // Use progressMessage from backend if available, otherwise fall back to default message
          final progressMessage = ingestion['progressMessage']?.toString() ?? 
                                 getStatusMessage(ingestion['status']?.toString());
          
          progressMap[fileId] = progressMap[fileId]!.copyWith(
            status: ingestion['status']?.toString() ?? 'unknown',
            message: progressMessage,
            startedAt: ingestion['startedAt'] != null ? DateTime.parse(ingestion['startedAt'].toString()) : null,
            finishedAt: ingestion['finishedAt'] != null ? DateTime.parse(ingestion['finishedAt'].toString()) : null,
            error: ingestion['error']?.toString(),
          );
        }
      } catch (e) {
        print('Error updating progress for ingestion: $e');
        // Continue with other ingestions even if one fails
      }
    }
  }

  static bool areAllIngestionsComplete(Map<String, IngestionProgress> progressMap) {
    return progressMap.values.every((progress) => 
      progress.status == 'succeeded' || 
      progress.status == 'failed' || 
      progress.status == 'skipped' ||
      progress.status == 'ingested'
    );
  }

  /// Check if specific files have been ingested by their IDs
  static Future<Map<String, bool>> checkFilesIngestionStatus({
    required BuildContext context,
    required List<String> fileIds,
    required String agencyId,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser?.agencyId == null) {
      throw Exception('Agency ID not found');
    }

    if (!userProvider.isAuthenticated || userProvider.token == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final apiClient = ApiClient();
    final response = await apiClient.post(
      ApiEndpoints.batchIngestionCheckFiles,
      data: {
        'fileIds': fileIds,
        'agencyId': agencyId,
      },
    );
    
    if (response.statusCode == 200) {
      final data = response.data;
      final Map<String, bool> ingestionStatus = {};
      
      // Parse the response to create a map of fileId -> isIngested
      if (data['ingestionStatus'] is Map) {
        final statusMap = data['ingestionStatus'] as Map<String, dynamic>;
        statusMap.forEach((fileId, status) {
          // A file is considered ingested if its status is 'ingested' or 'succeeded'
          ingestionStatus[fileId] = status == 'ingested' || status == 'succeeded';
        });
      }
      
      return ingestionStatus;
    } else {
      throw Exception('Failed to check ingestion status: ${response.statusCode}');
    }
  }
}
