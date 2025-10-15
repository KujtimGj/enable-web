import 'dart:async';

import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/agencyController.dart';
import 'package:enable_web/features/entities/productModel.dart';
import 'package:enable_web/features/entities/dmcModel.dart';
import 'package:enable_web/features/entities/serviceProviderModel.dart';
import 'package:enable_web/features/entities/externalProductModel.dart';
import 'package:enable_web/features/entities/experienceModel.dart';
import 'package:enable_web/core/failure.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../entities/agency.dart';
import '../entities/user.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';


class AgencyProvider extends ChangeNotifier {

  void _safeNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    // Only notify immediately when the framework is idle
    if (phase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      // Defer to after the current frame to avoid "during build"
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Double-check we're not in the middle of another build
        if (!hasListeners) return; // optional safeguard
        notifyListeners();
      });
    }
  }
  final AgencyController _agencyController = AgencyController();
  List<ProductModel> _products = [];
  AgencyModel? _agency;
  AgencyModel? _createdAgency;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _token;
  
  // Document count state
  Map<String, int> _documentCounts = {
    'dmcCount': 0,
    'productCount': 0,
    'experienceCount': 0,
    'externalProductCount': 0,
    'serviceProviderCount': 0,
  };
  bool _isLoadingCounts = false;

  // Data state
  List<DMC> _dmcs = [];
  List<ExternalProductModel> _externalProducts = [];
  List<ServiceProviderModel> _serviceProviders = [];
  List<ExperienceModel> _experiences = [];
  bool _isLoadingData = false;
  
  // Pagination state for experiences
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  
  // Pagination state for products
  int _productsCurrentPage = 1;
  int _productsTotalPages = 1;
  int _productsTotalCount = 0;
  bool _productsHasMore = false;
  bool _isLoadingMoreProducts = false;
  bool _isLoadingProducts = false;
  
  // Search state
  List<ExperienceModel> _filteredExperiences = [];
  String _searchQuery = '';
  bool _isSearching = false;

  AgencyModel? get agency => _agency;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  AgencyModel? get createdAgency => _createdAgency;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  
  // Document count getters
  Map<String, int> get documentCounts => _documentCounts;
  bool get isLoadingCounts => _isLoadingCounts;
  
  // Data getters
  List<DMC> get dmcs => _dmcs;
  List<ExternalProductModel> get externalProducts => _externalProducts;
  List<ServiceProviderModel> get serviceProviders => _serviceProviders;
  List<ExperienceModel> get experiences => _experiences;
  bool get isLoadingData => _isLoadingData;
  
  // Pagination getters for experiences
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  
  // Pagination getters for products
  int get productsCurrentPage => _productsCurrentPage;
  int get productsTotalPages => _productsTotalPages;
  int get productsTotalCount => _productsTotalCount;
  bool get productsHasMore => _productsHasMore;
  bool get isLoadingMoreProducts => _isLoadingMoreProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  
  // Search getters
  List<ExperienceModel> get filteredExperiences => _filteredExperiences.isEmpty ? _experiences : _filteredExperiences;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  AgencyProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final agencyJson = prefs.getString('agency');
      final userJson = prefs.getString('user');
      

      if (token != null) {
        _token = token;
        
        // First try to get agency from stored agency data
        if (agencyJson != null) {
          _agency = AgencyModel.fromJson(jsonDecode(agencyJson));
        } 
        // If no agency data, try to create agency from user's agencyId
        else if (userJson != null) {
          final userMap = jsonDecode(userJson);
          final user = UserModel.fromJson(userMap);
          
          if (user.agencyId.isNotEmpty) {
            // Create a minimal agency object from user's agencyId
            _agency = AgencyModel(
              id: user.agencyId,
              name: 'Agency', // Default name, could be fetched later
              email: '',
              password: '',
              phone: '',
              logoUrl: '',
              externalKnowledgeBase: false,
            );
            print('AgencyProvider: Created agency from user agencyId: ${user.agencyId}');
          }
        }
        
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      print('AgencyProvider: Error in _initializeAuth: $e');
      _isAuthenticated = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> fetchAgencyProducts(String agencyId, {bool refresh = true}) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingProducts) {
      return;
    }
    
    _isLoadingProducts = true;
    if (refresh) {
      _isLoading = true;
      _productsCurrentPage = 1;
      // Don't clear products immediately to avoid showing empty state
    }
    _errorMessage = null;
    notifyListeners();

    final result = await _agencyController.getAgencyProducts(
      agencyId,
      page: _productsCurrentPage,
      limit: 100,
    );
    
    result.fold(
      (failure) {
        final serverFailure = failure as ServerFailure;
        _errorMessage = serverFailure.message;
      },
      (data) {
        // Get the products list from data - it's already List<ProductModel> from controller
        final productsList = List<ProductModel>.from(data['products'] as List);
        final pagination = data['pagination'] as Map<String, dynamic>;
        
        if (refresh) {
          _products = productsList;
        } else {
          _products.addAll(productsList);
        }
        
        _productsCurrentPage = pagination['currentPage'] ?? 1;
        _productsTotalPages = pagination['totalPages'] ?? 1;
        _productsTotalCount = pagination['totalCount'] ?? 0;
        _productsHasMore = pagination['hasMore'] ?? false;
      },
    );

    _isLoading = false;
    _isLoadingProducts = false;
    notifyListeners();
  }

  Future<void> loadMoreProducts(String agencyId) async {
    if (_isLoadingMoreProducts || !_productsHasMore) return;

    _isLoadingMoreProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productsCurrentPage++;
      final result = await _agencyController.getAgencyProducts(
        agencyId,
        page: _productsCurrentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: Load more products failed: $failure');
          _errorMessage = (failure as ServerFailure).message;
          _productsCurrentPage--;
        },
        (data) {
          final productsList = List<ProductModel>.from(data['products'] as List);
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          _products.addAll(productsList);
          
          _productsCurrentPage = pagination['currentPage'] ?? _productsCurrentPage;
          _productsTotalPages = pagination['totalPages'] ?? 1;
          _productsTotalCount = pagination['totalCount'] ?? 0;
          _productsHasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in loadMoreProducts: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
      _productsCurrentPage--;
    }

    _isLoadingMoreProducts = false;
    notifyListeners();
  }

  Future<void> goToNextProductsPage(String agencyId) async {
    if (_productsCurrentPage >= _productsTotalPages || _isLoadingProducts) return;
    
    _isLoadingProducts = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productsCurrentPage++;
      final result = await _agencyController.getAgencyProducts(
        agencyId,
        page: _productsCurrentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: Go to next products page failed: $failure');
          _errorMessage = (failure as ServerFailure).message;
          _productsCurrentPage--;
        },
        (data) {
          final productsList = List<ProductModel>.from(data['products'] as List);
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          _products = productsList; // Replace with new page data
          
          _productsCurrentPage = pagination['currentPage'] ?? _productsCurrentPage;
          _productsTotalPages = pagination['totalPages'] ?? 1;
          _productsTotalCount = pagination['totalCount'] ?? 0;
          _productsHasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in goToNextProductsPage: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
      _productsCurrentPage--;
    }

    _isLoading = false;
    _isLoadingProducts = false;
    notifyListeners();
  }

  Future<void> goToPreviousProductsPage(String agencyId) async {
    if (_productsCurrentPage <= 1 || _isLoadingProducts) return;
    
    _isLoadingProducts = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productsCurrentPage--;
      final result = await _agencyController.getAgencyProducts(
        agencyId,
        page: _productsCurrentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: Go to previous products page failed: $failure');
          _errorMessage = (failure as ServerFailure).message;
          _productsCurrentPage++;
        },
        (data) {
          final productsList = List<ProductModel>.from(data['products'] as List);
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          _products = productsList; // Replace with new page data
          
          _productsCurrentPage = pagination['currentPage'] ?? _productsCurrentPage;
          _productsTotalPages = pagination['totalPages'] ?? 1;
          _productsTotalCount = pagination['totalCount'] ?? 0;
          _productsHasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in goToPreviousProductsPage: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
      _productsCurrentPage++;
    }

    _isLoading = false;
    _isLoadingProducts = false;
    notifyListeners();
  }

  Future<void> createAgency(AgencyModel agencyModel) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _agencyController.createAgency(agencyModel);
    result.fold(
          (failure) {
        _errorMessage = (failure as ServerFailure).message;
        _createdAgency = null;
      },
          (agency) {
        _createdAgency = agency;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<AgencyModel?> loginAgency(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _agencyController.loginAgency(email, password);
    return await result.fold(
      (failure) async {
        _errorMessage = failure.toString();
        _agency = null;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return null;
      },
      (loggedAgency) async {
        _agency = loggedAgency;
        _isAuthenticated = true;
        
        // Store agency data in SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('agency', jsonEncode(loggedAgency.toJson()));
        // Token is already stored by the controller
        _token = prefs.getString('token');
        
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return _agency;
      },
    );
  }

  Future<void> logoutAgency() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('agency');
    
    _agency = null;
    _token = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchDocumentCounts(String agencyId) async {
    try {
      final result = await _agencyController.getDocumentCount(agencyId);
      result.fold(
            (failure) {
           print(failure);
        },
            (counts) { counts;},
      );
    } catch (e) {
      print(e.toString());
    }
    // Either rely on fetchAllData's final notify, or:
    // _safeNotify();
  }


  Future<void> fetchDMCs(String agencyId) async {
    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _agencyController.getDMCsByAgencyId(agencyId);
    result.fold(
      (failure) {
        _errorMessage = (failure as ServerFailure).message;
      },
      (dmcs) {
        _dmcs = dmcs;
      },
    );

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> fetchExternalProducts(String agencyId) async {
    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _agencyController.getExternalProductsByAgencyId(agencyId);
    result.fold(
      (failure) {
        _errorMessage = (failure as ServerFailure).message;
      },
      (externalProducts) {
        _externalProducts = externalProducts.map((json) => ExternalProductModel.fromJson(json)).toList();
      },
    );

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> fetchServiceProviders(String agencyId) async {
    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _agencyController.getServiceProvidersByAgencyId(agencyId);
    result.fold(
      (failure) {
        _errorMessage = (failure as ServerFailure).message;
      },
      (serviceProviders) {
        _serviceProviders = serviceProviders.map((json) => ServiceProviderModel.fromJson(json)).toList();
      },
    );

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> fetchExperiences(String agencyId, {bool refresh = true}) async {
    if (refresh) {
      _isLoadingData = true;
      _currentPage = 1;
      _experiences = [];
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _agencyController.getExperiencesByAgencyId(
        agencyId,
        page: _currentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: API call failed with failure: $failure');
          _errorMessage = (failure as ServerFailure).message;
        },
        (data) {
          final experiencesJson = data['experiences'] as List;
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          final newExperiences = experiencesJson
              .map((json) => ExperienceModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          if (refresh) {
            _experiences = newExperiences;
          } else {
            _experiences.addAll(newExperiences);
          }
          
          _currentPage = pagination['currentPage'] ?? 1;
          _totalPages = pagination['totalPages'] ?? 1;
          _totalCount = pagination['totalCount'] ?? 0;
          _hasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in fetchExperiences: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
    }

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> loadMoreExperiences(String agencyId) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPage++;
      final result = await _agencyController.getExperiencesByAgencyId(
        agencyId,
        page: _currentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: Load more failed with failure: $failure');
          _errorMessage = (failure as ServerFailure).message;
          _currentPage--; // Revert page increment on failure
        },
        (data) {
          final experiencesJson = data['experiences'] as List;
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          final newExperiences = experiencesJson
              .map((json) => ExperienceModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          _experiences.addAll(newExperiences);
          
          _currentPage = pagination['currentPage'] ?? _currentPage;
          _totalPages = pagination['totalPages'] ?? 1;
          _totalCount = pagination['totalCount'] ?? 0;
          _hasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in loadMoreExperiences: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
      _currentPage--; // Revert page increment on failure
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> goToNextPage(String agencyId) async {
    if (_currentPage >= _totalPages) return;
    
    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _currentPage++;
      final result = await _agencyController.getExperiencesByAgencyId(
        agencyId,
        page: _currentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: Go to next page failed: $failure');
          _errorMessage = (failure as ServerFailure).message;
          _currentPage--; // Revert on failure
        },
        (data) {
          final experiencesJson = data['experiences'] as List;
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          final newExperiences = experiencesJson
              .map((json) => ExperienceModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          _experiences = newExperiences; // Replace with new page data
          
          _currentPage = pagination['currentPage'] ?? _currentPage;
          _totalPages = pagination['totalPages'] ?? 1;
          _totalCount = pagination['totalCount'] ?? 0;
          _hasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in goToNextPage: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
      _currentPage--;
    }

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> goToPreviousPage(String agencyId) async {
    if (_currentPage <= 1) return;
    
    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _currentPage--;
      final result = await _agencyController.getExperiencesByAgencyId(
        agencyId,
        page: _currentPage,
        limit: 100,
      );

      result.fold(
        (failure) {
          print('AgencyProvider: Go to previous page failed: $failure');
          _errorMessage = (failure as ServerFailure).message;
          _currentPage++; // Revert on failure
        },
        (data) {
          final experiencesJson = data['experiences'] as List;
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          final newExperiences = experiencesJson
              .map((json) => ExperienceModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          _experiences = newExperiences; // Replace with new page data
          
          _currentPage = pagination['currentPage'] ?? _currentPage;
          _totalPages = pagination['totalPages'] ?? 1;
          _totalCount = pagination['totalCount'] ?? 0;
          _hasMore = pagination['hasMore'] ?? false;
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in goToPreviousPage: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred: $e';
      _currentPage++;
    }

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> fetchAllData(String agencyId) async {
    // if you're tracking a loading flag, set it here without notifying yet
    // isLoadingCounts = true;  // optional, but don't notify here

    try {
      await Future.wait([
        fetchDocumentCounts(agencyId),   // these should NOT notify early
        fetchAgencyProducts(agencyId),
        fetchDMCs(agencyId),
        fetchExternalProducts(agencyId),
        fetchServiceProviders(agencyId),
        fetchExperiences(agencyId),
      ]);
    } catch (e, st) {
      print(e.toString());
      if (kDebugMode) print('[AgencyProvider] fetchAllData error: $e\n$st');
    } finally {
      _safeNotify(); // <-- single, safe notification after all updates
    }
  }

  Future<void> searchExperiences(String query, String agencyId) async {
    if (query.trim().isEmpty) {
      _filteredExperiences = [];
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
      final result = await _agencyController.searchExperiences(query, agencyId);
      
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          _filteredExperiences = [];
        },
        (experiencesJson) {
          _filteredExperiences = experiencesJson.map((json) => ExperienceModel.fromJson(json)).toList();
        },
      );
    } catch (e, stackTrace) {
      print('AgencyProvider: Exception in searchExperiences: $e');
      print('AgencyProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred during search: $e';
      _filteredExperiences = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _filteredExperiences = [];
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  void performLocalSearch(String query) {
    if (query.trim().isEmpty) {
      _filteredExperiences = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    final q = query.toLowerCase();

    bool mapContains(Map<String, dynamic>? map, String q) {
      if (map == null) return false;
      for (final entry in map.entries) {
        final v = entry.value;
        if (v == null) continue;
        if (v is String && v.toLowerCase().contains(q)) return true;
        if (v is num && v.toString().toLowerCase().contains(q)) return true;
        if (v is Map<String, dynamic> && mapContains(v, q)) return true;
        if (v is List) {
          for (final item in v) {
            if (item == null) continue;
            if (item is String && item.toLowerCase().contains(q)) return true;
            if (item is num && item.toString().toLowerCase().contains(q)) return true;
            if (item is Map<String, dynamic> && mapContains(item, q)) return true;
          }
        }
      }
      return false;
    }

    // Perform local filtering across many fields (destination, country, notes, tags, extras, party, status, itinerary fields)
    _filteredExperiences = _experiences.where((experience) {
      if ((experience.destination ?? '').toLowerCase().contains(q)) return true;
      if ((experience.country ?? '').toLowerCase().contains(q)) return true;
      if ((experience.status ?? '').toLowerCase().contains(q)) return true;
      if ((experience.notes ?? '').toLowerCase().contains(q)) return true;

      // dates
      if (experience.startDate != null &&
          experience.startDate!.toIso8601String().toLowerCase().contains(q)) return true;
      if (experience.endDate != null &&
          experience.endDate!.toIso8601String().toLowerCase().contains(q)) return true;

      // party
      if (experience.party != null) {
        final adults = experience.party!['adults']?.toString().toLowerCase() ?? '';
        final children = experience.party!['children']?.toString().toLowerCase() ?? '';
        if (adults.contains(q) || children.contains(q)) return true;
      }

      // tags / extras / totals
      if (mapContains(experience.tags, q)) return true;
      if (mapContains(experience.extras, q)) return true;
      if (mapContains(experience.totals, q)) return true;

      // itinerary nested fields
      if (experience.itinerary != null) {
        for (final it in experience.itinerary!) {
          if ((it.type ?? '').toLowerCase().contains(q)) return true;
          if ((it.status ?? '').toLowerCase().contains(q)) return true;
          if (it.supplier != null &&
              ((it.supplier!['name']?.toString().toLowerCase() ?? '').contains(q) ||
               (it.supplier!['confirmationCode']?.toString().toLowerCase() ?? '').contains(q))) return true;
          if (it.location != null) {
            final loc = it.location!;
            if ((loc['address']?.toString().toLowerCase() ?? '').contains(q)) return true;
            if ((loc['city']?.toString().toLowerCase() ?? '').contains(q)) return true;
          }
          if (mapContains(it.details, q)) return true;
          if (mapContains(it.extras, q)) return true;
          if (mapContains(it.snapshot, q)) return true;
        }
      }

      return false;
    }).toList();
    
    notifyListeners();
  }

}
