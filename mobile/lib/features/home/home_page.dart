import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/momo_orb.dart';
import '../../core/widgets/momo_quote_bubble.dart';
import '../../services/analytics_service.dart';
import '../../services/home_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomeSummaryModel> _summaryFuture;
  int _heroWhisperIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('home_render');
    AnalyticsService.instance.logOnce(
      'home_age_notice',
      'age_notice_shown',
      payload: <String, Object?>{'surface': 'home'},
    );
    _summaryFuture = HomeService().fetchHomeSummary();
  }

  Future<void> _refresh() async {
    final Future<HomeSummaryModel> refreshed = HomeService().fetchHomeSummary();
    setState(() => _summaryFuture = refreshed);
    await refreshed;
  }

  void _openRoute(String route, {required String source}) {
    AnalyticsService.instance.logEvent(
      'module_open',
      payload: <String, Object?>{
        'module': route.replaceFirst('/', ''),
        'source': source,
      },
    );
    context.push(route);
  }

  List<String> _heroWhispers(String stage, List<String> dynamicLines) {
    if (dynamicLines.isNotEmpty) {
      return dynamicLines;
    }

    switch (stage) {
      case 'bloom':
        return const <String>[
          '我给你留了一个软软的位置。',
          '今天我们轻一点就好。',
          '我想把一点温柔分给你。',
        ];
      case 'glow':
        return const <String>[
          '你回来的时候，这里就亮了一点。',
          '累的话，也可以先摸摸我。',
          '今天先待一会也很好。',
        ];
      default:
        return const <String>[
          '我先在这里等你。',
          '只靠近一下也可以。',
          '不用马上整理好。',
        ];
    }
  }

  String _heroWhisper(String stage, List<String> dynamicLines) {
    final List<String> lines = _heroWhispers(stage, dynamicLines);
    return lines[_heroWhisperIndex % lines.length];
  }

  MomoMotion _heroMotion(String stage) {
    switch (stage) {
      case 'bloom':
        return MomoMotion.hop;
      case 'glow':
        return MomoMotion.excited;
      default:
        return MomoMotion.swim;
    }
  }

  MomoExpression _heroExpression(String stage) {
    final int moodIndex = _heroWhisperIndex % 3;
    switch (stage) {
      case 'bloom':
        return <MomoExpression>[
          MomoExpression.happy,
          MomoExpression.cheer,
          MomoExpression.happy,
        ][moodIndex];
      case 'glow':
        return <MomoExpression>[
          MomoExpression.softSmile,
          MomoExpression.happy,
          MomoExpression.curious,
        ][moodIndex];
      default:
        return <MomoExpression>[
          MomoExpression.softSmile,
          MomoExpression.sleepy,
          MomoExpression.curious,
        ][moodIndex];
    }
  }

  void _cycleHeroWhisper(String stage, List<String> dynamicLines) {
    final int total = _heroWhispers(stage, dynamicLines).length;
    setState(() {
      _heroWhisperIndex = (_heroWhisperIndex + 1) % total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.skyBackground,
            Color(0xFFF7FBFF),
            AppColors.softCream,
          ],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<HomeSummaryModel>(
          future: _summaryFuture,
          builder: (BuildContext context, AsyncSnapshot<HomeSummaryModel> snapshot) {
            final HomeSummaryModel summary =
                snapshot.data ??
                const HomeSummaryModel(
                  momoStage: 'seed',
                  growthPoints: 0,
                  lastSummary: '今天想从哪里开始都可以。',
                  entryBadges: <String>[],
                  whisperLines: <String>[
                    '我先在这里陪你一会。',
                    '不用马上整理好，我们慢一点也可以。',
                    '今天想从哪一块开始，都算在往前。',
                  ],
                );

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _HeroIsland(
                    whisperLine: _heroWhisper(
                      summary.momoStage,
                      summary.whisperLines,
                    ),
                    growthPoints: summary.growthPoints,
                    motion: _heroMotion(summary.momoStage),
                    expression: _heroExpression(summary.momoStage),
                    onMomoTap: () => _cycleHeroWhisper(
                      summary.momoStage,
                      summary.whisperLines,
                    ),
                    onTalkTap: () => _openRoute('/treehole', source: 'home_hero'),
                    onWeatherTap: () => _openRoute('/mood-weather', source: 'home_hero'),
                    onBlindBoxTap: () => _openRoute('/blind-box', source: 'home_hero'),
                    onGrowthTap: () => _openRoute('/growth', source: 'home_scene'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroIsland extends StatefulWidget {
  const _HeroIsland({
    required this.whisperLine,
    required this.growthPoints,
    required this.motion,
    required this.expression,
    required this.onMomoTap,
    required this.onTalkTap,
    required this.onWeatherTap,
    required this.onBlindBoxTap,
    required this.onGrowthTap,
  });

  final String whisperLine;
  final int growthPoints;
  final MomoMotion motion;
  final MomoExpression expression;
  final VoidCallback onMomoTap;
  final VoidCallback onTalkTap;
  final VoidCallback onWeatherTap;
  final VoidCallback onBlindBoxTap;
  final VoidCallback onGrowthTap;

  @override
  State<_HeroIsland> createState() => _HeroIslandState();
}

class _HeroIslandState extends State<_HeroIsland> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final double sceneHeight = math.max(720, math.min(viewportHeight * 0.92, 940.0));

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double wave = math.sin(_controller.value * math.pi * 2);
        final double rise = math.cos(_controller.value * math.pi * 2);
        final double momoOffsetX = wave * 16;
        final double momoOffsetY = (rise * 10) + (math.sin(_controller.value * math.pi * 4) * 4);
        final double frontCloudOffset = wave * 10;
        final double backCloudOffset = rise * 8;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(42),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFF4F9FF),
                Color(0xFFE6F2FF),
                Color(0xFFF1F8FF),
                Color(0xFFF7F6FF),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.mistBlue.withValues(alpha: 0.16),
                blurRadius: 42,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: SizedBox(
            height: sceneHeight,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double sceneWidth = constraints.maxWidth;
                final double islandWidth = sceneWidth * 1.78;
                final double islandHeight = math.max(sceneHeight * 0.44, 360);
                final double depthScale = 0.5 + (((rise + 1) / 2) * 0.24);
                final double momoSize = 92 + (depthScale * 18);
                final double momoDriftX = momoOffsetX * 2.2;
                final double momoDriftY = momoOffsetY * 1.9;
                final double edgeInset = math.max(16, sceneWidth * 0.04);

                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      top: -22,
                      right: -10,
                      child: Container(
                        width: sceneWidth * 0.38,
                        height: sceneWidth * 0.38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              AppColors.sun.withValues(alpha: 0.88),
                              AppColors.sun.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: sceneHeight * 0.05 + (rise * 2),
                      left: sceneWidth * 0.02,
                      child: _SkyMist(
                        width: sceneWidth * 0.48,
                        height: sceneHeight * 0.18,
                      ),
                    ),
                    Positioned(
                      top: sceneHeight * 0.08 - (wave * 2),
                      right: sceneWidth * 0.04,
                      child: _SkyMist(
                        width: sceneWidth * 0.34,
                        height: sceneHeight * 0.14,
                        tint: AppColors.lavender,
                      ),
                    ),
                    Positioned(
                      top: 78 + (wave * 1.6),
                      left: 18 + frontCloudOffset,
                      child: const _CloudBlob(width: 132, height: 56),
                    ),
                    Positioned(
                      top: 96 - (rise * 1.8),
                      right: 20 - backCloudOffset,
                      child: const _CloudBlob(width: 118, height: 50),
                    ),
                    Positioned(
                      top: sceneHeight * 0.23,
                      left: sceneWidth * 0.22 + (backCloudOffset * 0.4),
                      child: const _CloudBlob(
                        width: 90,
                        height: 40,
                        tint: Color(0xFFFDFBFF),
                      ),
                    ),
                    Positioned(
                      top: 26,
                      left: 0,
                      right: 0,
                      child: const Align(
                        alignment: Alignment.topCenter,
                        child: _SceneTitleBadge(
                          title: '我的小岛',
                          subtitle: '和 momo 靠岸一会',
                        ),
                      ),
                    ),
                    Positioned(
                      top: 52 + (frontCloudOffset * 0.2),
                      left: sceneWidth * 0.2,
                      child: const _SkySparkle(size: 18),
                    ),
                    Positioned(
                      top: 94 + (rise * 3),
                      left: sceneWidth * 0.34,
                      child: const _SkySparkle(size: 10, tint: AppColors.sun),
                    ),
                    Positioned(
                      top: 116 + (frontCloudOffset * 0.1),
                      right: sceneWidth * 0.28,
                      child: const _SkySparkle(size: 14, tint: AppColors.lavender),
                    ),
                    Positioned(
                      left: -40,
                      right: -40,
                      bottom: sceneHeight * 0.14,
                      child: Container(
                        height: sceneHeight * 0.24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.16),
                              AppColors.mistBlue.withValues(alpha: 0.08),
                              AppColors.mistBlue.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -50,
                      right: -50,
                      bottom: -sceneHeight * 0.02,
                      child: Container(
                        height: sceneHeight * 0.34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              AppColors.mistBlue.withValues(alpha: 0.18),
                              const Color(0xFFCDE4F8).withValues(alpha: 0.34),
                              const Color(0xFFB8D6F1).withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 26,
                      bottom: 248,
                      child: _FarIslet(width: 64, height: 22),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 260,
                      child: Transform.scale(
                        scale: 1.12,
                        child: const _FarIslet(width: 76, height: 24),
                      ),
                    ),
                    Positioned(
                      left: -sceneWidth * 0.28,
                      right: -sceneWidth * 0.28,
                      bottom: -sceneHeight * 0.12,
                      child: _IslandGround(
                        width: islandWidth,
                        height: islandHeight,
                      ),
                    ),
                    Positioned(
                      left: sceneWidth * 0.14,
                      bottom: sceneHeight * 0.1,
                      child: const _IslandTree(scale: 1.34),
                    ),
                    Positioned(
                      right: sceneWidth * 0.15,
                      bottom: sceneHeight * 0.12,
                      child: const _IslandHouse(scale: 1.26),
                    ),
                    Positioned(
                      left: edgeInset,
                      bottom: sceneHeight * 0.2 + (wave * 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SceneActionPill(
                            icon: Icons.chat_bubble_rounded,
                            label: '树洞',
                            onTap: widget.onTalkTap,
                          ),
                          const SizedBox(height: 10),
                          _SceneActionPill(
                            icon: Icons.air_rounded,
                            label: '天气',
                            onTap: widget.onWeatherTap,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: edgeInset,
                      top: sceneHeight * 0.2 + (rise * 4),
                      child: _SceneActionPill(
                        icon: Icons.auto_awesome_rounded,
                        label: '我的 momo',
                        onTap: widget.onGrowthTap,
                        tint: AppColors.lavender,
                      ),
                    ),
                    Positioned(
                      right: edgeInset,
                      bottom: sceneHeight * 0.22 + (rise * 3),
                      child: _SceneActionPill(
                        icon: Icons.card_giftcard_rounded,
                        label: '抽卡',
                        onTap: widget.onBlindBoxTap,
                        tint: AppColors.peachGlow,
                      ),
                    ),
                    Positioned(
                      right: sceneWidth * 0.22 - (wave * 9),
                      bottom: sceneHeight * 0.43 + (rise * 6),
                      child: const _FloatParticle(size: 14),
                    ),
                    Positioned(
                      left: sceneWidth * 0.18 + (rise * 7),
                      bottom: sceneHeight * 0.48 + (wave * 5),
                      child: const _FloatParticle(size: 10),
                    ),
                    Positioned(
                      right: sceneWidth * 0.34 + (wave * 6),
                      bottom: sceneHeight * 0.38 + (rise * 4),
                      child: const _FloatParticle(size: 8),
                    ),
                    Positioned(
                      left: (sceneWidth * 0.47) + momoDriftX,
                      bottom: sceneHeight * 0.38 + momoDriftY,
                      child: SizedBox(
                        width: 194,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Positioned(
                              left: 8,
                              top: 20,
                              child: Transform.rotate(
                                angle: wave * 0.04,
                                child: Transform.scale(
                                  scale: 0.82 + (((depthScale - 0.5) / 0.24) * 0.18),
                                  alignment: Alignment.center,
                                  child: const _SkyTrail(width: 186, height: 98),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 52,
                              bottom: 8,
                              child: Container(
                                width: 42 + (depthScale * 18),
                                height: 10 + (depthScale * 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppColors.mistBlue.withValues(alpha: 0.1 + (depthScale * 0.04)),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.mistBlue.withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 54,
                              top: 18,
                              child: Transform.rotate(
                                angle: wave * 0.035,
                                child: Transform.scale(
                                  scale: depthScale,
                                  alignment: Alignment.center,
                                  child: MomoOrb(
                                    size: momoSize,
                                    glowColor: AppColors.lavender,
                                    motion: widget.motion,
                                    expression: widget.expression,
                                    onTap: widget.onMomoTap,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -8,
                              top: -12,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: Transform.rotate(
                                  key: ValueKey<String>(widget.whisperLine),
                                  angle: -0.04,
                                  child: MomoQuoteBubble(
                                    text: widget.whisperLine,
                                    tint: AppColors.lavender,
                                    compact: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: -sceneWidth * 0.1,
                      right: -sceneWidth * 0.1,
                      bottom: -sceneHeight * 0.07,
                      child: Container(
                        height: sceneHeight * 0.19,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.06),
                              const Color(0xFFC4DDF3).withValues(alpha: 0.32),
                              const Color(0xFFAFCFEA).withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SceneTitleBadge extends StatelessWidget {
  const _SceneTitleBadge({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 236),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            AppColors.softCream.withValues(alpha: 0.56),
            AppColors.lavender.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.mistBlue.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.94),
                  AppColors.sun.withValues(alpha: 0.28),
                ],
              ),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              size: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sun.withValues(alpha: 0.9),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.sun.withValues(alpha: 0.36),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneActionPill extends StatelessWidget {
  const _SceneActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final Color baseTint = tint ?? AppColors.softCream;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.86),
                baseTint.withValues(alpha: 0.36),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.mistBlue.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 14, color: AppColors.ink),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandGround extends StatelessWidget {
  const _IslandGround({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double scale = width / 420;

    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: width * 0.05,
              right: width * 0.05,
              bottom: height * 0.05,
              child: Container(
                height: height * 0.58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(220),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFD4BA97),
                      Color(0xFFB7926F),
                      Color(0xFF8D6B52),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF8D6C54).withValues(alpha: 0.2),
                      blurRadius: 34,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: width * 0.02,
              right: width * 0.02,
              top: height * 0.02,
              child: Container(
                height: height * 0.63,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(240),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFF7F4DA),
                      Color(0xFFEAF0C8),
                      Color(0xFFDBE7B7),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.calmGreen.withValues(alpha: 0.16),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: width * 0.16,
              right: width * 0.16,
              top: height * 0.05,
              child: Container(
                height: height * 0.16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.42),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.08,
              top: height * 0.16,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: width * 0.28,
                  height: height * 0.12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1CC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              right: width * 0.08,
              top: height * 0.14,
              child: Transform.rotate(
                angle: 0.16,
                child: Container(
                  width: width * 0.3,
                  height: height * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F2CF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.31,
              top: height * 0.19,
              child: Transform.rotate(
                angle: -0.06,
                child: Container(
                  width: width * 0.26,
                  height: height * 0.16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.8),
                        const Color(0xFFD5EEFA),
                        const Color(0xFF9FD2F0),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.62),
                      width: 1.4,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.mistBlue.withValues(alpha: 0.18),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.39,
              top: height * 0.24,
              child: Transform.rotate(
                angle: 0.18,
                child: Container(
                  width: width * 0.13,
                  height: height * 0.032,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.16,
              bottom: height * 0.2,
              child: Transform.rotate(
                angle: -0.28,
                child: Container(
                  width: width * 0.24,
                  height: height * 0.052,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFFF8E8C4),
                        Color(0xFFE9C78B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.42,
              bottom: height * 0.24,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: width * 0.2,
                  height: height * 0.04,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFFF7E4BF),
                        Color(0xFFE6BE84),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.1,
              right: width * 0.1,
              bottom: height * 0.13,
              child: Container(
                height: height * 0.16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFFAEBCB),
                      Color(0xFFECCA92),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.16,
              right: width * 0.16,
              bottom: height * 0.15,
              child: Container(
                height: height * 0.03,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              left: width * 0.08,
              right: width * 0.08,
              bottom: height * 0.01,
              child: Container(
                height: height * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFFB68860).withValues(alpha: 0.26),
                      const Color(0xFF855E47).withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.12,
              bottom: height * 0.24,
              child: _BushCluster(scale: width / 340),
            ),
            Positioned(
              right: width * 0.14,
              bottom: height * 0.26,
              child: _BushCluster(scale: width / 380),
            ),
            Positioned(
              right: width * 0.28,
              bottom: height * 0.25,
              child: _FlowerDots(scale: scale * 0.78),
            ),
            Positioned(
              left: width * 0.24,
              top: height * 0.12,
              child: _FlowerDots(scale: scale * 0.66),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudBlob extends StatelessWidget {
  const _CloudBlob({
    required this.width,
    required this.height,
    this.tint = Colors.white,
  });

  final double width;
  final double height;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: width * 0.76,
                height: height * 0.52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.2,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.5),
                      tint.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const <double>[0, 0.6, 1],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.74, 0.18),
            child: Container(
              width: width * 0.34,
              height: height * 0.48,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.36),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.12, -0.08),
            child: Container(
              width: width * 0.42,
              height: height * 0.62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.98),
                    tint.withValues(alpha: 0.94),
                    const Color(0xFFF4F8FF).withValues(alpha: 0.92),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.44),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.58, 0.12),
            child: Container(
              width: width * 0.34,
              height: height * 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.96),
                    tint.withValues(alpha: 0.9),
                    const Color(0xFFF6FAFF).withValues(alpha: 0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.05, 0.48),
            child: Container(
              width: width * 0.68,
              height: height * 0.44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.96),
                    tint.withValues(alpha: 0.88),
                    const Color(0xFFF3F8FF).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyMist extends StatelessWidget {
  const _SkyMist({
    required this.width,
    required this.height,
    this.tint = AppColors.sun,
  });

  final double width;
  final double height;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.1),
          radius: 1.1,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.26),
            tint.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const <double>[0, 0.58, 1],
        ),
      ),
    );
  }
}

class _SkySparkle extends StatelessWidget {
  const _SkySparkle({
    required this.size,
    this.tint = AppColors.lavender,
  });

  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size * 0.34,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.9),
                  tint.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          Container(
            width: size,
            height: size * 0.34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.18),
                  tint.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.9),
                  tint.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatParticle extends StatelessWidget {
  const _FloatParticle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: 0.78),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.sun.withValues(alpha: 0.36),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _FarIslet extends StatelessWidget {
  const _FarIslet({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: SizedBox(
        width: width,
        height: height + (height * 0.9),
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              top: height * 0.42,
              child: Container(
                width: width * 0.9,
                height: height * 0.95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFB89C7D),
                      Color(0xFF94765E),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFF4F6E0),
                    Color(0xFFDEE8C8),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.calmGreen.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkyTrail extends StatelessWidget {
  const _SkyTrail({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SkyTrailPainter(),
    );
  }
}

class _SkyTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final Path first = Path()
      ..moveTo(size.width * 0.06, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.18,
        size.width * 0.82,
        size.height * 0.34,
      );

    final Paint secondPaint = Paint()
      ..color = AppColors.mistBlue.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Path second = Path()
      ..moveTo(size.width * 0.14, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.42,
        size.width * 0.94,
        size.height * 0.58,
      );

    canvas.drawPath(first, paint);
    canvas.drawPath(second, secondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IslandTree extends StatelessWidget {
  const _IslandTree({this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48 * scale,
      height: 72 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            width: 10 * scale,
            height: 32 * scale,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFC89D79),
                  Color(0xFFA37658),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Positioned(
            top: 12 * scale,
            left: 4 * scale,
            child: Container(
              width: 18 * scale,
              height: 18 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1D6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 2 * scale,
            left: 7 * scale,
            child: Container(
              width: 26 * scale,
              height: 24 * scale,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFE8F3DE),
                    Color(0xFFD3E7C6),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 22 * scale,
              height: 20 * scale,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFE8F6DD),
                    Color(0xFFD0E8C0),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 10 * scale,
            right: 6 * scale,
            child: Container(
              width: 10 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFF9D9CA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandHouse extends StatelessWidget {
  const _IslandHouse({this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52 * scale,
      height: 50 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            width: 32 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF8EFE3),
                ],
              ),
              borderRadius: BorderRadius.circular(10 * scale),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFB48A6C).withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8 * scale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.sun.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                ),
                SizedBox(width: 5 * scale),
                Container(
                  width: 6 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.sun.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8 * scale,
            top: 5 * scale,
            child: Container(
              width: 4 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFD8B79D),
                borderRadius: BorderRadius.circular(3 * scale),
              ),
            ),
          ),
          Positioned(
            top: 8 * scale,
            child: Container(
              width: 38 * scale,
              height: 16 * scale,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFFFE5D6),
                    Color(0xFFF3CDB6),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12 * scale),
                  topRight: Radius.circular(12 * scale),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 1 * scale,
            child: Container(
              width: 12 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFB98F70),
                borderRadius: BorderRadius.circular(4 * scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BushCluster extends StatelessWidget {
  const _BushCluster({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42 * scale,
      height: 22 * scale,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 18 * scale,
              height: 14 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFD8EBCB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 10 * scale,
            top: 0,
            child: Container(
              width: 18 * scale,
              height: 16 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F1D7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2 * scale,
            child: Container(
              width: 20 * scale,
              height: 14 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFD1E5BF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowerDots extends StatelessWidget {
  const _FlowerDots({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32 * scale,
      height: 18 * scale,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 6 * scale,
            child: _FlowerDot(color: const Color(0xFFF9D7C8), scale: scale),
          ),
          Positioned(
            left: 10 * scale,
            top: 0,
            child: _FlowerDot(color: const Color(0xFFFFE8B5), scale: scale),
          ),
          Positioned(
            right: 0,
            top: 5 * scale,
            child: _FlowerDot(color: const Color(0xFFD6E7F9), scale: scale),
          ),
        ],
      ),
    );
  }
}

class _FlowerDot extends StatelessWidget {
  const _FlowerDot({
    required this.color,
    required this.scale,
  });

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8 * scale,
      height: 8 * scale,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
