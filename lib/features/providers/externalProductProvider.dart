import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/externalProductController.dart';
import 'package:enable_web/features/entities/externalProductModel.dart';
import 'package:enable_web/core/failure.dart';

class ExternalProductProvider extends ChangeNotifier {
  final ExternalProductController _externalProductController = ExternalProductController();
  
  List<ExternalProductModel> _externalProducts = [];
  ExternalProductModel? _selectedExternalProduct;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ExternalProductModel> get externalProducts => _externalProducts;
  ExternalProductModel? get selectedExternalProduct => _selectedExternalProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected external product
  void setSelectedExternalProduct(ExternalProductModel? externalProduct) {
    _selectedExternalProduct = externalProduct;
    notifyListeners();
  }

  // Fetch external products by agency ID
  Future<void> fetchExternalProductsByAgencyId(String agencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _externalProductController.getExternalProductsByAgencyId(agencyId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (externalProducts) {
          _externalProducts = externalProducts;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get external product by ID
  Future<void> fetchExternalProductById(String externalProductId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _externalProductController.getExternalProductById(externalProductId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (externalProduct) {
          _selectedExternalProduct = externalProduct;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new external product
  Future<bool> createExternalProduct(Map<String, dynamic> externalProductData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _externalProductController.createExternalProduct(externalProductData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (externalProduct) {
          _externalProducts.add(externalProduct);
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

  // Update existing external product
  Future<bool> updateExternalProduct(String externalProductId, Map<String, dynamic> externalProductData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _externalProductController.updateExternalProduct(externalProductId, externalProductData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedExternalProduct) {
          final index = _externalProducts.indexWhere((ep) => ep.id == externalProductId);
          if (index != -1) {
            _externalProducts[index] = updatedExternalProduct;
          }
          if (_selectedExternalProduct?.id == externalProductId) {
            _selectedExternalProduct = updatedExternalProduct;
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

  // Delete external product
  Future<bool> deleteExternalProduct(String externalProductId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _externalProductController.deleteExternalProduct(externalProductId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (success) {
          if (success) {
            _externalProducts.removeWhere((ep) => ep.id == externalProductId);
            if (_selectedExternalProduct?.id == externalProductId) {
              _selectedExternalProduct = null;
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

  // Refresh external products
  Future<void> refreshExternalProducts(String agencyId) async {
    await fetchExternalProductsByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _externalProducts.clear();
    _selectedExternalProduct = null;
    _errorMessage = null;
    notifyListeners();
  }
}
