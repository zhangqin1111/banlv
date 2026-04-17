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
          '今天的你辛苦了。',
          '黑夜再长，也会有一点星光。',
          '如果想先安静一下，我就在这里。',
        ],
        duoChatLines: <HomeDuoLineModel>[
          HomeDuoLineModel(
            speaker: 'momo',
            text: '今天先把肩膀放松一点吧。',
            mood: 'soft_smile',
          ),
          HomeDuoLineModel(
            speaker: 'lulu',
            text: '嗯，我们陪你慢慢把这口气放下来。',
            mood: 'cheer',
          ),
          HomeDuoLineModel(
            speaker: 'momo',
            text: '如果只想待一会，也已经很好了。',
            mood: 'happy',
          ),
          HomeDuoLineModel(
            speaker: 'lulu',
            text: '那我就把小岛再暖一点，等你靠过来。',
            mood: 'curious',
          ),
        ],
        duoChatTurnLimit: 4,
      );
    }
  }
}
