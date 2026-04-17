import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/momo_orb.dart';
import '../../services/analytics_service.dart';
import '../../services/device_identity_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final DeviceIdentityService _deviceIdentityService = DeviceIdentityService();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('app_open');
    AnalyticsService.instance.logOnce(
      'splash_age_notice',
      'age_notice_shown',
      payload: <String, Object?>{'surface': 'splash'},
    );
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _deviceIdentityService.ensureGuestToken();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.skyBackground, AppColors.softCream],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const MomoOrb(size: 156),
                  const SizedBox(height: AppSpacing.lg),
                  Text('EmoBot', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '和你一起，慢一点也没关系。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.subInk,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: Text(
                      '18+ 使用 · 匿名陪伴 · 不替代现实支持',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.subInk,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
