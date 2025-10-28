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
  String _searchQuery = '';
  List<ServiceProviderModel> _filtered = [];

  // Filters
  String? _selectedCountry;

  // Getters
  List<ServiceProviderModel> get serviceProviders => _searchQuery.isEmpty ? _serviceProviders : _filtered;
  List<ServiceProviderModel> get visibleServiceProviders => _getFilteredServiceProviders();
  ServiceProviderModel? get selectedServiceProvider => _selectedServiceProvider;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Exposed filter state
  String? get selectedCountry => _selectedCountry;

  bool get hasActiveFilters => _selectedCountry != null;

  // Derived options from current dataset
  List<String> get countries {
    final set = <String>{};
    for (final sp in _serviceProviders) {
      final c = (sp.country ?? '').trim();
      if (c.isNotEmpty) set.add(_normalizeCase(c));
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<ServiceProviderModel> _getFilteredServiceProviders() {
    final base = serviceProviders;
    if (!hasActiveFilters) return base;

    return base.where((sp) {
      if (_selectedCountry != null &&
          _normalizeCase(sp.country ?? '') != _selectedCountry) return false;
      return true;
    }).toList();
  }

  void setCountry(String? value) {
    _selectedCountry = value?.trim().isEmpty == true ? null : value;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCountry = null;
    notifyListeners();
  }

  String _normalizeCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  // Local search
  void localSearch(String query) {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _filtered = [];
      notifyListeners();
      return;
    }

    final q = _searchQuery.toLowerCase();

    _filtered = _serviceProviders.where((sp) {
      if ((sp.name ?? '').toLowerCase().contains(q)) return true;
      if ((sp.type ?? '').toLowerCase().contains(q)) return true;
      if ((sp.contactPerson ?? '').toLowerCase().contains(q)) return true;
      if ((sp.email ?? '').toLowerCase().contains(q)) return true;
      if ((sp.phone ?? '').toLowerCase().contains(q)) return true;
      if ((sp.address ?? '').toLowerCase().contains(q)) return true;
      if ((sp.city ?? '').toLowerCase().contains(q)) return true;
      if ((sp.country ?? '').toLowerCase().contains(q)) return true;
      if ((sp.website ?? '').toLowerCase().contains(q)) return true;
      return false;
    }).toList();

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filtered = [];
    notifyListeners();
  }

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
  Future<void> refresh(String agencyId) async {
    await fetchServiceProvidersByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _serviceProviders.clear();
    _selectedServiceProvider = null;
    _errorMessage = null;
    _searchQuery = '';
    _filtered = [];
    notifyListeners();
  }
}
