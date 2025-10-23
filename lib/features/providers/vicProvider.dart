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
  
  // Search state
  List<VICModel> _filteredVICs = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Getters
  List<VICModel> get vics => _vics;
  VICModel? get selectedVIC => _selectedVIC;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Search getters
  List<VICModel> get filteredVICs => _filteredVICs.isEmpty ? _vics : _filteredVICs;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

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
          print('VICProvider: Failed to fetch VICs: ${failure }');
          _errorMessage = (failure as ServerFailure).message;
        },
        (vics) {
          _vics = vics;
        },
      );
    } catch (e) {
      print('VICProvider: Exception in fetchVICsByAgencyId: $e');
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

  Future<void> searchVICs(String query, String agencyId) async {
    if (query.trim().isEmpty) {
      _filteredVICs = [];
      _searchQuery = '';
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vicController.searchVICs(query, agencyId);
      
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          _filteredVICs = [];
        },
        (vicsJson) {
          _filteredVICs = vicsJson.map((json) => VICModel.fromJson(json)).toList();
        },
      );
    } catch (e, stackTrace) {
      print('VICProvider: Exception in searchVICs: $e');
      print('VICProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred during search: $e';
      _filteredVICs = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _filteredVICs = [];
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  void performLocalSearch(String query) {
    if (query.trim().isEmpty) {
      _filteredVICs = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    
    // Perform local filtering for partial matches
    _filteredVICs = _vics.where((vic) {
      final fullName = (vic.fullName ?? '').toLowerCase();
      final email = (vic.email ?? '').toLowerCase();
      final nationality = (vic.nationality ?? '').toLowerCase();
      final summary = (vic.summary ?? '').toLowerCase();
      final preferences = (vic.preferences?.toString() ?? '').toLowerCase();
      final queryLower = query.toLowerCase();
      
      return fullName.contains(queryLower) || 
             email.contains(queryLower) || 
             nationality.contains(queryLower) ||
             summary.contains(queryLower) ||
             preferences.contains(queryLower);
    }).toList();
    
    notifyListeners();
  }
}
