import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/eb_primary_button.dart';
import '../../core/widgets/momo_orb.dart';

class ModePageScaffold extends StatelessWidget {
  const ModePageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.glowColor,
    required this.metricLabel,
    required this.progress,
    required this.target,
    required this.scene,
    required this.onFinish,
    required this.isSaving,
    required this.finishEnabled,
  });

  final String title;
  final String subtitle;
  final String hint;
  final Color glowColor;
  final String metricLabel;
  final int progress;
  final int target;
  final Widget scene;
  final VoidCallback? onFinish;
  final bool isSaving;
  final bool finishEnabled;

  @override
  Widget build(BuildContext context) {
    final double ratio = target == 0 ? 0 : (progress / target).clamp(0, 1);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.skyBackground,
              glowColor.withValues(alpha: 0.2),
              AppColors.softCream,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              children: <Widget>[
                EbGlassCard(
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: glowColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'momo 的小仪式',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MomoOrb(size: 134, glowColor: glowColor),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        hint,
                        textAlign: TextAlign.center,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            metricLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '$progress / $target',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.subInk,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        finishEnabled
                            ? '已经够了，可以把这次感觉慢慢收下。'
                            : '不用着急完成，只要先在这里待一会就算数。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.subInk,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: scene),
                const SizedBox(height: AppSpacing.md),
                EbPrimaryButton(
                  label: isSaving
                      ? 'momo 正在把这次陪伴收起来...'
                      : finishEnabled
                          ? '收下这次小仪式'
                          : '先在这里待一会',
                  icon: Icons.check_rounded,
                  onPressed: finishEnabled && !isSaving ? onFinish : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showModeCompletionSheet(
  BuildContext context, {
  required String title,
  required Color glowColor,
  required ModeSessionResult result,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EbGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MomoOrb(size: 92, glowColor: glowColor),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                result.resultSummary,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'momo 收下了 ${result.awardedPoints} 点成长值，也记住了你刚刚陪自己的方式。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subInk,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              EbPrimaryButton(
                label: '回到上一页',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
