import 'dart:async';

import 'package:dio/dio.dart';

import '../core/models/app_models.dart';
import '../core/network/api_client.dart';
import 'device_identity_service.dart';

class ChatStreamService {
  ChatStreamService({
    ApiClient? apiClient,
    DeviceIdentityService? identityService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _identityService = identityService ?? DeviceIdentityService();

  final ApiClient _apiClient;
  final DeviceIdentityService _identityService;

  Future<String> createSession({String? opener}) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).post(
                '/v1/treehole/sessions',
                data: <String, dynamic>{'opener': opener ?? ''},
              );
      return response.data?['session_id'] as String? ?? 'offline-session';
    } on DioException {
      return 'offline-session';
    }
  }

  Future<List<ChatMessage>> fetchMessages({required String sessionId}) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).get(
                '/v1/treehole/sessions/$sessionId/messages',
              );
      final List<dynamic> items = response.data?['items'] as List<dynamic>? ?? <dynamic>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } on DioException {
      return <ChatMessage>[];
    }
  }

  Future<void> submitFeedback({
    required String sessionId,
    required int helpfulScore,
  }) async {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      await _apiClient.create(deviceId: deviceId).post(
        '/v1/treehole/sessions/$sessionId/feedback',
        data: <String, dynamic>{'helpful_score': helpfulScore},
      );
    } on DioException {
      // Feedback should not block the user from continuing.
    }
  }

  Stream<TreeholeStreamEvent> streamReply({
    required String sessionId,
    required String message,
    String? companionMode,
  }) async* {
    try {
      final String deviceId = await _identityService.ensureGuestToken();
      final Response<Map<String, dynamic>> response =
          await _apiClient.create(deviceId: deviceId).post(
                '/v1/treehole/sessions/$sessionId/reply',
                data: <String, dynamic>{
                  'message': message,
                  'companion_mode': companionMode,
                },
              );
      final Map<String, dynamic> payload = response.data ?? <String, dynamic>{};

      if ((payload['status'] as String?) == 'missing') {
        yield const TreeholeStreamEvent(
          type: 'error',
          payload: <String, dynamic>{'message': '树洞会话已经失效，请重新开始。'},
        );
        return;
      }

      if (payload['blocked'] == true) {
        yield TreeholeStreamEvent(
          type: 'safety_block',
          payload: <String, dynamic>{
            'reason': payload['reason'] as String? ?? 'high_risk',
            'severity': payload['severity'] as String? ?? 'high',
          },
        );
        return;
      }

      final String messageId =
          payload['message_id'] as String? ?? 'reply-${DateTime.now().millisecondsSinceEpoch}';
      final String replyText = payload['message'] as String? ?? '';
      final String? suggestion = payload['suggestion'] as String?;

      yield TreeholeStreamEvent(
        type: 'message_start',
        payload: <String, dynamic>{'message_id': messageId},
      );

      for (final String chunk in _chunkReply(replyText)) {
        await Future<void>.delayed(const Duration(milliseconds: 24));
        yield TreeholeStreamEvent(
          type: 'message_delta',
          payload: <String, dynamic>{
            'message_id': messageId,
            'delta': chunk,
          },
        );
      }

      yield TreeholeStreamEvent(
        type: 'message_done',
        payload: <String, dynamic>{
          'message_id': messageId,
          'suggestion': suggestion,
        },
      );
    } on DioException catch (error) {
      final String messageText = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['detail'] as String? ?? '现在这段连接有点不稳，我们先慢一点。')
          : '现在这段连接有点不稳，我们先慢一点。';
      yield TreeholeStreamEvent(
        type: 'error',
        payload: <String, dynamic>{'message': messageText},
      );
    }
  }

  Iterable<String> _chunkReply(String text) sync* {
    if (text.isEmpty) {
      return;
    }
    const int chunkSize = 10;
    for (int index = 0; index < text.length; index += chunkSize) {
      final int end = (index + chunkSize < text.length) ? index + chunkSize : text.length;
      yield text.substring(index, end);
    }
  }
}
