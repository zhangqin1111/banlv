import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class RecordsApiService {
  RecordsApiService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<List<RecordItem>> fetchRecords({int days = 7}) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).get(
                '/v1/records',
                queryParameters: <String, dynamic>{'days': days},
              );
      final List<dynamic> items =
          response.data?['items'] as List<dynamic>? ?? <dynamic>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(RecordItem.fromJson)
          .toList();
    } catch (_) {
      return const <RecordItem>[];
    }
  }
}
