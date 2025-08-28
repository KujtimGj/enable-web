import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/vicController.dart';
import 'package:enable_web/features/entities/vicModel.dart';
import 'package:enable_web/core/failure.dart';

class VICProvider extends ChangeNotifier {
  final VICController _vicController = VICController();
  
  List<VICModel> _vics = [];
  VICModel? _selectedVIC;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<VICModel> get vics => _vics;
  VICModel? get selectedVIC => _selectedVIC;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected VIC
  void setSelectedVIC(VICModel? vic) {
    _selectedVIC = vic;
    notifyListeners();
  }

  // Fetch VICs by agency ID
  Future<void> fetchVICsByAgencyId(String agencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vicController.getVICsByAgencyId(agencyId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (vics) {
          _vics = vics;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get VIC by ID
  Future<void> fetchVICById(String vicId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vicController.getVICById(vicId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (vic) {
          _selectedVIC = vic;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new VIC
  Future<bool> createVIC(Map<String, dynamic> vicData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vicController.createVIC(vicData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (vic) {
          _vics.add(vic);
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

  // Update existing VIC
  Future<bool> updateVIC(String vicId, Map<String, dynamic> vicData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vicController.updateVIC(vicId, vicData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedVIC) {
          final index = _vics.indexWhere((vic) => vic.id == vicId);
          if (index != -1) {
            _vics[index] = updatedVIC;
          }
          if (_selectedVIC?.id == vicId) {
            _selectedVIC = updatedVIC;
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

  // Delete VIC
  Future<bool> deleteVIC(String vicId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vicController.deleteVIC(vicId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (success) {
          if (success) {
            _vics.removeWhere((vic) => vic.id == vicId);
            if (_selectedVIC?.id == vicId) {
              _selectedVIC = null;
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

  // Refresh VICs
  Future<void> refreshVICs(String agencyId) async {
    await fetchVICsByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _vics.clear();
    _selectedVIC = null;
    _errorMessage = null;
    notifyListeners();
  }
}
