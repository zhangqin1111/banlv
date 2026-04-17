import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class EbGlassCard extends StatelessWidget {
  const EbGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        color: Colors.white.withValues(alpha: 0.72),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.mistBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
