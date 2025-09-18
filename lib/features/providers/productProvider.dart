import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/productController.dart';
import 'package:enable_web/features/entities/productModel.dart';
import 'package:enable_web/core/failure.dart';

class ProductProvider extends ChangeNotifier {
  final ProductController _productController = ProductController();
  
  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Search state
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Getters
  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Search getters
  List<ProductModel> get filteredProducts => _filteredProducts.isEmpty ? _products : _filteredProducts;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected product
  void setSelectedProduct(ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Fetch products by agency ID
  Future<void> fetchProductsByAgencyId(String agencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productController.getProductsByAgencyId(agencyId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (products) {
          _products = products;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get product by ID
  Future<void> fetchProductById(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productController.getProductById(productId);
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
        },
        (product) {
          _selectedProduct = product;
        },
      );
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new product
  Future<bool> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productController.createProduct(productData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (product) {
          _products.add(product);
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

  // Update existing product
  Future<bool> updateProduct(String productId, Map<String, dynamic> productData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productController.updateProduct(productId, productData);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (updatedProduct) {
          final index = _products.indexWhere((product) => product.id == productId);
          if (index != -1) {
            _products[index] = updatedProduct;
          }
          if (_selectedProduct?.id == productId) {
            _selectedProduct = updatedProduct;
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

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productController.deleteProduct(productId);
      return result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          return false;
        },
        (success) {
          if (success) {
            _products.removeWhere((product) => product.id == productId);
            if (_selectedProduct?.id == productId) {
              _selectedProduct = null;
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

  // Refresh products
  Future<void> refreshProducts(String agencyId) async {
    await fetchProductsByAgencyId(agencyId);
  }

  // Clear all data
  void clearData() {
    _products.clear();
    _selectedProduct = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> searchProducts(String query, String agencyId) async {
    if (query.trim().isEmpty) {
      _filteredProducts = [];
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
      final result = await _productController.searchProducts(query, agencyId);
      
      result.fold(
        (failure) {
          _errorMessage = (failure as ServerFailure).message;
          _filteredProducts = [];
        },
        (productsJson) {
          _filteredProducts = productsJson.map((json) => ProductModel.fromJson(json)).toList();
        },
      );
    } catch (e, stackTrace) {
      print('ProductProvider: Exception in searchProducts: $e');
      print('ProductProvider: Stack trace: $stackTrace');
      _errorMessage = 'Exception occurred during search: $e';
      _filteredProducts = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _filteredProducts = [];
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  void performLocalSearch(String query) {
    if (query.trim().isEmpty) {
      _filteredProducts = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    
    // Perform local filtering for partial matches
    _filteredProducts = _products.where((product) {
      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      final country = (product.country ?? '').toLowerCase();
      final city = (product.city ?? '').toLowerCase();
      final providerName = (product.providerName ?? '').toLowerCase();
      final queryLower = query.toLowerCase();
      
      return name.contains(queryLower) || 
             category.contains(queryLower) || 
             description.contains(queryLower) ||
             country.contains(queryLower) ||
             city.contains(queryLower) ||
             providerName.contains(queryLower);
    }).toList();
    
    notifyListeners();
  }
}
