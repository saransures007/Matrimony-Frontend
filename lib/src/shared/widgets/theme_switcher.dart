import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// ✅ Theme Switcher Widget
/// Dropdown button to switch between Light / Dark / System theme modes
class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final loc = ref.watch(localizationsProvider);

    return DropdownButton<ThemeMode>(
      value: themeMode,
      underline: const SizedBox(),
      icon: Icon(
        Icons.arrow_drop_down,
        size: 18,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      dropdownColor: Theme.of(context).cardColor,
      onChanged: (ThemeMode? value) {
        if (value != null) {
          ref.read(themeModeProvider.notifier).state = value;
        }
      },
      items: [
        DropdownMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              const Icon(Icons.light_mode, size: 18),
              if (!compact) ...[const SizedBox(width: 8), Text(loc.lightMode)],
            ],
          ),
        ),
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              const Icon(Icons.dark_mode, size: 18),
              if (!compact) ...[const SizedBox(width: 8), Text(loc.darkMode)],
            ],
          ),
        ),
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              const Icon(Icons.settings_brightness, size: 18),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(loc.systemDefault),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
