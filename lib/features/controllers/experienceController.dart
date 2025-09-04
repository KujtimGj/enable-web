import 'package:dartz/dartz.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/experienceModel.dart';
import '../../core/failure.dart';

class ExperienceController {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, List<ExperienceModel>>> getExperiencesByAgencyId(String agencyId) async {
    try {
      final endpoint = ApiEndpoints.getExperiences.replaceFirst('{agencyId}', agencyId);

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final experiences = data.map((json) => ExperienceModel.fromJson(json)).toList();
        return Right(experiences);
      } else {
        print('API Error: ${response.statusCode} - ${response.data}');
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get experiences',
        ));
      }
    } catch (e) {
      print('Exception in getExperiencesByAgencyId: $e');
      return Left(ServerFailure(message: 'Failed to get experiences: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> getExperienceById(String experienceId) async {
    try { 
      final endpoint = '/experience/single/$experienceId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get experience',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get experience: $e'));
    }
  }

  Future<Either<Failure, List<ExperienceModel>>> getExperiencesByVicId(String vicId) async {
    try {
      final endpoint = '/experience/vic/$vicId';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final experiences = data.map((json) => ExperienceModel.fromJson(json)).toList();
        return Right(experiences);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to get experiences by VIC',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get experiences by VIC: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> createExperience(Map<String, dynamic> experienceData) async {
    try {
      final endpoint = '/experience/create';
      final response = await _apiClient.post(endpoint, data: experienceData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to create experience',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create experience: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> updateExperience(String experienceId, Map<String, dynamic> experienceData) async {
    try {
      final endpoint = '/experience/update/$experienceId';
      final response = await _apiClient.put(endpoint, data: experienceData);

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update experience',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update experience: $e'));
    }
  }

  Future<Either<Failure, bool>> deleteExperience(String experienceId) async {
    try {
      final endpoint = '/experience/delete/$experienceId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete experience',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete experience: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> updateExperienceStatus(String experienceId, String status) async {
    try {
      final endpoint = '/experience/$experienceId/status';
      final response = await _apiClient.put(endpoint, data: {'status': status});

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update experience status',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update experience status: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> addItineraryItem(String experienceId, Map<String, dynamic> itineraryItem) async {
    try {
      final endpoint = '/experience/$experienceId/itinerary';
      final response = await _apiClient.post(endpoint, data: itineraryItem);

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to add itinerary item',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to add itinerary item: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> updateItineraryItem(String experienceId, String itemId, Map<String, dynamic> updateData) async {
    try {
      final endpoint = '/experience/$experienceId/itinerary/$itemId';
      final response = await _apiClient.put(endpoint, data: updateData);

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to update itinerary item',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update itinerary item: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> deleteItineraryItem(String experienceId, String itemId) async {
    try {
      final endpoint = '/experience/$experienceId/itinerary/$itemId';
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to delete itinerary item',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete itinerary item: $e'));
    }
  }

  Future<Either<Failure, ExperienceModel>> reorderItinerary(String experienceId, List<Map<String, dynamic>> itinerary) async {
    try {
      final endpoint = '/experience/$experienceId/itinerary/reorder';
      final response = await _apiClient.put(endpoint, data: {'itinerary': itinerary});

      if (response.statusCode == 200) {
        final experience = ExperienceModel.fromJson(response.data);
        return Right(experience);
      } else {
        return Left(ServerFailure(
          message: response.data['message'] ?? 'Failed to reorder itinerary',
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to reorder itinerary: $e'));
    }
  }
}
