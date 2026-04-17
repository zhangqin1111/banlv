import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class BlindBoxApiService {
  BlindBoxApiService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<BlindBoxCardModel> drawCard({required String worryText}) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).post(
                '/v1/blind-box/draw',
                data: <String, dynamic>{'worry_text': worryText},
              );

      return BlindBoxCardModel.fromJson(response.data ?? <String, dynamic>{});
    } catch (_) {
      return const BlindBoxCardModel(
        drawId: 'offline-draw',
        cardType: 'comfort',
        cardTitle: '先把肩膀放松一点',
        cardBody: '现在不用解决一整天，只先照顾这一分钟。momo 会替你把这句轻轻收好。',
      );
    }
  }

  Future<BlindBoxSaveResult> saveCard(String drawId) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).post(
                '/v1/blind-box/$drawId/save',
              );
      return BlindBoxSaveResult.fromJson(response.data ?? <String, dynamic>{});
    } catch (_) {
      return BlindBoxSaveResult(drawId: drawId, isSaved: true);
    }
  }
}
