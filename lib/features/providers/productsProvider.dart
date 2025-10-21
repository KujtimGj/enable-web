import 'package:flutter/material.dart';
import '../controllers/agencyController.dart';
import '../entities/productModel.dart';
import '../../core/failure.dart';

class ProductsProvider extends ChangeNotifier {
  final AgencyController _controller = AgencyController();
  
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  List<ProductModel> _filtered = [];
  
  // Filters
  String? _selectedCategory;
  String? _selectedCountry;
  String? _selectedCity;
  final Set<String> _selectedTagKeys = {};
  String _tagTextQuery = '';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  
  // Getters
  List<ProductModel> get products => _searchQuery.isEmpty ? _products : _filtered;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;
  
  // Exposed filter state
  String? get selectedCategory => _selectedCategory;
  String? get selectedCountry => _selectedCountry;
  String? get selectedCity => _selectedCity;
  Set<String> get selectedTagKeys => _selectedTagKeys;
  
  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _selectedCountry != null ||
      _selectedCity != null ||
      _selectedTagKeys.isNotEmpty ||
      _tagTextQuery.isNotEmpty;
  
  // Derived options from current dataset
  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      final c = p.category.trim();
      if (c.isNotEmpty) set.add(_normalizeCase(c));
    }
    final list = set.toList();
    list.sort();
    return list;
  }
  
  List<String> get countries {
    final set = <String>{};
    for (final p in _products) {
      final c = (p.country ?? '').trim();
      if (c.isNotEmpty) set.add(_normalizeCase(c));
    }
    final list = set.toList();
    list.sort();
    return list;
  }
  
  List<String> get cities {
    final set = <String>{};
    for (final p in _products) {
      final c = (p.city ?? '').trim();
      if (c.isNotEmpty) set.add(_normalizeCase(c));
    }
    final list = set.toList();
    list.sort();
    return list;
  }
  
  List<String> get tagKeys {
    // Build a set of unique tag VALUES across products. Many products store
    // tags as a map of index -> value (e.g., {"0": "Beachfront"}).
    final set = <String>{};
    for (final p in _products) {
      final tags = p.tags;
      if (tags == null) continue;
      for (final value in tags.values) {
        if (value == null) continue;
        final valueStr = value.toString().trim();
        if (valueStr.isNotEmpty) set.add(_normalizeCase(valueStr));
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }
  
  // Final list after applying search and filters
  List<ProductModel> get visibleProducts {
    final base = products; // already considers search
    if (!hasActiveFilters) return base;
    
    bool matches(ProductModel p) {
      if (_selectedCategory != null &&
          _normalizeCase(p.category) != _selectedCategory) return false;
      if (_selectedCountry != null &&
          _normalizeCase(p.country ?? '') != _selectedCountry) return false;
      if (_selectedCity != null &&
          _normalizeCase(p.city ?? '') != _selectedCity) return false;
      if (_selectedTagKeys.isNotEmpty) {
        final tags = p.tags;
        if (tags == null) return false;
        // require all selected tag keys to be present
        for (final key in _selectedTagKeys) {
          // Keys in DB are often indices; match against tag VALUES instead
          final exists = tags.values.any((v) => _normalizeCase(v.toString()) == key);
          if (!exists) return false;
        }
      }
      if (_tagTextQuery.isNotEmpty) {
        final tags = p.tags;
        if (tags == null) return false;
        final q = _tagTextQuery.toLowerCase();
        final contains = tags.values.any((v) => v != null && v.toString().toLowerCase().contains(q));
        if (!contains) return false;
      }
      return true;
    }
    
    return base.where(matches).toList();
  }
  
  // Mutators for filters
  void setCategory(String? value) {
    _selectedCategory = value?.trim().isEmpty == true ? null : value;
    notifyListeners();
  }
  
  void setCountry(String? value) {
    _selectedCountry = value?.trim().isEmpty == true ? null : value;
    notifyListeners();
  }
  
  void setCity(String? value) {
    _selectedCity = value?.trim().isEmpty == true ? null : value;
    notifyListeners();
  }
  
  void toggleTagKey(String key) {
    final normalized = _normalizeCase(key);
    if (_selectedTagKeys.contains(normalized)) {
      _selectedTagKeys.remove(normalized);
    } else {
      _selectedTagKeys.add(normalized);
    }
    notifyListeners();
  }
  
  void setTagTextQuery(String value) {
    _tagTextQuery = value.trim();
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedCategory = null;
    _selectedCountry = null;
    _selectedCity = null;
    _selectedTagKeys.clear();
    _tagTextQuery = '';
    notifyListeners();
  }
  
  String _normalizeCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
  
  // Fetch products
  Future<void> fetchProducts(String agencyId, {int page = 1, String? q}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    final result = await _controller.getAgencyProducts(
      agencyId,
      page: page,
      limit: 100,
      q: q,
    );
    
    result.fold(
      (failure) {
        _errorMessage = (failure as ServerFailure).message;
        _products = [];
      },
      (data) {
        final productsList = data['products'] as List<ProductModel>;
        final pagination = data['pagination'] as Map<String, dynamic>;
        
        _products = productsList;
        _currentPage = pagination['currentPage'] ?? 1;
        _totalPages = pagination['totalPages'] ?? 1;
        _totalCount = pagination['totalCount'] ?? 0;
      },
    );
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Local search across many fields
  void localSearch(String query) {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _filtered = [];
      notifyListeners();
      return;
    }

    final q = _searchQuery.toLowerCase();

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

    _filtered = _products.where((p) {
      if (p.name.toLowerCase().contains(q)) return true;
      if (p.category.toLowerCase().contains(q)) return true;
      if ((p.subcategory ?? '').toLowerCase().contains(q)) return true;
      if ((p.description ?? '').toLowerCase().contains(q)) return true;
      if ((p.country ?? '').toLowerCase().contains(q)) return true;
      if ((p.city ?? '').toLowerCase().contains(q)) return true;
      if ((p.providerName ?? '').toLowerCase().contains(q)) return true;
      if ((p.providerContact ?? '').toLowerCase().contains(q)) return true;
      if ((p.providerWebsite ?? '').toLowerCase().contains(q)) return true;
      if ((p.availability ?? '').toLowerCase().contains(q)) return true;

      if (p.priceMin != null && p.priceMin!.toString().toLowerCase().contains(q)) return true;
      if (p.priceMax != null && p.priceMax!.toString().toLowerCase().contains(q)) return true;
      if (p.rating != null && p.rating!.toString().toLowerCase().contains(q)) return true;

      if (mapContains(p.tags, q)) return true;
      if (p.features is Map<String, dynamic> && mapContains(p.features as Map<String, dynamic>, q)) return true;

      return false;
    }).toList();

    notifyListeners();
  }

  // Server search across backend smart search
  Future<void> serverSearch(String query, String agencyId, {int limit = 200}) async {
    _isLoading = true;
    _errorMessage = null;
    _searchQuery = query.trim();
    notifyListeners();

    // Prefer direct products endpoint with q to search full dataset without page constraints
    final result = await _controller.getAgencyProducts(
      agencyId,
      page: 1,
      limit: limit,
      q: _searchQuery,
    );

    result.fold(
      (failure) {
        _errorMessage = (failure as ServerFailure).message;
        _filtered = [];
      },
      (data) {
        final productsList = data['products'] as List<ProductModel>;
        _filtered = productsList;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filtered = [];
    notifyListeners();
  }
  
  // Go to next page
  Future<void> nextPage(String agencyId) async {
    if (_currentPage < _totalPages && !_isLoading) {
      await fetchProducts(agencyId, page: _currentPage + 1);
    }
  }
  
  // Go to previous page
  Future<void> previousPage(String agencyId) async {
    if (_currentPage > 1 && !_isLoading) {
      await fetchProducts(agencyId, page: _currentPage - 1);
    }
  }
  
  // Refresh
  Future<void> refresh(String agencyId) async {
    await fetchProducts(agencyId, page: 1);
  }
}

