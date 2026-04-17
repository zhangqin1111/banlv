import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/eb_primary_button.dart';
import '../../services/analytics_service.dart';
import '../../services/report_api_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _controller = TextEditingController();
  final ReportApiService _reportApiService = ReportApiService();
  String _category = '内容不适';
  bool _submitting = false;

  bool get _canSubmit => _controller.text.trim().isNotEmpty && !_submitting;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() => _submitting = true);
    await _reportApiService.submitReport(
      category: _category,
      message: _controller.text.trim(),
    );
    AnalyticsService.instance.logEvent(
      'report_submit',
      payload: <String, Object?>{'category': _category},
    );
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('反馈已经收到，谢谢你告诉我们。')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('举报与反馈')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          const EbGlassCard(
            child: Text(
              '如果你遇到了不适的内容、错误引导，或者哪里让你觉得别扭，都可以留在这里。',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: '内容不适', child: Text('内容不适')),
              DropdownMenuItem(value: '错误引导', child: Text('错误引导')),
              DropdownMenuItem(value: '其他问题', child: Text('其他问题')),
            ],
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '可以告诉我们发生了什么，或者哪一句话让你不舒服。',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EbPrimaryButton(
            label: _submitting ? '正在提交...' : '提交反馈',
            icon: Icons.flag_rounded,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
