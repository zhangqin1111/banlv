import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/eb_primary_button.dart';

class SafetyBlockPage extends StatelessWidget {
  const SafetyBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('先停一停')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          const EbGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('我在认真看待你刚才说的话。'),
                SizedBox(height: AppSpacing.sm),
                Text('现在更重要的是先联系现实中的支持资源，而不是继续普通陪聊。'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const EbGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('可以先做的事'),
                SizedBox(height: AppSpacing.sm),
                Text('1. 联系你信任的人，让对方知道你现在需要陪伴。'),
                Text('2. 先离开让你更难受的环境或工具。'),
                Text('3. 如果眼前风险正在升高，请立即联系当地急救或紧急求助资源。'),
                Text('4. 如果你未满 18 岁，请尽快告诉可信任的成年人。'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EbPrimaryButton(
            label: '回到首页',
            icon: Icons.home_rounded,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
