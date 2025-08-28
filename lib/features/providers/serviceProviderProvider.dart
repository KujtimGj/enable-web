import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/serviceProviderController.dart';
import 'package:enable_web/features/entities/serviceProviderModel.dart';
import 'package:enable_web/core/failure.dart';

class ServiceProviderProvider extends ChangeNotifier {
  final ServiceProviderController _serviceProviderController = ServiceProviderController();
  
  List<ServiceProviderModel> _serviceProviders = [];
  ServiceProviderModel? _selectedServiceProvider;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ServiceProviderModel> get serviceProviders => _serviceProviders;
  ServiceProviderModel? get selectedServiceProvider => _selectedServiceProvider;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected service provider
  void setSelectedServiceProvider(ServiceProviderModel? serviceProvider) {
    _selectedServiceProvider = serviceProvider;
    notifyListeners();
  }

  // Fetch service providers by agency ID
  Future<void> fetchServiceProvidersByAgencyId(String agencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _serviceProviderController.getServiceProvidersByAgencyId(agencyId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (serviceProviders) {
          _serviceProviders = serviceProviders;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get service provider by ID
  Future<void> fetchServiceProviderById(String serviceProviderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _serviceProviderController.getServiceProviderById(serviceProviderId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (serviceProvider) {
          _selectedServiceProvider = serviceProvider;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new service provider
  Future<bool> createServiceProvider(Map<String, dynamic> serviceProviderData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _serviceProviderController.createServiceProvider(serviceProviderData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (serviceProvider) {
          _serviceProviders.add(serviceProvider);
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

  // Update existing service provider
  Future<bool> updateServiceProvider(String serviceProviderId, Map<String, dynamic> serviceProviderData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _serviceProviderController.updateServiceProvider(serviceProviderId, serviceProviderData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedServiceProvider) {
          final index = _serviceProviders.indexWhere((sp) => sp.id == serviceProviderId);
          if (index != -1) {
            _serviceProviders[index] = updatedServiceProvider;
          }
          if (_selectedServiceProvider?.id == serviceProviderId) {
            _selectedServiceProvider = updatedServiceProvider;
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

  // Delete service provider
  Future<bool> deleteServiceProvider(String serviceProviderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _serviceProviderController.deleteServiceProvider(serviceProviderId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (success) {
          if (success) {
            _serviceProviders.removeWhere((sp) => sp.id == serviceProviderId);
            if (_selectedServiceProvider?.id == serviceProviderId) {
              _selectedServiceProvider = null;
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

  // Refresh service providers
  Future<void> refreshServiceProviders(String agencyId) async {
    await fetchServiceProvidersByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _serviceProviders.clear();
    _selectedServiceProvider = null;
    _errorMessage = null;
    notifyListeners();
  }
}
