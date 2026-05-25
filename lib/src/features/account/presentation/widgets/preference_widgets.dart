import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../lookups/domain/lookup_item.dart';

class PreferenceProgressHeader extends StatelessWidget {
  const PreferenceProgressHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.completedLabel,
    required this.onSavePressed,
    required this.isSaving,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String completedLabel;
  final VoidCallback onSavePressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).clamp(0, 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.15),
            scheme.secondary.withValues(alpha: 0.12),
            scheme.surface,
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: scheme.primary.withValues(alpha: 0.10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completedLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: isSaving ? null : onSavePressed,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(isSaving ? 'Saving...' : 'Update Preferences'),
          ),
        ],
      ),
    );
  }
}

class PreferenceExpandableSection extends StatefulWidget {
  const PreferenceExpandableSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completionLabel,
    required this.previewChips,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final String subtitle;
  final String completionLabel;
  final List<String> previewChips;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<PreferenceExpandableSection> createState() =>
      _PreferenceExpandableSectionState();
}

class _PreferenceExpandableSectionState extends State<PreferenceExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.completionLabel,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PreferencePreviewChips(chips: widget.previewChips),
                  const SizedBox(height: 12),
                  widget.child,
                ],
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class PreferenceSectionCard extends StatelessWidget {
  const PreferenceSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class PreferenceRangeTile extends StatelessWidget {
  const PreferenceRangeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.minValueLabel,
    required this.maxValueLabel,
    required this.range,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.leftSuffix,
    required this.rightSuffix,
  });

  final String title;
  final String subtitle;
  final String minValueLabel;
  final String maxValueLabel;
  final RangeValues range;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<RangeValues> onChanged;
  final String leftSuffix;
  final String rightSuffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surface.withValues(alpha: 0.72),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '$minValueLabel → $maxValueLabel',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RangeSlider(
            values: range,
            min: min,
            max: max,
            divisions: divisions,
            labels: RangeLabels(
              '$minValueLabel $leftSuffix',
              '$maxValueLabel $rightSuffix',
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class PreferenceChipSelector<T> extends StatefulWidget {
  const PreferenceChipSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.labelBuilder,
    this.multiple = true,
    this.compact = false,
  });

  final String label;
  final List<T> options;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onChanged;
  final String Function(T value)? labelBuilder;
  final bool multiple;
  final bool compact;

  @override
  State<PreferenceChipSelector<T>> createState() =>
      _PreferenceChipSelectorState<T>();
}

class _PreferenceChipSelectorState<T> extends State<PreferenceChipSelector<T>> {
  String _query = '';

  String _labelFor(T value) {
    return widget.labelBuilder?.call(value) ?? value.toString();
  }

  void _toggleItem(T option) {
    HapticFeedback.selectionClick();
    final isSelected = widget.selectedValues.contains(option);

    if (widget.multiple) {
      final next = List<T>.from(widget.selectedValues);
      if (isSelected) {
        next.remove(option);
      } else {
        next.add(option);
      }
      widget.onChanged(next);
      return;
    }

    widget.onChanged([option]);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options.where((option) {
      if (_query.isEmpty) return true;
      return _labelFor(option).toLowerCase().contains(_query);
    }).toList(growable: false);

    final scheme = Theme.of(context).colorScheme;
    final inputDecoration = InputDecoration(
      hintText: 'Search ${widget.label.toLowerCase()}...',
      prefixIcon: const Icon(Icons.search),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: inputDecoration,
          onChanged: (value) {
            setState(() => _query = value.trim().toLowerCase());
          },
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No ${widget.label.toLowerCase()} found',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: widget.compact ? 220 : 280,
            ),
            child: Scrollbar(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final option = filtered[index];
                  final isSelected = widget.selectedValues.contains(option);
                  return Material(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: CheckboxListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isSelected,
                      title: Text(_labelFor(option)),
                      onChanged: (_) => _toggleItem(option),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class PreferenceToggleCard extends StatelessWidget {
  const PreferenceToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing ??
                    Switch.adaptive(
                      value: value,
                      onChanged: (next) {
                        HapticFeedback.selectionClick();
                        onChanged(next);
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PreferencePreviewChips extends StatelessWidget {
  const PreferencePreviewChips({super.key, required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return Text(
        'Tap to configure this section',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .take(5)
          .map(
            (chip) => Chip(
              label: Text(chip),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}

Future<List<LookupItem>?> showLookupMultiSelectBottomSheet({
  required BuildContext context,
  required String title,
  required List<LookupItem> items,
  required List<LookupItem> selectedItems,
  List<String> previewChips = const [],
}) async {
  var query = '';
  final selected = selectedItems.map((item) => item.id).toSet();

  return showModalBottomSheet<List<LookupItem>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filtered = items.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query);
          }).toList(growable: false);
          final allFilteredSelected =
              filtered.isNotEmpty && filtered.every((item) => selected.contains(item.id));

          void toggleAllVisible() {
            HapticFeedback.selectionClick();
            setState(() {
              if (allFilteredSelected) {
                for (final item in filtered) {
                  selected.remove(item.id);
                }
              } else {
                for (final item in filtered) {
                  selected.add(item.id);
                }
              }
            });
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(
                            items
                                .where((item) => selected.contains(item.id))
                                .toList(growable: false),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (previewChips.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected so far',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PreferencePreviewChips(chips: previewChips),
                      const SizedBox(height: 12),
                    ],
                    if (selected.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PreferencePreviewChips(
                        chips: items
                            .where((item) => selected.contains(item.id))
                            .map((item) => item.name)
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() {
                        query = value.trim().toLowerCase();
                      }),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: filtered.isEmpty ? null : toggleAllVisible,
                        icon: Icon(
                          allFilteredSelected
                              ? Icons.clear_all_rounded
                              : Icons.select_all_rounded,
                        ),
                        label: Text(
                          allFilteredSelected ? 'Clear all' : 'Select all',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = selected.contains(item.id);
                          return Material(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: CheckboxListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              value: isSelected,
                              title: Text(item.name),
                              onChanged: (checked) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (checked ?? false) {
                                    selected.add(item.id);
                                  } else {
                                    selected.remove(item.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<List<String>?> showStringMultiSelectBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required List<String> selectedItems,
}) async {
  var query = '';
  final selected = selectedItems.toSet();

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filtered = options.where((item) {
            if (query.isEmpty) return true;
            return item.toLowerCase().contains(query);
          }).toList(growable: false);

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(
                            options.where(selected.contains).toList(growable: false),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() {
                        query = value.trim().toLowerCase();
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = selected.contains(item);
                          return Material(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: CheckboxListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              value: isSelected,
                              title: Text(item),
                              onChanged: (checked) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (checked ?? false) {
                                    selected.add(item);
                                  } else {
                                    selected.remove(item);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
