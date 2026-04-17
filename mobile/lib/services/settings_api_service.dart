import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class SettingsApiService {
  SettingsApiService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<bool> deleteAccount() async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      await _apiClient.create(deviceId: deviceId).post(
        '/v1/settings/delete-account',
      );
      return true;
    } on DioException {
      // Keep the local UX responsive even when the backend is unavailable.
      return false;
    }
  }
}
