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
  
  // Fetch products
  Future<void> fetchProducts(String agencyId, {int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    final result = await _controller.getAgencyProducts(
      agencyId,
      page: page,
      limit: 100,
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

    final result = await _controller.searchProducts(query, agencyId, limit: limit);
    result.fold(
      (failure) {
        _errorMessage = (failure as ServerFailure).message;
        _filtered = [];
      },
      (list) {
        _filtered = list.map((j) => ProductModel.fromJson(j)).toList();
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

