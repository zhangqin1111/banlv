import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/widgets/eb_glass_card.dart';
import '../../../core/widgets/momo_orb.dart';
import '../../../services/analytics_service.dart';
import '../../../services/mode_session_service.dart';
import '../mode_page_scaffold.dart';

class JoyModePage extends StatefulWidget {
  const JoyModePage({super.key});

  @override
  State<JoyModePage> createState() => _JoyModePageState();
}

class _JoyModePageState extends State<JoyModePage> {
  static const List<Alignment> _positions = <Alignment>[
    Alignment(-0.76, -0.7),
    Alignment(-0.3, -0.38),
    Alignment(0.3, -0.62),
    Alignment(0.76, -0.18),
    Alignment(0.58, 0.36),
    Alignment(-0.7, 0.24),
    Alignment(-0.14, 0.58),
    Alignment(0.16, 0.02),
  ];

  static const List<String> _warmNotes = <String>[
    '先把今天的一点亮光留住。',
    '这点轻盈已经被看见了。',
    '不用很大，只要这一小束就很好。',
    'momo 正在替你把它托住。',
  ];

  final ModeSessionService _service = ModeSessionService();
  final Set<int> _collected = <int>{};
  bool _isSaving = false;

  int get _progress => _collected.length;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent(
      'mode_scene_start',
      payload: <String, Object?>{'mode_id': 'joy_mode'},
    );
  }

  Future<void> _finish() async {
    if (_isSaving || _progress == 0) {
      return;
    }

    setState(() => _isSaving = true);
    final int helpfulScore = _progress >= 5 ? 2 : 1;
    final ModeSessionResult result = await _service.completeMode(
      modeType: 'joy_mode',
      durationSec: 45 + (_progress * 5),
      helpfulScore: helpfulScore,
    );
    AnalyticsService.instance.logEvent(
      'mode_scene_completion',
      payload: <String, Object?>{
        'mode_id': 'joy_mode',
        'completion_status': 'completed',
        'helpful_score': helpfulScore,
        'progress': _progress,
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    await showModeCompletionSheet(
      context,
      title: '这一点亮光已经被好好留住了',
      glowColor: AppColors.sun,
      result: result,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String get _progressCopy {
    if (_progress >= 6) {
      return '已经很亮了，可以把这份好感觉慢慢收下。';
    }
    return _warmNotes[_progress.clamp(0, _warmNotes.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return ModePageScaffold(
      title: '亮光漂流',
      subtitle: '把这点开心再留一会',
      hint: '轻点那些漂浮的光粒，让 momo 帮你把这一刻托住，不让它一下子溜走。',
      glowColor: AppColors.sun,
      metricLabel: '收住的亮光',
      progress: _progress,
      target: 6,
      isSaving: _isSaving,
      finishEnabled: _progress >= 3,
      onFinish: _finish,
      scene: EbGlassCard(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.95,
                    colors: <Color>[
                      AppColors.sun.withValues(alpha: 0.18 + (_progress * 0.05)),
                      Colors.white.withValues(alpha: 0.92),
                      AppColors.peachGlow.withValues(alpha: 0.28),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MomoOrb(
                    size: 122,
                    glowColor: Color.lerp(
                          AppColors.peachGlow,
                          AppColors.sun,
                          (_progress / 6).clamp(0, 1),
                        ) ??
                        AppColors.sun,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _progressCopy,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subInk,
                        ),
                  ),
                ],
              ),
            ),
            ...List<Widget>.generate(_positions.length, (int index) {
              final bool collected = _collected.contains(index);
              final double size = index.isEven ? 32 : 26;
              return Align(
                alignment: _positions[index],
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: collected ? 0.15 : 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: collected ? 0 : 1,
                    child: GestureDetector(
                      onTap: collected
                          ? null
                          : () => setState(() {
                                _collected.add(index);
                              }),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.sun.withValues(alpha: 0.48),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, size: 17),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Text(
                _progress >= 6 ? '够亮了，先把这束光带回去。' : '一点一点来，不用一下子全收集完。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subInk,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
