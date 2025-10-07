import 'package:flutter/material.dart';
import '../controllers/agencyController.dart';
import '../entities/productModel.dart';
import '../../core/failure.dart';

class ProductsProvider extends ChangeNotifier {
  final AgencyController _controller = AgencyController();
  
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  
  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  
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

