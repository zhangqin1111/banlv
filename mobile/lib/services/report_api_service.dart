import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class ReportApiService {
  ReportApiService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<void> submitReport({
    required String category,
    required String message,
  }) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      await _apiClient.create(deviceId: deviceId).post(
        '/v1/reports',
        data: <String, dynamic>{
          'source_type': 'app',
          'source_id': 'general',
          'category': category,
          'message': message,
        },
      );
    } on DioException {
      // Reporting should never trap the user on the page.
    }
  }
}
