import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/dmcController.dart';
import 'package:enable_web/features/entities/dmcModel.dart';
import 'package:enable_web/core/failure.dart';

class DMCProvider extends ChangeNotifier {
  final DMCController _dmcController = DMCController();
  
  List<DMC> _dmcs = [];
  DMC? _selectedDMC;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<DMC> get dmcs => _dmcs;
  DMC? get selectedDMC => _selectedDMC;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected DMC
  void setSelectedDMC(DMC? dmc) {
    _selectedDMC = dmc;
    notifyListeners();
  }

  // Fetch DMCs by agency ID
  Future<void> fetchDMCsByAgencyId(String agencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dmcController.getDMCsByAgencyId(agencyId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (dmcs) {
          _dmcs = dmcs;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get DMC by ID
  Future<void> fetchDMCById(String dmcId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dmcController.getDMCById(dmcId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (dmc) {
          _selectedDMC = dmc;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new DMC
  Future<bool> createDMC(Map<String, dynamic> dmcData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dmcController.createDMC(dmcData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (dmc) {
          _dmcs.add(dmc);
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

  // Update existing DMC
  Future<bool> updateDMC(String dmcId, Map<String, dynamic> dmcData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dmcController.updateDMC(dmcId, dmcData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedDMC) {
          final index = _dmcs.indexWhere((dmc) => dmc.id == dmcId);
          if (index != -1) {
            _dmcs[index] = updatedDMC;
          }
          if (_selectedDMC?.id == dmcId) {
            _selectedDMC = updatedDMC;
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

  // Delete DMC
  Future<bool> deleteDMC(String dmcId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dmcController.deleteDMC(dmcId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (success) {
          if (success) {
            _dmcs.removeWhere((dmc) => dmc.id == dmcId);
            if (_selectedDMC?.id == dmcId) {
              _selectedDMC = null;
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

  // Refresh DMCs
  Future<void> refreshDMCs(String agencyId) async {
    await fetchDMCsByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _dmcs.clear();
    _selectedDMC = null;
    _errorMessage = null;
    notifyListeners();
  }
}
