import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.messages)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MessageTile(
            name: loc.supportVerification,
            text: loc.supportVerificationText,
          ),
          _MessageTile(name: loc.matchRequest, text: loc.matchRequestText),
          const SizedBox(height: 16),
          Text(
            loc.messagesReadyText,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
        title: Text(name),
        subtitle: Text(text),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
