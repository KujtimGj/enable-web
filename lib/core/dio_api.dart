import 'package:dio/dio.dart';
import 'package:enable_web/core/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      // connectTimeout: const Duration(seconds: 30),
      // receiveTimeout: const Duration(seconds: 60),
      // Remove sendTimeout for web compatibility
    ));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Content-Type'] = 'application/json';
          
          // Add authentication token if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print("Dio Error: ${e.message}");
          print("Dio Error Status: ${e.response?.statusCode}");
          print("Dio Error Data: ${e.response?.data}");
          print("Dio Error Headers: ${e.response?.headers}");
          
          if (e.response?.statusCode == 401) {
            _handleTokenExpiration();
          }
          
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _handleTokenExpiration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('agency');
      await prefs.remove('token');
      await prefs.setBool('isAuthenticated', false);
    } catch (e) {
      print('Error handling token expiration: $e');
    }
  }

  Future<Response> get(String path) async {
    return _dio.get(path);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> postMultipart(String path, {required FormData formData}) async {
    return _dio.post(path, data: formData);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }
}