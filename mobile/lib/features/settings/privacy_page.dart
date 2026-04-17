import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/eb_glass_card.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私说明')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const <Widget>[
          _PrivacySection(
            title: '匿名使用',
            lines: <String>[
              '我们默认以匿名设备身份记录使用行为，不要求你先注册账号。',
              '当前访客身份只用来关联你的树洞、情绪记录、盲盒和成长数据。',
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _PrivacySection(
            title: '数据保存',
            lines: <String>[
              '情绪标签、强度、模式结果和成长事件会用于生成记录页和我的 momo。',
              '高危文本不会作为普通历史长期缓存，会直接进入安全处理链路。',
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _PrivacySection(
            title: '删除与反馈',
            lines: <String>[
              '你可以在设置里清空当前访客数据，系统会为你生成一个新的匿名身份。',
              '如果你遇到不适内容，也可以随时通过举报与反馈页告诉我们。',
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _PrivacySection(
            title: '年龄与安全',
            lines: <String>[
              'EmoBot 面向 18+ 用户，不是医疗产品，不提供诊断或治疗承诺。',
              '遇到明确高危内容时，产品会停止普通陪聊并优先引导现实支持资源。',
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return EbGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...lines.map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subInk,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
