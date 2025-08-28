import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/experienceController.dart';
import 'package:enable_web/features/entities/experienceModel.dart';
import 'package:enable_web/core/failure.dart';

class ExperienceProvider extends ChangeNotifier {
  final ExperienceController _experienceController = ExperienceController();
  
  List<ExperienceModel> _experiences = [];
  ExperienceModel? _selectedExperience;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ExperienceModel> get experiences => _experiences;
  ExperienceModel? get selectedExperience => _selectedExperience;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected experience
  void setSelectedExperience(ExperienceModel? experience) {
    _selectedExperience = experience;
    notifyListeners();
  }

  // Fetch experiences by agency ID
  Future<void> fetchExperiencesByAgencyId(String agencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.getExperiencesByAgencyId(agencyId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (experiences) {
          _experiences = experiences;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get experience by ID
  Future<void> fetchExperienceById(String experienceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.getExperienceById(experienceId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (experience) {
          _selectedExperience = experience;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get experiences by VIC ID
  Future<void> fetchExperiencesByVicId(String vicId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.getExperiencesByVicId(vicId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (experiences) {
          _experiences = experiences;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new experience
  Future<bool> createExperience(Map<String, dynamic> experienceData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.createExperience(experienceData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (experience) {
          _experiences.add(experience);
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing experience
  Future<bool> updateExperience(String experienceId, Map<String, dynamic> experienceData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.updateExperience(experienceId, experienceData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExperience) {
          final index = _experiences.indexWhere((exp) => exp.id == experienceId);
          if (index != -1) {
            _experiences[index] = updatedExperience;
          }
          if (_selectedExperience?.id == experienceId) {
            _selectedExperience = updatedExperience;
          }
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update experience status
  Future<bool> updateExperienceStatus(String experienceId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.updateExperienceStatus(experienceId, status);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExperience) {
          final index = _experiences.indexWhere((exp) => exp.id == experienceId);
          if (index != -1) {
            _experiences[index] = updatedExperience;
          }
          if (_selectedExperience?.id == experienceId) {
            _selectedExperience = updatedExperience;
          }
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete experience
  Future<bool> deleteExperience(String experienceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.deleteExperience(experienceId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (success) {
          if (success) {
            _experiences.removeWhere((exp) => exp.id == experienceId);
            if (_selectedExperience?.id == experienceId) {
              _selectedExperience = null;
            }
          }
          return success;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add itinerary item
  Future<bool> addItineraryItem(String experienceId, Map<String, dynamic> itineraryItem) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.addItineraryItem(experienceId, itineraryItem);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExperience) {
          final index = _experiences.indexWhere((exp) => exp.id == experienceId);
          if (index != -1) {
            _experiences[index] = updatedExperience;
          }
          if (_selectedExperience?.id == experienceId) {
            _selectedExperience = updatedExperience;
          }
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update itinerary item
  Future<bool> updateItineraryItem(String experienceId, String itemId, Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.updateItineraryItem(experienceId, itemId, updateData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExperience) {
          final index = _experiences.indexWhere((exp) => exp.id == experienceId);
          if (index != -1) {
            _experiences[index] = updatedExperience;
          }
          if (_selectedExperience?.id == experienceId) {
            _selectedExperience = updatedExperience;
          }
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete itinerary item
  Future<bool> deleteItineraryItem(String experienceId, String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.deleteItineraryItem(experienceId, itemId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExperience) {
          final index = _experiences.indexWhere((exp) => exp.id == experienceId);
          if (index != -1) {
            _experiences[index] = updatedExperience;
          }
          if (_selectedExperience?.id == experienceId) {
            _selectedExperience = updatedExperience;
          }
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reorder itinerary
  Future<bool> reorderItinerary(String experienceId, List<Map<String, dynamic>> itinerary) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _experienceController.reorderItinerary(experienceId, itinerary);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExperience) {
          final index = _experiences.indexWhere((exp) => exp.id == experienceId);
          if (index != -1) {
            _experiences[index] = updatedExperience;
          }
          if (_selectedExperience?.id == experienceId) {
            _selectedExperience = updatedExperience;
          }
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh experiences
  Future<void> refreshExperiences(String agencyId) async {
    await fetchExperiencesByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _experiences.clear();
    _selectedExperience = null;
    _errorMessage = null;
    notifyListeners();
  }
}
