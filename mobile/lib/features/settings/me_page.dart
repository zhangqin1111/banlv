import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/momo_orb.dart';
import '../../services/analytics_service.dart';
import '../../services/device_identity_service.dart';
import '../../services/growth_api_service.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<_MeSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('me_open');
    _snapshotFuture = _loadSnapshot();
  }

  Future<_MeSnapshot> _loadSnapshot() async {
    final GrowthSummaryModel growth = await GrowthApiService().fetchGrowthSummary();
    final String deviceId = await DeviceIdentityService().ensureGuestToken();
    return _MeSnapshot(growth: growth, deviceId: deviceId);
  }

  Future<void> _refresh() async {
    final Future<_MeSnapshot> refreshed = _loadSnapshot();
    setState(() => _snapshotFuture = refreshed);
    await refreshed;
  }

  String _stageTitle(String stage) {
    switch (stage) {
      case 'bloom':
        return '陪伴绽放中';
      case 'glow':
        return '柔光闪一闪';
      default:
        return '轻轻发芽';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_MeSnapshot>(
        future: _snapshotFuture,
        builder: (BuildContext context, AsyncSnapshot<_MeSnapshot> snapshot) {
          final _MeSnapshot? data = snapshot.data;
          final GrowthSummaryModel growth =
              data?.growth ??
              const GrowthSummaryModel(
                growthPoints: 0,
                currentStage: 'seed',
                nextStageAt: 10,
                recentEvents: <GrowthEventModel>[],
              );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                EbGlassCard(
                  child: Column(
                    children: <Widget>[
                      const MomoOrb(size: 120),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'momo 会记得你回来过的每一次。',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '这里放着成长、设置、隐私和反馈，也放着你和它最近的陪伴痕迹。',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.subInk,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          _MiniChip(label: _stageTitle(growth.currentStage)),
                          _MiniChip(label: '${growth.growthPoints} 点成长值'),
                          if (data != null) _MiniChip(label: '访客 ${data.shortDeviceLabel}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MeEntry(
                  title: '查看成长',
                  subtitle: '阶段、成长值、最近变化',
                  onTap: () => context.push('/growth'),
                ),
                _MeEntry(
                  title: '设置',
                  subtitle: '通知、偏好与匿名数据操作',
                  onTap: () => context.push('/settings'),
                ),
                _MeEntry(
                  title: '隐私说明',
                  subtitle: '了解我们如何保存和删除数据',
                  onTap: () => context.push('/privacy'),
                ),
                _MeEntry(
                  title: '举报与反馈',
                  subtitle: '提交不适内容或告诉我们哪里别扭',
                  onTap: () => context.push('/report'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MeEntry extends StatelessWidget {
  const _MeEntry({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        tileColor: Colors.white.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(label),
    );
  }
}

class _MeSnapshot {
  const _MeSnapshot({
    required this.growth,
    required this.deviceId,
  });

  final GrowthSummaryModel growth;
  final String deviceId;

  String get shortDeviceLabel {
    if (deviceId.length <= 6) {
      return deviceId;
    }
    return deviceId.substring(deviceId.length - 6);
  }
}
