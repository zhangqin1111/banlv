import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants/app_copy.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/eb_primary_button.dart';
import '../../core/widgets/momo_orb.dart';
import '../../services/analytics_service.dart';
import '../../services/mood_weather_api_service.dart';

class MoodWeatherPage extends StatefulWidget {
  const MoodWeatherPage({super.key});

  @override
  State<MoodWeatherPage> createState() => _MoodWeatherPageState();
}

class _MoodWeatherPageState extends State<MoodWeatherPage> {
  static const List<_EmotionOption> _emotionOptions = <_EmotionOption>[
    _EmotionOption(
      label: '低落',
      weatherTitle: '阴下来的一片云',
      sceneHint: '今天像有一朵云贴得很近，先不用急着把它拨开。',
      icon: Icons.cloud_rounded,
      accent: AppColors.calmGreen,
      glow: AppColors.lavender,
    ),
    _EmotionOption(
      label: '平静',
      weatherTitle: '很轻的微风',
      sceneHint: '这份安静也值得被记住，不一定非要发生什么。',
      icon: Icons.air_rounded,
      accent: AppColors.mistBlue,
      glow: AppColors.calmGreen,
    ),
    _EmotionOption(
      label: '疲惫',
      weatherTitle: '慢慢落下来的雾',
      sceneHint: '像是整个人都想先靠一会，我们就先替今天按慢一点。',
      icon: Icons.hotel_rounded,
      accent: AppColors.calmGreen,
      glow: AppColors.softCream,
    ),
    _EmotionOption(
      label: '生气',
      weatherTitle: '一阵挤在心口的红雾',
      sceneHint: '那股顶着的劲不用立刻压下去，可以先安全地散一散。',
      icon: Icons.whatshot_rounded,
      accent: AppColors.gentleRed,
      glow: AppColors.peachGlow,
    ),
    _EmotionOption(
      label: '焦虑',
      weatherTitle: '转个不停的风',
      sceneHint: '脑子里像有很多线同时拉着，先替自己收一小截回来。',
      icon: Icons.waves_rounded,
      accent: AppColors.lavender,
      glow: AppColors.mistBlue,
    ),
    _EmotionOption(
      label: '开心',
      weatherTitle: '被照亮的一小块晴空',
      sceneHint: '这一点亮光很好，值得被好好托住，不让它一下子溜走。',
      icon: Icons.wb_sunny_rounded,
      accent: AppColors.sun,
      glow: AppColors.peachGlow,
    ),
  ];

  final MoodWeatherApiService _service = MoodWeatherApiService();
  final TextEditingController _noteController = TextEditingController();

  String _selectedEmotion = '平静';
  double _intensity = 5;
  MoodWeatherResult? _result;
  bool _isSubmitting = false;

  _EmotionOption get _currentOption => _emotionOptions.firstWhere(
        (_EmotionOption option) => option.label == _selectedEmotion,
        orElse: () => _emotionOptions[1],
      );

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('checkin_start');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final MoodWeatherResult result = await _service.submitCheckin(
      emotion: _selectedEmotion,
      intensity: _intensity.round(),
      noteText: _noteController.text.trim(),
    );

    AnalyticsService.instance.logEvent(
      'checkin_complete',
      payload: <String, Object?>{
        'mood_type': _selectedEmotion,
        'intensity': _intensity.round(),
        'recommended_mode': result.recommendedMode,
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _result = result;
      _isSubmitting = false;
    });
  }

  void _clearResult() {
    if (_result != null) {
      setState(() => _result = null);
    }
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'anger_mode':
        return '推荐你去“气泡散开”，把那股顶着的劲安全地放一放。';
      case 'joy_mode':
        return '推荐你去“亮光漂流”，把今天这点好感觉留久一点。';
      default:
        return '推荐你去“云团慢呼吸”，先让自己慢慢松下来。';
    }
  }

  IconData _inviteIcon(InviteCardModel card) {
    if (card.route == '/treehole') {
      return Icons.chat_bubble_rounded;
    }
    if (card.route == '/blind-box') {
      return Icons.card_giftcard_rounded;
    }
    switch (card.mode) {
      case 'joy_mode':
        return Icons.auto_awesome_rounded;
      case 'anger_mode':
        return Icons.blur_on_rounded;
      default:
        return Icons.spa_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _EmotionOption option = _currentOption;

    return Scaffold(
      appBar: AppBar(title: const Text('情绪气象台')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.skyBackground,
              option.accent.withValues(alpha: 0.16),
              AppColors.softCream,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            _WeatherHero(option: option),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppCopy.moodWeatherPrompt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '原始需求里最重要的不是“判断对错”，而是让不同情绪进入不同陪伴方式。我们先从今天的小天气开始。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subInk,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            EbGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '今天更像哪一片天气？',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _emotionOptions.map((option) {
                      final bool selected = option.label == _selectedEmotion;
                      return _EmotionChip(
                        option: option,
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedEmotion = option.label);
                          _clearResult();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EbGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '这阵感觉现在有多满？',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_intensity.round()} / 10',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Slider(
                    value: _intensity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (double value) {
                      setState(() => _intensity = value);
                      _clearResult();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text('轻一点'),
                      Text('很满了'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EbGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '要不要再写一句此刻？',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '可以是一句话，也可以只是一小段碎碎念。不写也没关系。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subInk,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 4,
                    onChanged: (_) => _clearResult(),
                    decoration: const InputDecoration(
                      hintText: '比如：今天下班回家前，整个人已经快没电了。',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EbPrimaryButton(
              label: _isSubmitting ? 'momo 正在收下这片天气...' : '收下今天的小天气',
              icon: Icons.cloud_rounded,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_result != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              EbGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(option.icon, color: option.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            option.weatherTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _result!.empathyText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: option.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.nightlight_round, color: option.accent),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(_modeLabel(_result!.recommendedMode))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._result!.inviteCards.map((InviteCardModel card) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    onTap: () {
                      AnalyticsService.instance.logEvent(
                        'module_open',
                        payload: <String, Object?>{
                          'module': card.route.replaceFirst('/', ''),
                          'source': 'mood_weather_invite',
                          'mode_id': card.mode ?? '',
                          'mood_type': _selectedEmotion,
                        },
                      );
                      context.push(card.route);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: option.accent.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: option.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(_inviteIcon(card), color: option.accent),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    card.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.subtitle,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.subInk,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeatherHero extends StatelessWidget {
  const _WeatherHero({required this.option});

  final _EmotionOption option;

  @override
  Widget build(BuildContext context) {
    return EbGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              option.glow.withValues(alpha: 0.5),
              Colors.white.withValues(alpha: 0.9),
              option.accent.withValues(alpha: 0.24),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 22,
              top: 22,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  option.weatherTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 70,
              child: Text(
                option.sceneHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                    ),
              ),
            ),
            Positioned(
              left: 34,
              top: 136,
              child: _FloatingDot(
                color: option.accent.withValues(alpha: 0.32),
                size: 16,
              ),
            ),
            Positioned(
              right: 42,
              top: 116,
              child: _FloatingDot(
                color: option.glow.withValues(alpha: 0.42),
                size: 24,
              ),
            ),
            Positioned(
              right: 74,
              top: 56,
              child: Icon(option.icon, size: 42, color: option.accent),
            ),
            Align(
              alignment: const Alignment(0, 0.6),
              child: MomoOrb(size: 124, glowColor: option.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  const _EmotionChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _EmotionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? option.accent.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: selected
                ? option.accent.withValues(alpha: 0.58)
                : Colors.white.withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(option.icon, size: 18, color: selected ? AppColors.ink : option.accent),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _EmotionOption {
  const _EmotionOption({
    required this.label,
    required this.weatherTitle,
    required this.sceneHint,
    required this.icon,
    required this.accent,
    required this.glow,
  });

  final String label;
  final String weatherTitle;
  final String sceneHint;
  final IconData icon;
  final Color accent;
  final Color glow;
}
