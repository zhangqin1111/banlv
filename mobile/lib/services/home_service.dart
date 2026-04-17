import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class HomeService {
  HomeService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<HomeSummaryModel> fetchHomeSummary() async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).get('/v1/home/summary');
      return HomeSummaryModel.fromJson(response.data ?? <String, dynamic>{});
    } catch (_) {
      return const HomeSummaryModel(
        momoStage: 'seed',
        growthPoints: 0,
        lastSummary: '今天想从哪里开始都可以。',
        entryBadges: <String>['treehole', 'mood_weather', 'blind_box', 'growth'],
        whisperLines: <String>[
          '我先在这里陪你一会。',
          '不用马上整理好，我们慢一点也可以。',
          '今天想从哪一块开始，都算在往前。',
        ],
      );
    }
  }
}
