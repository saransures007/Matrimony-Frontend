import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

/// 🌍 Language Switcher Widget
/// Dropdown button to switch between supported languages
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.compact = false, this.isDark = false});

  final bool compact;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Material(
      color: Colors.transparent,
      child: DropdownButton<AppLocale>(
        value: currentLocale,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, size: 18, color: isDark ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white : null),
        dropdownColor: Theme.of(context).cardColor,
        onChanged: (AppLocale? value) {
          if (value != null) {
            ref.read(localeProvider.notifier).state = value;
          }
        },
        items: AppLocale.values.map((locale) {
          return DropdownMenuItem(
            value: locale,
            child: Row(
              children: [
                Icon(Icons.language, size: 18),
                const SizedBox(width: 8),
                Text(locale.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
