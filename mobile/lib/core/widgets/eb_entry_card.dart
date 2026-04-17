import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'eb_glass_card.dart';

class EbEntryCard extends StatelessWidget {
  const EbEntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: EbGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.peachGlow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.subInk),
            ),
          ],
        ),
      ),
    );
  }
}
