import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_env.dart';

class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  static String get defaultBaseUrl => AppEnv.apiBaseUrl;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('[DioError] ${e.requestOptions.method} ${e.requestOptions.path} => ${e.message}');
          return handler.next(e);
        },
      ),
    );
}
