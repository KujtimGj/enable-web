import 'dart:convert';
import 'package:enable_web/features/controllers/user_controller.dart';
import 'package:enable_web/features/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/failure.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final UserController userController = UserController();
  bool _isLoading = true; // Start with loading true
  bool _isInitialized = false; // Track if initialization is complete
  String? _error;
  bool _isAuthenticated = false;

  String? _token;

  //Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  String? get token => _token;

  UserProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userJson = prefs.getString('user');
      
      if (token != null && userJson != null) {
        _token = token;
        _user = UserModel.fromJson(jsonDecode(userJson));
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      print('Error initializing auth: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<UserModel?> login(String email, password) async {
    var result = await userController.loginUser(email, password);

    _isLoading = true;
    _error = null;
    notifyListeners();
    return await result.fold(
      (failure) async {
        if (failure is ServerFailure) {
          _error = failure.message ?? 'Login failed';
        } else {
          _error = 'Login failed';
        }
        _isLoading = false;
        notifyListeners();
        return null;
      },
      (user) async {
        _user = user;
        _isAuthenticated = true;
        // Get token from SharedPreferences since it's stored there by the controller
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('token');
        _isLoading = false;
        _error = null;
        notifyListeners();
        return _user;
      },
    );
  }
  

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    _user = null;
    _token = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  Future<UserModel?> register(UserModel userModel) async {
    var result = await userController.registerUser(userModel);

    _isLoading = true;
    _error = null;
    notifyListeners();
    return await result.fold(
      (failure) async {
        if (failure is ServerFailure) {
          _error = failure.message ?? 'Registration failed';
        } else {
          _error = 'Registration failed';
        }
        _isLoading = false;
        notifyListeners();
        return null;
      },
      (user) async {
        _user = user;
        _isLoading = false;
        _error = null;
        notifyListeners();
        return _user;
      },
    );
  }

  Future<bool> getAUser(String id)async{
    var result = await userController.getUser(id);
    return await result.fold(
            (failure){
              return false;},
            (user)async{
              _user=user;
              notifyListeners();
              return true;
            }
    );
  }
}
