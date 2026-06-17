import 'package:flutter/material.dart';

import '../domain/match_profile.dart';

class ProfileAiChatPage extends StatefulWidget {
  const ProfileAiChatPage({
    super.key,
    required this.profile,
    required this.sectionTitle,
    required this.scoreLabel,
    required this.prompt,
    required this.prompts,
  });

  final MatchProfile profile;
  final String sectionTitle;
  final String scoreLabel;
  final String prompt;
  final List<String> prompts;

  @override
  State<ProfileAiChatPage> createState() => _ProfileAiChatPageState();
}

class _ProfileAiChatPageState extends State<ProfileAiChatPage> {
  late final TextEditingController _controller;
  late final List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prompt);
    _messages = [
      _ChatMessage(
        isUser: false,
        text:
            'I can help you explore ${widget.profile.fullname} from different angles. Try one of the prompts below or ask a custom question.',
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendPrompt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: trimmed));
      _messages.add(
        _ChatMessage(
          isUser: false,
          text:
              'Based on the current profile details, that is a great question to dig into. I’d look at shared values, lifestyle fit, family expectations, and long-term compatibility signals.',
        ),
      );
      _controller.clear();
    });
  }

  void _applyPrompt(String text) {
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text('Ask AI about ${widget.profile.fullname}'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sectionTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.scoreLabel,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Suggested prompts',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.prompts
                          .map(
                            (prompt) => ActionChip(
                              label: Text(prompt),
                              onPressed: () => _applyPrompt(prompt),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? scheme.primary
                            : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: message.isUser
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendPrompt,
                      decoration: InputDecoration(
                        hintText: 'Ask about compatibility, red flags, or long-term fit',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => _sendPrompt(_controller.text),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
  });

  final bool isUser;
  final String text;
}
