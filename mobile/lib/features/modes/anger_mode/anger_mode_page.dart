import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/widgets/eb_glass_card.dart';
import '../../../core/widgets/momo_orb.dart';
import '../../../services/analytics_service.dart';
import '../../../services/mode_session_service.dart';
import '../mode_page_scaffold.dart';

class AngerModePage extends StatefulWidget {
  const AngerModePage({super.key});

  @override
  State<AngerModePage> createState() => _AngerModePageState();
}

class _AngerModePageState extends State<AngerModePage> {
  static const List<Alignment> _bubblePositions = <Alignment>[
    Alignment(-0.72, -0.58),
    Alignment(-0.2, -0.18),
    Alignment(0.25, -0.62),
    Alignment(0.74, -0.08),
    Alignment(0.42, 0.38),
    Alignment(-0.62, 0.32),
    Alignment(-0.08, 0.56),
    Alignment(0.12, 0.05),
  ];

  static const List<double> _bubbleSizes = <double>[58, 72, 52, 66, 60, 64, 54, 70];

  final ModeSessionService _service = ModeSessionService();
  final Set<int> _released = <int>{};
  bool _isSaving = false;

  int get _progress => _released.length;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent(
      'mode_scene_start',
      payload: <String, Object?>{'mode_id': 'anger_mode'},
    );
  }

  Future<void> _finish() async {
    if (_isSaving || _progress == 0) {
      return;
    }
    setState(() => _isSaving = true);
    final int helpfulScore = _progress >= 5 ? 2 : 1;
    final ModeSessionResult result = await _service.completeMode(
      modeType: 'anger_mode',
      durationSec: 45 + (_progress * 6),
      helpfulScore: helpfulScore,
    );
    AnalyticsService.instance.logEvent(
      'mode_scene_completion',
      payload: <String, Object?>{
        'mode_id': 'anger_mode',
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
      title: '这股顶着的劲已经散开一点了',
      glowColor: AppColors.gentleRed,
      result: result,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String get _groundingCopy {
    if (_progress >= 6) {
      return '已经散开很多了，最后把肩膀慢慢放松下来。';
    }
    if (_progress >= 3) {
      return '这阵情绪已经被看见了，收口时不用再那么用力。';
    }
    return '不用压住它，只要让那些紧绷感一点点散开。';
  }

  @override
  Widget build(BuildContext context) {
    return ModePageScaffold(
      title: '气泡散开',
      subtitle: '先让那股绷紧感安全地散一散',
      hint: '原始需求里的“愤怒模式”不是说教，而是安全释放。把那些顶着的气泡戳散，最后再跟着 momo 收口。',
      glowColor: AppColors.gentleRed,
      metricLabel: '散开的气泡',
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
                    colors: <Color>[
                      AppColors.gentleRed.withValues(alpha: 0.24),
                      Colors.white.withValues(alpha: 0.9),
                      AppColors.peachGlow.withValues(alpha: 0.32),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.62),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const MomoOrb(size: 92, glowColor: AppColors.gentleRed),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _groundingCopy,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subInk,
                        ),
                  ),
                ],
              ),
            ),
            ...List<Widget>.generate(_bubblePositions.length, (int index) {
              final bool released = _released.contains(index);
              return Align(
                alignment: _bubblePositions[index],
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: released ? 0.2 : 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: released ? 0 : 1,
                    child: GestureDetector(
                      onTap: released
                          ? null
                          : () => setState(() {
                                _released.add(index);
                              }),
                      child: Container(
                        width: _bubbleSizes[index],
                        height: _bubbleSizes[index],
                        decoration: BoxDecoration(
                          color: AppColors.gentleRed.withValues(alpha: 0.56),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.84),
                            width: 2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.gentleRed.withValues(alpha: 0.3),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.blur_on_rounded, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
