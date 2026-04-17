class ModuleEntry {
  const ModuleEntry({
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String route;
}

class GuestIdentity {
  const GuestIdentity({
    required this.deviceId,
    required this.anonToken,
  });

  factory GuestIdentity.fromJson(Map<String, dynamic> json) {
    return GuestIdentity(
      deviceId: json['device_id'] as String? ?? '',
      anonToken: json['anon_token'] as String? ?? '',
    );
  }

  final String deviceId;
  final String anonToken;
}

class HomeSummaryModel {
  const HomeSummaryModel({
    this.momoStage = 'seed',
    this.growthPoints = 0,
    this.lastSummary = '今天想从哪里开始都可以。',
    this.entryBadges = const <String>[],
    this.whisperLines = const <String>[],
    this.duoChatLines = const <HomeDuoLineModel>[],
    this.duoChatTurnLimit = 4,
  });

  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) {
    return HomeSummaryModel(
      momoStage: json['momo_stage'] as String? ?? 'seed',
      growthPoints: json['growth_points'] as int? ?? 0,
      lastSummary: json['last_summary'] as String? ?? '今天想从哪里开始都可以。',
      entryBadges: (json['entry_badges'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      whisperLines: (json['whisper_lines'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .where((String item) => item.trim().isNotEmpty)
          .toList(),
      duoChatLines: (json['duo_chat_lines'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((Map item) => HomeDuoLineModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      duoChatTurnLimit: json['duo_chat_turn_limit'] as int? ?? 4,
    );
  }

  final String momoStage;
  final int growthPoints;
  final String lastSummary;
  final List<String> entryBadges;
  final List<String> whisperLines;
  final List<HomeDuoLineModel> duoChatLines;
  final int duoChatTurnLimit;
}

class HomeDuoLineModel {
  const HomeDuoLineModel({
    required this.speaker,
    required this.text,
    required this.mood,
  });

  factory HomeDuoLineModel.fromJson(Map<String, dynamic> json) {
    return HomeDuoLineModel(
      speaker: json['speaker'] as String? ?? 'momo',
      text: json['text'] as String? ?? '',
      mood: json['mood'] as String? ?? 'soft_smile',
    );
  }

  final String speaker;
  final String text;
  final String mood;
}

class InviteCardModel {
  const InviteCardModel({
    required this.title,
    required this.subtitle,
    required this.route,
    this.mode,
  });

  factory InviteCardModel.fromJson(Map<String, dynamic> json) {
    final String type = json['type'] as String? ?? '';
    final String mode = json['mode'] as String? ?? '';
    final String title = json['title'] as String? ?? '继续看看';
    final String route = json['route'] as String? ?? '/home';

    String subtitle = '往前走一小步也可以。';
    if (type == 'chat') {
      subtitle = '先把心里的话放下来。';
    } else if (type == 'mode') {
      subtitle = mode == 'anger_mode' ? '去安全释放一下。' : '去对应的小场景。';
    } else if (type == 'blind_box') {
      subtitle = '也许会有一句刚好适合你的话。';
    }

    return InviteCardModel(
      title: title,
      subtitle: subtitle,
      route: route,
      mode: mode.isEmpty ? null : mode,
    );
  }

  final String title;
  final String subtitle;
  final String route;
  final String? mode;
}

class MoodWeatherResult {
  const MoodWeatherResult({
    required this.checkinId,
    required this.empathyText,
    required this.recommendedMode,
    required this.inviteCards,
  });

  factory MoodWeatherResult.fromJson(Map<String, dynamic> json) {
    return MoodWeatherResult(
      checkinId: json['checkin_id'] as String? ?? '',
      empathyText: json['empathy_text'] as String? ?? '',
      recommendedMode: json['recommended_mode'] as String? ?? 'low_mode',
      inviteCards: (json['invite_cards'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((Map item) => InviteCardModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String checkinId;
  final String empathyText;
  final String recommendedMode;
  final List<InviteCardModel> inviteCards;
}

class BlindBoxCardModel {
  const BlindBoxCardModel({
    required this.drawId,
    required this.cardType,
    required this.cardTitle,
    required this.cardBody,
  });

  factory BlindBoxCardModel.fromJson(Map<String, dynamic> json) {
    return BlindBoxCardModel(
      drawId: json['draw_id'] as String? ?? '',
      cardType: json['card_type'] as String? ?? 'comfort',
      cardTitle: json['card_title'] as String? ?? '',
      cardBody: json['card_body'] as String? ?? '',
    );
  }

  final String drawId;
  final String cardType;
  final String cardTitle;
  final String cardBody;
}

class BlindBoxSaveResult {
  const BlindBoxSaveResult({
    required this.drawId,
    required this.isSaved,
  });

  factory BlindBoxSaveResult.fromJson(Map<String, dynamic> json) {
    return BlindBoxSaveResult(
      drawId: json['draw_id'] as String? ?? '',
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }

  final String drawId;
  final bool isSaved;
}

class GrowthEventModel {
  const GrowthEventModel({
    required this.sourceType,
    required this.deltaPoints,
    required this.createdAt,
  });

  factory GrowthEventModel.fromJson(Map<String, dynamic> json) {
    return GrowthEventModel(
      sourceType: json['source_type'] as String? ?? 'unknown',
      deltaPoints: json['delta_points'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String sourceType;
  final int deltaPoints;
  final DateTime createdAt;
}

class GrowthSummaryModel {
  const GrowthSummaryModel({
    required this.growthPoints,
    required this.currentStage,
    required this.nextStageAt,
    required this.recentEvents,
  });

  factory GrowthSummaryModel.fromJson(Map<String, dynamic> json) {
    return GrowthSummaryModel(
      growthPoints: json['growth_points'] as int? ?? 0,
      currentStage: json['current_stage'] as String? ?? 'seed',
      nextStageAt: json['next_stage_at'] as int? ?? 10,
      recentEvents: (json['recent_events'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((Map item) => GrowthEventModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final int growthPoints;
  final String currentStage;
  final int nextStageAt;
  final List<GrowthEventModel> recentEvents;
}

class RecordItem {
  const RecordItem({
    required this.id,
    required this.sourceType,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.createdAt,
  });

  factory RecordItem.fromJson(Map<String, dynamic> json) {
    final DateTime createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now();
    return RecordItem(
      id: json['id'] as String? ?? '',
      sourceType:
          json['source_type'] as String? ?? _inferRecordType(json['title'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timeLabel: _timeLabelFor(createdAt),
      createdAt: createdAt,
    );
  }

  final String id;
  final String sourceType;
  final String title;
  final String subtitle;
  final String timeLabel;
  final DateTime createdAt;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'assistant',
      text: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  final String role;
  final String text;
  final DateTime? createdAt;
}

class TreeholeStreamEvent {
  const TreeholeStreamEvent({
    required this.type,
    required this.payload,
  });

  final String type;
  final Map<String, dynamic> payload;
}

class ModeSessionResult {
  const ModeSessionResult({
    required this.sessionId,
    required this.modeType,
    required this.awardedPoints,
    required this.resultSummary,
  });

  factory ModeSessionResult.fromJson(Map<String, dynamic> json) {
    return ModeSessionResult(
      sessionId: json['session_id'] as String? ?? '',
      modeType: json['mode_type'] as String? ?? 'low_mode',
      awardedPoints: json['awarded_points'] as int? ?? 0,
      resultSummary: json['result_summary'] as String? ?? '',
    );
  }

  final String sessionId;
  final String modeType;
  final int awardedPoints;
  final String resultSummary;
}

String _timeLabelFor(DateTime dateTime) {
  final Duration diff = DateTime.now().difference(dateTime);
  if (diff.inDays <= 0) {
    return '今天';
  }
  if (diff.inDays == 1) {
    return '昨天';
  }
  return '${diff.inDays} 天前';
}

String _inferRecordType(String title) {
  if (title.contains('树洞')) {
    return 'treehole';
  }
  if (title.contains('盲盒')) {
    return 'blind_box';
  }
  if (title.contains('模式')) {
    return 'mode';
  }
  return 'mood_weather';
}
