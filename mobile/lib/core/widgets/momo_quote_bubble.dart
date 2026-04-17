import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class MomoQuoteBubble extends StatelessWidget {
  const MomoQuoteBubble({
    super.key,
    required this.text,
    this.label,
    this.tint = AppColors.lavender,
    this.compact = false,
    this.align = CrossAxisAlignment.start,
  });

  final String text;
  final String? label;
  final Color tint;
  final bool compact;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = compact ? 12 : 14;
    final double verticalPadding = compact ? 10 : 12;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(maxWidth: compact ? 220 : 260),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding + 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(compact ? 20 : 22),
            border: Border.all(color: tint.withValues(alpha: 0.2)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tint.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: align,
            children: <Widget>[
              if (label != null) ...<Widget>[
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.subInk,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        Positioned(
          left: compact ? 18 : 22,
          bottom: -6,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tint.withValues(alpha: 0.16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
