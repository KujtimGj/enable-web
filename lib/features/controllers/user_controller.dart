import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:enable_web/core/failure.dart';
import 'package:flutter/material.dart';
import 'package:enable_web/core/dio_api.dart';
import 'package:enable_web/core/api.dart';
import 'package:enable_web/features/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class UserController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  Future<Either<Failure, UserModel>> loginUser(String email, String password,) async {
    try {
      var loginBody = {'email': email, 'password': password};
      final response = await _apiClient.post(
        "/auth/login/user",
        data: loginBody,
      );
      final decodedData = response.data;
      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        var user = decodedData['user'];
        var token = decodedData['token'];
        prefs.setString('user', jsonEncode(user));
        prefs.setString('token', token);
        var userModel = UserModel.fromJson(user);
        return Right(userModel);
      } else {
        return Left(ServerFailure(message: response.data['message']));
      }
    } catch (e) {
      if (e is DioException) {

      }
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure,UserModel>> registerUser(UserModel userModel) async{
    try{
      var body = userModel.toJson();
      final response = await _apiClient.post(ApiEndpoints.registerUrl.replaceFirst(ApiEndpoints.baseUrl, ''),data: body);
      final decodedData = response.data;
      if(response.statusCode == 200 || response.statusCode==201){
          var userModel = UserModel.fromJson(decodedData);
          return Right(userModel);
      }else{
        return Left(ServerFailure(message: response.data['message']));
      }
    }catch(e){
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, UserModel>> getUser(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.singleUser}/id'.replaceFirst(ApiEndpoints.baseUrl, ''));
      if (response.statusCode == 200) {
        var userModel = UserModel.fromJson(response.data);
        return Right(userModel);
      } else {
        return Left(ServerFailure());
      }
    } on DioException catch (e) {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
  // Future<Either<Failure,List<UserModel>>> getUsersByAgencyId(String agencyId) async {
  //   try {
  //
  //
  //     final response = await _apiClient.get(
  //       '${ApiEndpoints.agencyUsers}/$agencyId'.replaceFirst(ApiEndpoints.baseUrl, '')
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> usersData = response.data;
  //       return Right(_users);
  //     } else {
  //       return Left(NotFoundFailure());
  //     }
  //   } catch (e) {
  //     _error = 'Error fetching users: $e';
  //     return Left(ServerFailure());
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
}
