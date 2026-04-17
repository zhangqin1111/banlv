import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/eb_glass_card.dart';
import '../../core/widgets/momo_orb.dart';
import '../../core/widgets/momo_quote_bubble.dart';
import '../../services/analytics_service.dart';
import '../../services/chat_stream_service.dart';

class TreeholePage extends StatefulWidget {
  const TreeholePage({super.key});

  @override
  State<TreeholePage> createState() => _TreeholePageState();
}

class _TreeholePageState extends State<TreeholePage> {
  static const List<_CompanionModeOption> _modes = <_CompanionModeOption>[
    _CompanionModeOption(
      id: 'listen',
      label: '听你说',
      shortHint: '先说，不用整理',
      composerHint: '想起哪一段，就先说哪一段',
      starterPrompts: <String>['我有点乱', '今天很委屈', '我想慢慢说'],
      greeting: '我先安静听你说，哪怕只是一小段也可以。',
      momoLines: <String>[
        '你先把最想说的那一句给我就好，我会慢慢接。',
        '如果一开始有点乱，也没关系，我会跟着你走。',
        '你说慢一点也可以，我会在这里陪着。',
      ],
      motion: MomoMotion.cuddle,
      expression: MomoExpression.softSmile,
      icon: Icons.favorite_border_rounded,
      color: AppColors.lavender,
    ),
    _CompanionModeOption(
      id: 'vent',
      label: '陪你骂一会',
      shortHint: '不急着劝，也不用体面',
      composerHint: '想吐槽、想抱怨、想骂两句都可以',
      starterPrompts: <String>['我现在很火大', '真的烦死了', '我想先吐槽'],
      greeting: '如果你现在只想吐槽、抱怨、骂两句，也可以，我不会急着打断你。',
      momoLines: <String>[
        '你可以先把那股火说出来，我先不急着劝你。',
        '如果这会儿只想吐槽几句，也完全可以。',
        '先把胸口那团闷的东西丢给我一点点也好。',
      ],
      motion: MomoMotion.hop,
      expression: MomoExpression.cheer,
      icon: Icons.local_fire_department_outlined,
      color: AppColors.gentleRed,
    ),
    _CompanionModeOption(
      id: 'organize',
      label: '帮你理一理',
      shortHint: '把乱的地方拆开一点',
      composerHint: '告诉我最卡住你的那一块就够了',
      starterPrompts: <String>['我不知道先处理哪个', '事情堆在一起了', '帮我理一下'],
      greeting: '如果你想把事情理清一点，我们先只抓最乱的那一团。',
      momoLines: <String>[
        '我们不用一下子理完，我先陪你挑出最卡的一块。',
        '把最乱的那团递给我，我们一起松一松。',
        '如果你愿意，我可以陪你把事情拆小一点。',
      ],
      motion: MomoMotion.swim,
      expression: MomoExpression.curious,
      icon: Icons.route_rounded,
      color: AppColors.mistBlue,
    ),
    _CompanionModeOption(
      id: 'quiet',
      label: '先不说也可以',
      shortHint: '几个字也算，沉默也算',
      composerHint: '哪怕只写“乱”“烦”“累”，我也会接住',
      starterPrompts: <String>['乱', '烦', '累'],
      greeting: '哪怕只留几个字，或者一句“我现在不想多说”，也可以。',
      momoLines: <String>[
        '今天就算只留几个字，我也会在这里陪你。',
        '如果你现在只想安静待一会，也完全可以。',
        '你先靠过来一点点就好，不想多说也没关系。',
      ],
      motion: MomoMotion.swim,
      expression: MomoExpression.sleepy,
      icon: Icons.nightlight_round_rounded,
      color: AppColors.calmGreen,
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatStreamService _chatStreamService = ChatStreamService();

  List<ChatMessage> _messages = <ChatMessage>[];
  bool _isStreaming = false;
  bool _isSubmittingFeedback = false;
  String? _sessionId;
  String? _suggestedMode;
  int? _selectedHelpfulScore;
  int _assistantReplyCount = 0;
  bool _feedbackPromptVisible = false;
  bool _feedbackDismissed = false;
  int _modeLineIndex = 0;
  _CompanionModeOption _selectedMode = _modes.first;

  bool get _showSuggestionCard =>
      !_isStreaming &&
      _suggestedMode != null &&
      _messages.any((ChatMessage message) => message.role == 'assistant');

  String get _momoLine {
    if (_isStreaming) {
      return '我正在这里，一小句一小句接住你。';
    }
    if (_feedbackPromptVisible || _selectedHelpfulScore != null) {
      return '谢谢你告诉我刚刚那一下的感觉，我会记住这次陪伴。';
    }
    return _selectedMode.momoLines[_modeLineIndex % _selectedMode.momoLines.length];
  }

  MomoMotion get _momoMotion => _isStreaming ? MomoMotion.swim : _selectedMode.motion;

  MomoExpression get _momoExpression {
    if (_isStreaming) {
      return MomoExpression.curious;
    }
    if (_selectedHelpfulScore != null) {
      return MomoExpression.happy;
    }
    return _selectedMode.expression;
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('treehole_start');
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectMode(_CompanionModeOption option) {
    if (_selectedMode.id == option.id) {
      return;
    }
    AnalyticsService.instance.logEvent(
      'treehole_mode_selected',
      payload: <String, Object?>{'companion_mode': option.id},
    );
    setState(() {
      _selectedMode = option;
      _modeLineIndex = 0;
    });
  }

  void _cycleMomoLine() {
    setState(() {
      _modeLineIndex = (_modeLineIndex + 1) % _selectedMode.momoLines.length;
    });
  }

  void _applyStarterPrompt(String text) {
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) {
      return;
    }
    final GoRouter router = GoRouter.of(context);

    AnalyticsService.instance.logEvent(
      'treehole_send',
      payload: <String, Object?>{
        'message_length': text.length,
        'companion_mode': _selectedMode.id,
      },
    );

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _controller.clear();
      _isStreaming = true;
      _suggestedMode = null;
      _feedbackPromptVisible = false;
    });
    _scrollToBottomSoon();

    _sessionId ??= await _chatStreamService.createSession(opener: text);
    final StringBuffer buffer = StringBuffer();
    bool shouldOpenSafety = false;

    setState(() {
      _messages.add(const ChatMessage(role: 'assistant', text: ''));
    });
    _scrollToBottomSoon();

    await for (final TreeholeStreamEvent event in _chatStreamService.streamReply(
      sessionId: _sessionId!,
      message: text,
      companionMode: _selectedMode.id,
    )) {
      if (!mounted) {
        return;
      }

      if (event.type == 'message_delta') {
        buffer.write(event.payload['delta'] as String? ?? '');
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: 'assistant',
            text: buffer.toString(),
          );
        });
        _scrollToBottomSoon();
        continue;
      }

      if (event.type == 'message_done') {
        _assistantReplyCount += 1;
        AnalyticsService.instance.logEvent(
          'treehole_completion',
          payload: <String, Object?>{
            'session_id': _sessionId,
            'suggestion': event.payload['suggestion'] as String? ?? 'none',
            'companion_mode': _selectedMode.id,
          },
        );
        setState(() {
          _suggestedMode = event.payload['suggestion'] as String?;
          if (_assistantReplyCount >= 3 &&
              _selectedHelpfulScore == null &&
              !_feedbackDismissed) {
            _feedbackPromptVisible = true;
          }
        });
        continue;
      }

      if (event.type == 'safety_block') {
        shouldOpenSafety = true;
        AnalyticsService.instance.logEvent(
          'safety_block',
          payload: <String, Object?>{
            'source': 'treehole',
            'session_id': _sessionId,
            'reason': event.payload['reason'] as String? ?? 'high_risk',
          },
        );
        setState(() {
          _messages[_messages.length - 1] = const ChatMessage(
            role: 'assistant',
            text: '我有认真看见你刚才说的话。现在更重要的是先联系现实中的支持资源。',
          );
        });
        continue;
      }

      if (event.type == 'error' && buffer.isEmpty) {
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: 'assistant',
            text: event.payload['message'] as String? ?? '现在这段连接有点不稳，我们先慢一点。',
          );
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (_sessionId != null) {
      final List<ChatMessage> latest =
          await _chatStreamService.fetchMessages(sessionId: _sessionId!);
      if (latest.isNotEmpty && mounted) {
        setState(() {
          _messages = latest;
        });
      }
    }

    setState(() {
      _isStreaming = false;
    });
    _scrollToBottomSoon();

    if (shouldOpenSafety) {
      router.push('/safety');
    }
  }

  Future<void> _submitHelpfulScore(int score) async {
    if (_sessionId == null || _isSubmittingFeedback) {
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
      _selectedHelpfulScore = score;
      _feedbackPromptVisible = false;
    });
    await _chatStreamService.submitFeedback(
      sessionId: _sessionId!,
      helpfulScore: score,
    );
    AnalyticsService.instance.logEvent(
      'helpfulness_feedback',
      payload: <String, Object?>{
        'session_id': _sessionId,
        'helpful_score': score,
        'companion_mode': _selectedMode.id,
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmittingFeedback = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('谢谢你告诉我这次的感受。')),
    );
  }

  void _dismissFeedbackCard() {
    AnalyticsService.instance.logEvent(
      'helpfulness_feedback_dismissed',
      payload: <String, Object?>{'session_id': _sessionId},
    );
    setState(() {
      _feedbackDismissed = true;
      _feedbackPromptVisible = false;
    });
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 48,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('解忧树洞'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: EbGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '今天想让我怎么陪你？',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedMode.shortHint,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.subInk,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      MomoOrb(
                        size: 68,
                        glowColor: _selectedMode.color,
                        motion: _momoMotion,
                        expression: _momoExpression,
                        onTap: _cycleMomoLine,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: MomoQuoteBubble(
                      key: ValueKey<String>(_momoLine),
                      text: _momoLine,
                      label: 'momo',
                      tint: _selectedMode.color,
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _modes.map((_CompanionModeOption option) {
                      final bool selected = option.id == _selectedMode.id;
                      return ChoiceChip(
                        selected: selected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(option.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(option.label),
                          ],
                        ),
                        onSelected: (_) => _selectMode(option),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _selectedMode.starterPrompts.map((String text) {
                      return ActionChip(
                        label: Text(text),
                        onPressed: () => _applyStarterPrompt(text),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                final ChatMessage message = _messages[index];
                final bool isUser = message.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.mistBlue.withValues(alpha: 0.62)
                          : Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _FeedbackCard(
              visible: _feedbackPromptVisible &&
                  !_isStreaming &&
                  !_isSubmittingFeedback &&
                  _sessionId != null &&
                  _selectedHelpfulScore == null,
              selectedScore: _selectedHelpfulScore,
              isSubmitting: _isSubmittingFeedback,
              onSelect: _submitHelpfulScore,
              onDismiss: _dismissFeedbackCard,
            ),
          ),
          if (_showSuggestionCard) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _SuggestionCard(suggestedMode: _suggestedMode),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: _selectedMode.composerHint),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: _send,
                  icon: _isStreaming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.visible,
    required this.selectedScore,
    required this.isSubmitting,
    required this.onSelect,
    required this.onDismiss,
  });

  final bool visible;
  final int? selectedScore;
  final bool isSubmitting;
  final ValueChanged<int> onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return EbGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '这次有稍微帮到你吗？',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: isSubmitting ? null : onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: '先收起',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _HelpfulChip(
                label: '有一点',
                selected: selectedScore == 2,
                enabled: !isSubmitting,
                onTap: () => onSelect(2),
              ),
              _HelpfulChip(
                label: '一般',
                selected: selectedScore == 1,
                enabled: !isSubmitting,
                onTap: () => onSelect(1),
              ),
              _HelpfulChip(
                label: '还没太帮助',
                selected: selectedScore == 0,
                enabled: !isSubmitting,
                onTap: () => onSelect(0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpfulChip extends StatelessWidget {
  const _HelpfulChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestedMode});

  final String? suggestedMode;

  @override
  Widget build(BuildContext context) {
    String route = '/mode/low';
    String text = '如果你想换一种方式，我们也可以试试一个更轻的情绪小场景。';

    if (suggestedMode == 'anger_mode') {
      route = '/mode/anger';
      text = '如果你想先把这一阵绷紧散开一点，我们可以试试气泡释放。';
    } else if (suggestedMode == 'joy_mode') {
      route = '/mode/joy';
      text = '如果你想把这点轻亮再留一会，我们可以去光粒漂流。';
    } else if (suggestedMode == 'low_mode') {
      route = '/mode/low';
      text = '如果你想先缓一缓，我们可以去一个更安静的小场景。';
    }

    return EbGlassCard(
      child: InkWell(
        onTap: () {
          AnalyticsService.instance.logEvent(
            'module_open',
            payload: <String, Object?>{
              'module': route.replaceFirst('/', ''),
              'source': 'treehole_suggestion',
            },
          );
          context.push(route);
        },
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Row(
          children: <Widget>[
            const Icon(Icons.air_rounded, color: AppColors.subInk),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subInk,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.subInk),
          ],
        ),
      ),
    );
  }
}

class _CompanionModeOption {
  const _CompanionModeOption({
    required this.id,
    required this.label,
    required this.shortHint,
    required this.composerHint,
    required this.starterPrompts,
    required this.greeting,
    required this.momoLines,
    required this.motion,
    required this.expression,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final String shortHint;
  final String composerHint;
  final List<String> starterPrompts;
  final String greeting;
  final List<String> momoLines;
  final MomoMotion motion;
  final MomoExpression expression;
  final IconData icon;
  final Color color;
}
