import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../services/analytics_service.dart';
import '../../services/device_identity_service.dart';
import '../../services/settings_api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsApiService _settingsApiService = SettingsApiService();
  final DeviceIdentityService _identityService = DeviceIdentityService();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('settings_open');
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清空这位访客的记录？'),
          content: const Text(
            '这会删除当前匿名身份下的树洞、情绪记录、盲盒和成长数据。删除后会自动生成一个新的访客身份。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('先不要'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认清空'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _deleting = true);
    final bool synced = await _settingsApiService.deleteAccount();
    await _identityService.resetGuestIdentity();
    AnalyticsService.instance.logEvent(
      'delete_account',
      payload: <String, Object?>{'synced': synced},
    );
    if (!mounted) {
      return;
    }

    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced ? '已经清空这位访客的记录，并为你准备了新的开始。' : '本机身份已重置，云端请求稍后会继续重试。',
        ),
      ),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          const SwitchListTile(
            value: true,
            onChanged: null,
            title: Text('温柔提醒'),
            subtitle: Text('先保留开关位置，后面会接本地通知能力。'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('18+ 与安全说明'),
            subtitle: const Text('匿名陪伴，不替代现实支持或紧急求助。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            title: const Text('清空当前访客数据'),
            subtitle: Text(
              _deleting ? '正在为你清空这位访客的匿名记录' : '删除当前匿名身份下的所有记录，并重新开始',
            ),
            trailing: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            onTap: _deleting ? null : _deleteAccount,
          ),
          const ListTile(
            title: Text('版本信息'),
            subtitle: Text('MVP 0.1.0'),
          ),
        ],
      ),
    );
  }
}
