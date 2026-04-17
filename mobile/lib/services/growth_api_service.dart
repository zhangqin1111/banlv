import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class GrowthApiService {
  GrowthApiService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<GrowthSummaryModel> fetchGrowthSummary() async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).get('/v1/growth/summary');
      return GrowthSummaryModel.fromJson(response.data ?? <String, dynamic>{});
    } catch (_) {
      return const GrowthSummaryModel(
        growthPoints: 0,
        currentStage: 'seed',
        nextStageAt: 10,
        recentEvents: <GrowthEventModel>[],
      );
    }
  }
}
