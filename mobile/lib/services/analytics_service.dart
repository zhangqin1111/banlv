import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'device_identity_service.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final DeviceIdentityService _identityService = DeviceIdentityService();
  final String _sessionId = 'session-${DateTime.now().millisecondsSinceEpoch}';
  final Set<String> _onceKeys = <String>{};

  void logEvent(String name, {Map<String, Object?> payload = const {}}) {
    unawaited(_emit(name, payload));
  }

  void logOnce(
    String key,
    String name, {
    Map<String, Object?> payload = const {},
  }) {
    if (!_onceKeys.add(key)) {
      return;
    }
    logEvent(name, payload: payload);
  }

  Future<void> _emit(String name, Map<String, Object?> payload) async {
    final String? deviceId = await _identityService.currentDeviceId();
    final Map<String, Object?> event = <String, Object?>{
      'event': name,
      'session_id': _sessionId,
      'device_id': deviceId ?? 'unknown',
      'ts': DateTime.now().toIso8601String(),
      ...payload,
    };
    debugPrint('[analytics] ${jsonEncode(event)}');
  }
}
