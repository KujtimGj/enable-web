import 'package:file_picker/file_picker.dart';
import 'package:enable_web/features/controllers/agencyController.dart';
import 'package:enable_web/features/entities/agency.dart';
import 'package:dartz/dartz.dart';
import '../../core/failure.dart';

class FileUploadService {
  final AgencyController _agencyController = AgencyController();

  /// Upload a file to an agency
  /// 
  /// [agencyId] - The ID of the agency to upload the file to
  /// 
  /// Returns either a Failure or the uploaded file information
  Future<Either<Failure, Map<String, dynamic>>> uploadFileToAgency(
    String agencyId,
  ) async {
    try {
      // Pick a file using file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return Left(ServerFailure(message: 'No file selected'));
      }

      final file = result.files.first;
      
      if (file.bytes == null) {
        return Left(ServerFailure(message: 'Failed to read file'));
      }

      // Upload the file using the agency controller
      return await _agencyController.uploadFileToAgency(file, agencyId);
    } catch (e) {
      return Left(ServerFailure(message: 'Error uploading file: $e'));
    }
  }

  /// Get all files for an agency
  /// 
  /// [agencyId] - The ID of the agency to get files for
  /// 
  /// Returns either a Failure or the list of files
  Future<Either<Failure, List<AgencyFile>>> getAgencyFiles(String agencyId) async {
    return await _agencyController.getAgencyFiles(agencyId);
  }

  /// Delete a file from an agency
  /// 
  /// [agencyId] - The ID of the agency
  /// [fileId] - The ID of the file to delete
  /// 
  /// Returns either a Failure or success message
  Future<Either<Failure, String>> deleteAgencyFile(
    String agencyId,
    String fileId,
  ) async {
    return await _agencyController.deleteAgencyFile(agencyId, fileId);
  }

  /// Get a user-friendly error message from a failure
  String getFailureMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Server error occurred';
    } else if (failure is OfflineFailure) {
      return failure.message ?? 'Network error occurred';
    } else if (failure is NotFoundFailure) {
      return failure.message ?? 'Resource not found';
    } else if (failure is UnauthorizedFailure) {
      return failure.message ?? 'Unauthorized access';
    } else {
      return 'An error occurred';
    }
  }
} 