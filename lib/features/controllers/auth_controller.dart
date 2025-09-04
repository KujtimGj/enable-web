import 'dart:convert';

import 'package:enable_web/core/api.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/features/entities/agency.dart';
import 'package:enable_web/features/entities/user.dart';
import 'package:dartz/dartz.dart';
import '../../core/failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController{

  final ApiClient _apiClient = ApiClient();
  
  Future<Either<Failure, UserLoginResponse>> signIn(String email, String password) async {
    try{
        var loginBody = {"email":email,"password":password};
        final response = await _apiClient.post(ApiEndpoints.loginUserUrl.replaceFirst(ApiEndpoints.baseUrl, ""),data: loginBody);
        final decodedData = response.data;

        if (response.statusCode == 200) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          
          // Parse the user login response
          var loginResponse = UserLoginResponse.fromJson(decodedData);
          
          // Save user data
          prefs.setString('user', jsonEncode(loginResponse.user.toJson()));
          
          // Save token
          prefs.setString('token', loginResponse.token);
          
          prefs.setBool('isAuthenticated', true);
          

          return Right(loginResponse);
        } else {
          return Left(ServerFailure(message: response.data['message'] ?? 'Unknown login error'));
        }
    }catch(e){
      print('Error during log in: $e');
      return Left(ServerFailure());
    }
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.setBool('isAuthenticated', false);
  }

  Future<bool> isAuthenticated() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAuthenticated') ?? false;
  }

  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<AgencyModel?> getAgency() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final agencyJson = prefs.getString('agency');
    if (agencyJson != null) {
      final agencyMap = jsonDecode(agencyJson);
      return AgencyModel.fromJson(agencyMap);
    }
    return null;
  }

  Future<UserModel?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      return UserModel.fromJson(userMap);
    }
    return null;
  }
}