import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/eb_primary_button.dart';
import '../../core/widgets/momo_orb.dart';
import '../../services/analytics_service.dart';
import '../../services/blind_box_api_service.dart';

class BlindBoxPage extends StatefulWidget {
  const BlindBoxPage({super.key});

  @override
  State<BlindBoxPage> createState() => _BlindBoxPageState();
}

class _BlindBoxPageState extends State<BlindBoxPage> {
  static const List<String> _starterPrompts = <String>[
    '今天脑子很吵。',
    '我有点累，也有点撑。',
    '明明没出大事，但就是闷着。',
  ];

  final TextEditingController _controller = TextEditingController();
  final BlindBoxApiService _service = BlindBoxApiService();

  BlindBoxCardModel? _selectedCard;
  bool _isLoading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('blind_box_open');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPrompt(String prompt) {
    setState(() {
      _controller.text = prompt;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  Future<void> _drawCard() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    final BlindBoxCardModel card = await _service.drawCard(
      worryText: _controller.text.trim(),
    );
    AnalyticsService.instance.logEvent(
      'blind_box_draw',
      payload: <String, Object?>{
        'card_type': card.cardType,
        'has_worry_text': _controller.text.trim().isNotEmpty,
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCard = card;
      _isSaved = false;
      _isLoading = false;
    });
  }

  Future<void> _saveCard() async {
    final BlindBoxCardModel? card = _selectedCard;
    if (card == null || _isSaved) {
      return;
    }
    final BlindBoxSaveResult result = await _service.saveCard(card.drawId);
    AnalyticsService.instance.logEvent(
      'blind_box_save',
      payload: <String, Object?>{
        'card_type': card.cardType,
        'is_saved': result.isSaved,
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaved = result.isSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSaved ? '这张卡已经替你收好了。' : '这次没有保存成功。'),
      ),
    );
  }

  IconData _cardIcon(String type) {
    switch (type) {
      case 'action':
        return Icons.directions_walk_rounded;
      case 'reframe':
        return Icons.wb_twilight_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  Color _cardColor(String type) {
    switch (type) {
      case 'action':
        return AppColors.sun;
      case 'reframe':
        return AppColors.lavender;
      default:
        return AppColors.peachGlow;
    }
  }

  String _cardTypeLabel(String type) {
    switch (type) {
      case 'action':
        return '轻动作';
      case 'reframe':
        return '换个角度';
      default:
        return '抱抱你';
    }
  }

  @override
  Widget build(BuildContext context) {
    final BlindBoxCardModel? card = _selectedCard;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('今日盲盒')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.skyBackground,
              Color(0xFFF7F2FF),
              AppColors.softCream,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            EbGlassCard(
              padding: EdgeInsets.zero,
              child: Container(
                height: 196,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.lavender.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.92),
                      AppColors.peachGlow.withValues(alpha: 0.28),
                    ],
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 20,
                      top: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'momo 的今日卡片',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 28,
                      top: 86,
                      child: _BlindBoxStar(size: 14),
                    ),
                    const Positioned(
                      right: 34,
                      top: 62,
                      child: _BlindBoxStar(size: 18),
                    ),
                    const Positioned(
                      right: 66,
                      top: 138,
                      child: _BlindBoxStar(size: 10),
                    ),
                    Positioned(
                      left: 24,
                      top: 70,
                      right: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '想掉下一句适合今天的话吗？',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '写一句现在的你，或者什么都不写。\n它只会轻轻掉下一张卡陪你。',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.subInk,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      right: 18,
                      bottom: 14,
                      child: MomoOrb(size: 104, glowColor: AppColors.peachGlow),
                    ),
                    Positioned(
                      right: 20,
                      top: 72,
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '不用想太完整。\n几句话就够了。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.subInk,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EbGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.peachGlow.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.edit_note_rounded, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '写一句现在的你',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '不写也可以，只是会更像今天一点。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.subInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _controller,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '比如：我其实没有那么糟，只是今天真的有点累。',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _starterPrompts.map((String prompt) {
                      return _BlindPromptChip(
                        label: prompt,
                        onTap: () => _applyPrompt(prompt),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EbPrimaryButton(
              label: _isLoading ? 'momo 正在打开今天的卡...' : '打开一张卡',
              icon: Icons.redeem_rounded,
              onPressed: _isLoading ? null : _drawCard,
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: card == null
                  ? const _BlindBoxEmptyState()
                  : _BlindBoxCardView(
                      key: ValueKey<String>(card.drawId),
                      card: card,
                      isSaved: _isSaved,
                      cardColor: _cardColor(card.cardType),
                      cardLabel: _cardTypeLabel(card.cardType),
                      cardIcon: _cardIcon(card.cardType),
                      onSave: _saveCard,
                      onRedraw: _isLoading ? null : _drawCard,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlindBoxEmptyState extends StatelessWidget {
  const _BlindBoxEmptyState();

  @override
  Widget build(BuildContext context) {
    return EbGlassCard(
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.peachGlow.withValues(alpha: 0.52),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, size: 40),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '一张卡还没落下来',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '准备好时，momo 会替今天轻轻掉下一句。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.subInk,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlindPromptChip extends StatelessWidget {
  const _BlindPromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.72),
            border: Border.all(
              color: AppColors.mistBlue.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _BlindBoxCardView extends StatelessWidget {
  const _BlindBoxCardView({
    super.key,
    required this.card,
    required this.isSaved,
    required this.cardColor,
    required this.cardLabel,
    required this.cardIcon,
    required this.onSave,
    required this.onRedraw,
  });

  final BlindBoxCardModel card;
  final bool isSaved;
  final Color cardColor;
  final String cardLabel;
  final IconData cardIcon;
  final VoidCallback onSave;
  final VoidCallback? onRedraw;

  @override
  Widget build(BuildContext context) {
    return EbGlassCard(
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  cardColor.withValues(alpha: 0.52),
                  Colors.white.withValues(alpha: 0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cardLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cardIcon, color: AppColors.ink, size: 34),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  card.cardTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  card.cardBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '如果这一句刚好落在你心上，可以把它收进今天。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.subInk,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: isSaved ? null : onSave,
            icon: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined),
            label: Text(isSaved ? '已经收好了' : '收下这张卡'),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: onRedraw,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isSaved ? '想换一张也可以' : '先不收，换一张看看'),
          ),
        ],
      ),
    );
  }
}

class _BlindBoxStar extends StatelessWidget {
  const _BlindBoxStar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.peachGlow.withValues(alpha: 0.48),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
