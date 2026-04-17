import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  final String _baseUrl;

  String get baseUrl => _baseUrl;

  Dio create({String? deviceId}) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    if (deviceId != null && deviceId.isNotEmpty) {
      dio.options.headers['X-Device-Id'] = deviceId;
    }

    return dio;
  }
}
