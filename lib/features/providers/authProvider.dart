import 'package:flutter/foundation.dart';
import 'package:enable_web/features/controllers/auth_controller.dart';
import 'package:enable_web/features/entities/user.dart';
import 'package:enable_web/core/failure.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _authController = AuthController();
  
  bool _isAuthenticated = false;
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check if user is authenticated
      _isAuthenticated = await _authController.isAuthenticated();
      
      if (_isAuthenticated) {
        // Load token and user data
        _token = await _authController.getToken();
        _currentUser = await _authController.getUser();
        
        // Validate that we have both token and user data
        if (_token == null || _currentUser == null) {
          _isAuthenticated = false;
          await _authController.signOut(); // Clear invalid data
        }
      }
    } catch (e) {
      _error = 'Failed to initialize authentication state';
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Refresh authentication state (useful for token validation)
  Future<void> refreshAuth() async {
    if (!_isInitialized) return; // Don't refresh if not initialized
    
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authController.isAuthenticated();
      
      if (_isAuthenticated) {
        _token = await _authController.getToken();
        _currentUser = await _authController.getUser();
        
        // Validate that we have both token and user data
        if (_token == null || _currentUser == null) {
          _isAuthenticated = false;
          await _authController.signOut();
        }
      }
    } catch (e) {
      print('Error refreshing auth: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authController.signIn(email, password);
      
      return result.fold(
        (failure) {
          if (failure is ServerFailure) {
            _error = failure.message ?? 'Login failed';
          } else {
            _error = 'Login failed';
          }
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (loginResponse) {
          _isAuthenticated = true;
          _currentUser = loginResponse.user;
          _token = loginResponse.token;
          _isLoading = false;
          _error = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authController.signOut();
      _isAuthenticated = false;
      _currentUser = null;
      _token = null;
      _error = null;
    } catch (e) {
      _error = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearStoredAuth() async {
    _isAuthenticated = false;
    _currentUser = null;
    _token = null;
    _error = null;
    await _authController.signOut();
    notifyListeners();
  }
}
