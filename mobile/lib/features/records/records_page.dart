import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../services/analytics_service.dart';
import '../../services/records_api_service.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late Future<List<RecordItem>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('records_open');
    _recordsFuture = RecordsApiService().fetchRecords();
  }

  Future<void> _refresh() async {
    final Future<List<RecordItem>> refreshed = RecordsApiService().fetchRecords();
    setState(() => _recordsFuture = refreshed);
    await refreshed;
  }

  IconData _iconFor(String sourceType) {
    switch (sourceType) {
      case 'treehole':
        return Icons.chat_bubble_rounded;
      case 'blind_box':
        return Icons.card_giftcard_rounded;
      case 'mode':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.filter_vintage_rounded;
    }
  }

  Color _colorFor(String sourceType) {
    switch (sourceType) {
      case 'treehole':
        return AppColors.lavender;
      case 'blind_box':
        return AppColors.peachGlow;
      case 'mode':
        return AppColors.sun;
      default:
        return AppColors.mistBlue;
    }
  }

  String _summaryLabel(List<RecordItem> items) {
    if (items.isEmpty) {
      return '今天还没有新的陪伴片段。';
    }
    final int modeCount = items.where((RecordItem item) => item.sourceType == 'mode').length;
    final int treeholeCount =
        items.where((RecordItem item) => item.sourceType == 'treehole').length;
    if (modeCount > 0 && treeholeCount > 0) {
      return '这几天你既有说出来，也有慢慢练习把自己收回来。';
    }
    if (treeholeCount > 0) {
      return '你有把心里的话慢慢放下来。';
    }
    if (modeCount > 0) {
      return '你有在一点点照顾自己的节奏。';
    }
    return '最近留下了一些轻轻的痕迹。';
  }

  Map<String, List<RecordItem>> _groupRecords(List<RecordItem> items) {
    final Map<String, List<RecordItem>> grouped = <String, List<RecordItem>>{};
    for (final RecordItem item in items) {
      grouped.putIfAbsent(item.timeLabel, () => <RecordItem>[]).add(item);
    }
    return grouped;
  }

  int _activeDayCount(List<RecordItem> items) {
    return items
        .map((RecordItem item) => DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day))
        .toSet()
        .length;
  }

  String _detailTimeLabel(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    if (DateUtils.isSameDay(dateTime, DateTime.now())) {
      return '$hour:$minute';
    }
    return '${dateTime.month}/${dateTime.day} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<RecordItem>>(
        future: _recordsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<RecordItem>> snapshot) {
          final List<RecordItem> items = snapshot.data ?? <RecordItem>[];
          final Map<String, List<RecordItem>> grouped = _groupRecords(items);
          final int activeDays = _activeDayCount(items);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                Text('最近和 momo 一起留下的痕迹', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '原始需求里，记录不该只是日志，而是你这几天和自己待过的片段。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.subInk,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                EbGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('最近 7 天', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: items.isEmpty ? 0 : (activeDays / 7).clamp(0, 1),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        activeDays == 0 ? '这周还没有留下新的痕迹。' : '这 7 天里，你已经在 $activeDays 天里回来照顾过自己。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.subInk,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _summaryLabel(items),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.subInk,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  const EbGlassCard(
                    child: Text('还没有新的记录，今天想从哪里开始都可以。'),
                  ),
                ...grouped.entries.map((MapEntry<String, List<RecordItem>> group) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            group.key,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.subInk,
                                ),
                          ),
                        ),
                        ...group.value.map((RecordItem item) {
                          final Color color = _colorFor(item.sourceType);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: EbGlassCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Column(
                                    children: <Widget>[
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.34),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(_iconFor(item.sourceType), color: AppColors.ink),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 48,
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        color: color.withValues(alpha: 0.28),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Text(
                                              _detailTimeLabel(item.createdAt),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppColors.subInk,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          item.subtitle,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.subInk,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
