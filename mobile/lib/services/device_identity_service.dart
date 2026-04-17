import '../core/models/app_models.dart';
import '../core/network/api_client.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  static const String _deviceIdKey = 'guest_device_id';
  static const String _anonTokenKey = 'guest_anon_token';
  static final Map<String, String> _sessionCache = <String, String>{};

  final ApiClient _apiClient;

  Future<String> ensureGuestToken() async {
    final String? storedDeviceId = _sessionCache[_deviceIdKey];
    final String? storedToken = _sessionCache[_anonTokenKey];
    if (storedDeviceId != null &&
        storedDeviceId.isNotEmpty &&
        storedToken != null &&
        storedToken.isNotEmpty) {
      return storedDeviceId;
    }

    try {
      final response = await _apiClient.create().post<Map<String, dynamic>>(
        '/v1/auth/guest',
      );
      final GuestIdentity identity =
          GuestIdentity.fromJson(response.data ?? <String, dynamic>{});
      if (identity.deviceId.isNotEmpty) {
        _sessionCache[_deviceIdKey] = identity.deviceId;
        _sessionCache[_anonTokenKey] = identity.anonToken;
        return identity.deviceId;
      }
    } catch (_) {
      // Fall through to local-only fallback.
    }

    final String fallbackDeviceId =
        storedDeviceId ?? 'local-${DateTime.now().millisecondsSinceEpoch}';
    _sessionCache[_deviceIdKey] = fallbackDeviceId;
    _sessionCache[_anonTokenKey] ??= 'offline-demo-token';
    return fallbackDeviceId;
  }

  Future<String?> currentDeviceId() async {
    return _sessionCache[_deviceIdKey];
  }

  Future<Map<String, String>> buildHeaders() async {
    final String deviceId = await ensureGuestToken();
    return <String, String>{'X-Device-Id': deviceId};
  }

  Future<void> resetGuestIdentity() async {
    _sessionCache.remove(_deviceIdKey);
    _sessionCache.remove(_anonTokenKey);
  }
}
