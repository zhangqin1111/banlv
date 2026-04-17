import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/widgets/eb_glass_card.dart';
import '../../../core/widgets/momo_orb.dart';
import '../../../services/analytics_service.dart';
import '../../../services/mode_session_service.dart';
import '../mode_page_scaffold.dart';

class LowModePage extends StatefulWidget {
  const LowModePage({super.key});

  @override
  State<LowModePage> createState() => _LowModePageState();
}

class _LowModePageState extends State<LowModePage> with SingleTickerProviderStateMixin {
  static const List<String> _roundNotes = <String>[
    '第一轮：先让肩膀知道，你已经准备慢一点了。',
    '第二轮：不用把难受都赶走，只先让它轻一点。',
    '第三轮：这一阵已经没有刚才那么挤了。',
  ];

  final ModeSessionService _service = ModeSessionService();
  late final AnimationController _controller;
  int _rounds = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent(
      'mode_scene_start',
      payload: <String, Object?>{'mode_id': 'low_mode'},
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _phaseLabel {
    final double value = _controller.value;
    if (value < 0.42) {
      return '吸气';
    }
    if (value < 0.58) {
      return '停一停';
    }
    return '呼气';
  }

  String get _roundLabel {
    if (_rounds == 0) {
      return '跟着云团做三轮慢呼吸，不用追求完美。';
    }
    return _roundNotes[(_rounds - 1).clamp(0, _roundNotes.length - 1)];
  }

  Future<void> _finish() async {
    if (_isSaving || _rounds == 0) {
      return;
    }
    setState(() => _isSaving = true);
    final int helpfulScore = _rounds >= 3 ? 2 : 1;
    final ModeSessionResult result = await _service.completeMode(
      modeType: 'low_mode',
      durationSec: 50 + (_rounds * 12),
      helpfulScore: helpfulScore,
    );
    AnalyticsService.instance.logEvent(
      'mode_scene_completion',
      payload: <String, Object?>{
        'mode_id': 'low_mode',
        'completion_status': 'completed',
        'helpful_score': helpfulScore,
        'progress': _rounds,
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    await showModeCompletionSheet(
      context,
      title: '这阵闷闷的云已经松开一点了',
      glowColor: AppColors.calmGreen,
      result: result,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModePageScaffold(
      title: '云团慢呼吸',
      subtitle: '先陪自己慢下来',
      hint: '原始需求里“低落”不该被催着解决。我们先跟着云团收放三轮，让节奏慢一点就好。',
      glowColor: AppColors.calmGreen,
      metricLabel: '完成的呼吸轮次',
      progress: _rounds,
      target: 3,
      isSaving: _isSaving,
      finishEnabled: _rounds >= 2,
      onFinish: _finish,
      scene: EbGlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double size = 140 + (_controller.value * 58);
                final double innerSize = 90 + (_controller.value * 30);
                return SizedBox(
                  width: 260,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.calmGreen.withValues(alpha: 0.12),
                        ),
                      ),
                      Container(
                        width: innerSize + 48,
                        height: innerSize + 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.calmGreen.withValues(alpha: 0.42),
                            width: 2.6,
                          ),
                        ),
                      ),
                      Container(
                        width: innerSize,
                        height: innerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.58),
                        ),
                      ),
                      const MomoOrb(size: 100, glowColor: AppColors.calmGreen),
                      Positioned(
                        bottom: 18,
                        child: Text(
                          _phaseLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _roundLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subInk,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: _rounds >= 3 ? null : () => setState(() => _rounds += 1),
              icon: const Icon(Icons.spa_rounded),
              label: Text(_rounds >= 3 ? '三轮都完成了' : '跟完这一轮'),
            ),
          ],
        ),
      ),
    );
  }
}
