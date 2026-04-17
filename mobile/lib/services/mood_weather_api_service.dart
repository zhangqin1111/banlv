import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class MoodWeatherApiService {
  MoodWeatherApiService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<MoodWeatherResult> submitCheckin({
    required String emotion,
    required int intensity,
    required String noteText,
  }) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).post(
                '/v1/mood-weather/checkins',
                data: <String, dynamic>{
                  'emotion': emotion,
                  'intensity': intensity,
                  'note_text': noteText,
                },
              );

      return MoodWeatherResult.fromJson(response.data ?? <String, dynamic>{});
    } catch (_) {
      return const MoodWeatherResult(
        checkinId: 'offline-checkin',
        empathyText: '今天像有一点阴下来。先不用急着把一切都整理好，我们先把这片天气收住。',
        recommendedMode: 'low_mode',
        inviteCards: <InviteCardModel>[
          InviteCardModel(
            title: '说给我听',
            subtitle: '先把心里的话轻轻放下来。',
            route: '/treehole',
          ),
          InviteCardModel(
            title: '去云团里缓一缓',
            subtitle: '跟着小场景，把节奏慢下来一点。',
            route: '/mode/low',
            mode: 'low_mode',
          ),
          InviteCardModel(
            title: '抽一张今天的卡',
            subtitle: '也许会有一句话刚好落在你现在的心上。',
            route: '/blind-box',
          ),
        ],
      );
    }
  }
}
