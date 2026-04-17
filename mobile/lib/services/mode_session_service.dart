import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class ModeSessionService {
  ModeSessionService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<ModeSessionResult> completeMode({
    required String modeType,
    required int durationSec,
    int helpfulScore = 2,
  }) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).post(
        '/v1/modes/sessions',
        data: <String, dynamic>{
          'mode_type': modeType,
          'duration_sec': durationSec,
          'helpful_score': helpfulScore,
        },
      );
      return ModeSessionResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException {
      return ModeSessionResult(
        sessionId: 'offline-$modeType',
        modeType: modeType,
        awardedPoints: 2,
        resultSummary: '这次小仪式已经被轻轻记下了，momo 会继续陪着你。',
      );
    }
  }
}
