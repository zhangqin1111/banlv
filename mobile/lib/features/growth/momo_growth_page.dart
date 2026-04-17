import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/momo_orb.dart';
import '../../services/analytics_service.dart';
import '../../services/growth_api_service.dart';

class MomoGrowthPage extends StatefulWidget {
  const MomoGrowthPage({super.key});

  @override
  State<MomoGrowthPage> createState() => _MomoGrowthPageState();
}

class _MomoGrowthPageState extends State<MomoGrowthPage> {
  late Future<GrowthSummaryModel> _future;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('growth_page_open');
    _future = GrowthApiService().fetchGrowthSummary();
  }

  Future<void> _refresh() async {
    final Future<GrowthSummaryModel> refreshed = GrowthApiService().fetchGrowthSummary();
    setState(() => _future = refreshed);
    await refreshed;
  }

  String _stageTitle(String stage) {
    switch (stage) {
      case 'bloom':
        return '正在舒展';
      case 'glow':
        return '会发光了';
      default:
        return '轻轻发芽';
    }
  }

  String _stageBody(String stage) {
    switch (stage) {
      case 'bloom':
        return 'momo 已经不只是安静地等你，它开始更主动地发亮、靠近，也更像一直住在你的小岛上。';
      case 'glow':
        return '你和 momo 的关系已经有了明显温度。它会记得你最近留下的痕迹，也会把光留得更久一点。';
      default:
        return '现在的 momo 还很软、很小，但每一次你回来照顾自己，它都会更有一点存在感。';
    }
  }

  String _eventLabel(String sourceType) {
    switch (sourceType) {
      case 'checkin':
        return '收下了一次情绪天气';
      case 'treehole':
        return '在树洞里待了一会';
      case 'mode':
        return '完成了一次小仪式';
      case 'blind_box':
        return '把一张今日卡收进来了';
      default:
        return sourceType;
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'bloom':
        return AppColors.sun;
      case 'glow':
        return AppColors.peachGlow;
      default:
        return AppColors.lavender;
    }
  }

  String _nextStageName(String stage) {
    switch (stage) {
      case 'seed':
        return '下一站：舒展 bloom';
      case 'bloom':
        return '下一站：发光 glow';
      default:
        return '已经来到最亮阶段';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的 momo')),
      body: FutureBuilder<GrowthSummaryModel>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<GrowthSummaryModel> snapshot) {
          final GrowthSummaryModel summary =
              snapshot.data ??
              const GrowthSummaryModel(
                growthPoints: 0,
                currentStage: 'seed',
                nextStageAt: 10,
                recentEvents: <GrowthEventModel>[],
              );
          final double progress = summary.nextStageAt == 0
              ? 0
              : (summary.growthPoints / summary.nextStageAt).clamp(0, 1);
          final Color stageColor = _stageColor(summary.currentStage);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                EbGlassCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          stageColor.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.92),
                          AppColors.skyBackground,
                        ],
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _stageTitle(summary.currentStage),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            const Positioned(
                              left: 16,
                              top: 12,
                              child: _AuraDot(size: 14, color: AppColors.lavender),
                            ),
                            Positioned(
                              right: 16,
                              top: 22,
                              child: _AuraDot(size: 18, color: stageColor),
                            ),
                            const Positioned(
                              right: 54,
                              bottom: 16,
                              child: _AuraDot(size: 10, color: AppColors.peachGlow),
                            ),
                            MomoOrb(size: 164, glowColor: stageColor),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _stageBody(summary.currentStage),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.subInk,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '每次你回来，momo 都会更像一个真正陪着你的角色。',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.subInk,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                EbGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '成长值 ${summary.growthPoints} / ${summary.nextStageAt}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            _nextStageName(summary.currentStage),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.subInk,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        summary.nextStageAt > summary.growthPoints
                            ? '再积累 ${summary.nextStageAt - summary.growthPoints} 点，momo 会更亮一点，也更像会主动回应你的样子。'
                            : '这一阶段已经被点亮了。现在的 momo 会把你最近的陪伴痕迹留得更久。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.subInk,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                EbGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('最近 momo 记住的事', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      if (summary.recentEvents.isEmpty)
                        const Text('还没有新的成长记录。')
                      else
                        ...summary.recentEvents.map((GrowthEventModel event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.68),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: stageColor.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_awesome_rounded),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(_eventLabel(event.sourceType)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${event.deltaPoints > 0 ? '+' : ''}${event.deltaPoints} 点成长',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.subInk,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${event.createdAt.month}/${event.createdAt.day}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuraDot extends StatelessWidget {
  const _AuraDot({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.42),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
