import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/presentation/discover_controller.dart';
import '../../home/application/home_navigation_controller.dart';
import '../../lookups/data/static_data_repository.dart';
import '../../lookups/domain/lookup_item.dart';
import '../../lookups/domain/static_data.dart';
import '../data/profile_preferences_repository.dart';
import 'widgets/preference_widgets.dart'
    show
        PreferenceToggleCard,
        showLookupMultiSelectBottomSheet,
        showStringMultiSelectBottomSheet;

const _pageBackground = Colors.white;
const _headerTint = Color(0xFFFCE7EA);
const _cardBorder = Color(0xFFEDE6F5);
const _selectedChipBorder = Color(0xFFFF7B8B);
const _selectedChipFill = Color(0xFFFBE3E7);
const _accent = Color(0xFFD94D67);

class ProfilePreferencesPage extends ConsumerStatefulWidget {
  const ProfilePreferencesPage({super.key});

  @override
  ConsumerState<ProfilePreferencesPage> createState() =>
      _ProfilePreferencesPageState();
}

class _ProfilePreferencesPageState
    extends ConsumerState<ProfilePreferencesPage> {
  ProfilePreferencesView _draft = const ProfilePreferencesView();
  bool _hydrated = false;
  bool _saving = false;
  bool _horoscopeEnabled = false;
  Timer? _autoSaveTimer;
  RangeValues _ageRange = const RangeValues(24, 32);
  final Set<String> _expandedSections = <String>{
    'Basic Details',
    'Education & Occupation',
    'Religion and Ethnicity',
    'Lifestyle',
  };

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _hydrate(ProfilePreferencesView? preferences) {
    if (_hydrated) return;
    _hydrated = true;
    _draft = preferences ?? const ProfilePreferencesView();
    _ageRange = RangeValues(
      (_draft.minAge ?? 24).toDouble(),
      (_draft.maxAge ?? 32).toDouble(),
    );
    _horoscopeEnabled = _draft.requireHoroscopeMatch;
  }

  void _updateDraft(ProfilePreferencesView next, {bool queueAutoSave = true}) {
    setState(() => _draft = next);
    if (queueAutoSave) {
      _queueAutoSave();
    }
  }

  void _updateAgeRange(RangeValues range) {
    final normalized = RangeValues(
      range.start.clamp(18.0, 100.0),
      range.end.clamp(18.0, 100.0),
    );
    setState(() {
      _ageRange = normalized;
      _draft = _draft.copyWith(
        minAge: normalized.start.round(),
        maxAge: normalized.end.round(),
      );
    });
    _queueAutoSave();
  }

  void _toggleSection(String key) {
    setState(() {
      if (_expandedSections.contains(key)) {
        _expandedSections.remove(key);
      } else {
        _expandedSections.add(key);
      }
    });
  }

  void _queueAutoSave() {
    if (!_hydrated) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _saving) return;
      _save(silent: true);
    });
  }

  List<String> _previewNames(List<LookupItem> items, List<int> ids) {
    final map = {for (final item in items) item.id: item.name};
    return ids.map((id) => map[id]).whereType<String>().toList(growable: false);
  }

  List<String> _prefixedPreview(String label, Iterable<LookupItem> items) {
    return items.map((item) => '$label: ${item.name}').toList(growable: false);
  }

  List<LookupItem> _selectedLookupItems(List<LookupItem> items, List<int> ids) {
    final selectedIds = ids.toSet();
    return items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);
  }

  List<LookupItem> _statesForCountries(
    List<LookupItem> states,
    List<int> countryIds,
  ) {
    if (countryIds.isEmpty) return const [];
    return states
        .where((state) => countryIds.contains(state.countryCode))
        .toList(growable: false);
  }

  List<LookupItem> _citiesForLocation(
    List<LookupItem> cities,
    List<LookupItem> states,
    List<int> countryIds,
    List<int> stateIds,
  ) {
    if (countryIds.isEmpty) return const [];

    final allowedStateIds = _statesForCountries(
      states,
      countryIds,
    ).map((state) => state.id).toSet();
    final selectedStateIds = stateIds.where(allowedStateIds.contains).toSet();

    return cities
        .where((city) {
          final cityStateId = city.stateId ?? city.parentId;
          if (selectedStateIds.isNotEmpty) {
            return cityStateId != null &&
                selectedStateIds.contains(cityStateId);
          }

          if (cityStateId != null) {
            return allowedStateIds.contains(cityStateId);
          }

          final cityCountryCode = city.countryCode;
          return cityCountryCode != null &&
              countryIds.contains(cityCountryCode);
        })
        .toList(growable: false);
  }

  String _displayCount(List<String> values, String fallback) {
    if (values.isEmpty) return fallback;
    if (values.length == 1) return values.first;
    return '${values.first} +${values.length - 1} More';
  }

  String _rangeFromLookup(
    List<LookupItem> items,
    int? minId,
    int? maxId, {
    String separator = ' to ',
    String fallback = 'Not set',
  }) {
    if (items.isEmpty) return fallback;
    final minIndex = minId == null
        ? 0
        : items
              .indexWhere((item) => item.id == minId)
              .clamp(0, items.length - 1);
    final maxIndex = maxId == null
        ? items.length - 1
        : items
              .indexWhere((item) => item.id == maxId)
              .clamp(0, items.length - 1);
    if (minIndex < 0 || maxIndex < 0) return fallback;
    return '${items[minIndex].name}$separator${items[maxIndex].name}';
  }

  String _locationPreview(StaticData lookups) {
    final countries = _previewNames(
      lookups.countries,
      _draft.preferredCountryIds,
    );
    final states = _previewNames(
      _statesForCountries(lookups.states, _draft.preferredCountryIds),
      _draft.preferredStateIds,
    );
    final cities = _previewNames(
      _citiesForLocation(
        lookups.cities,
        lookups.states,
        _draft.preferredCountryIds,
        _draft.preferredStateIds,
      ),
      _draft.preferredCityIds,
    );

    final values = <String>[...countries, ...states, ...cities];

    if (values.isEmpty) return 'Not set';
    return values.join(', ');
  }

  String _summaryChipText(StaticData lookups, String type) {
    switch (type) {
      case 'Age':
        return '${_ageRange.start.round()}-${_ageRange.end.round()} Years';
      case 'Height':
        return _rangeFromLookup(
          lookups.heights,
          _draft.minHeightId,
          _draft.maxHeightId,
        );
      case 'Location':
        return _locationPreview(lookups);
      case 'Marital':
        return _displayCount(_draft.preferredMaritalStatusIds, 'Not set');
      case 'Education':
        return _displayCount(
          _previewNames(lookups.education, _draft.preferredEducationIds),
          'Not set',
        );
      case 'Occupation':
        return _displayCount(
          _previewNames(lookups.occupation, _draft.preferredOccupationIds),
          'Not set',
        );
      default:
        return 'Not set';
    }
  }

  bool _showChildrenPreferenceOptions() {
    final statuses = _draft.preferredMaritalStatusIds;
    return !(statuses.length == 1 && statuses.contains('Single'));
  }

  Future<void> _save({
    bool silent = false,
    bool navigateToPeople = false,
  }) async {
    if (_saving) return;

    final updated = _draft.copyWith(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      requireHoroscopeMatch: _horoscopeEnabled,
    );

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(profilePreferencesRepositoryProvider)
          .saveMyPreferences(updated);
      _draft = saved;
      ref.invalidate(myPreferencesProvider);

      if (navigateToPeople) {
        ref.read(discoverFiltersProvider.notifier).applyPreferences(saved);
        ref.read(homeTabIndexProvider.notifier).state = 2;
      }

      if (!mounted) return;

      if (navigateToPeople) {
        Navigator.of(context).pop();
        return;
      }

      if (!silent) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Preferences updated')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLookupMultiSelect({
    required String title,
    required List<LookupItem> items,
    required List<int> selectedIds,
    required ValueChanged<List<int>> onChanged,
  }) async {
    final selectedItems = items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);
    final picked = await showLookupMultiSelectBottomSheet(
      context: context,
      title: title,
      items: items,
      selectedItems: selectedItems,
    );
    if (picked == null) return;
    onChanged(picked.map((item) => item.id).toList(growable: false));
    _queueAutoSave();
  }

  Future<void> _pickStringMultiSelect({
    required String title,
    required List<String> items,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final picked = await showStringMultiSelectBottomSheet(
      context: context,
      title: title,
      options: items,
      selectedItems: selectedValues,
    );
    if (picked == null) return;
    onChanged(picked);
    _queueAutoSave();
  }

  Future<RangeValues?> _pickRange({
    required String sectionLabel,
    required String title,
    required String subtitle,
    required RangeValues initialRange,
    required double min,
    required double max,
    required int divisions,
    required String Function(RangeValues range) rangeLabel,
    required String saveLabel,
  }) {
    return showModalBottomSheet<RangeValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var currentRange = initialRange;

        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: EdgeInsets.fromLTRB(
                  18,
                  14,
                  18,
                  18 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sectionLabel.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rangeLabel(currentRange),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RangeSlider(
                      values: currentRange,
                      min: min,
                      max: max,
                      divisions: divisions,
                      labels: RangeLabels(
                        currentRange.start.round().toString(),
                        currentRange.end.round().toString(),
                      ),
                      onChanged: (value) {
                        setState(() => currentRange = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(currentRange),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          saveLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editAgeRange() async {
    final picked = await _pickRange(
      sectionLabel: 'Basic Details',
      title: 'Age Range',
      subtitle: 'Find matches in the right age bracket',
      initialRange: _ageRange,
      min: 18,
      max: 100,
      divisions: 82,
      rangeLabel: (range) =>
          '${range.start.round()} Years to ${range.end.round()} Years',
      saveLabel: 'Okay',
    );
    if (picked == null) return;
    _updateAgeRange(picked);
  }

  Future<void> _editHeightRange(List<LookupItem> heights) async {
    if (heights.isEmpty) return;
    final startIndex = _draft.minHeightId == null
        ? 0
        : heights
              .indexWhere((item) => item.id == _draft.minHeightId)
              .clamp(0, heights.length - 1);
    final endIndex = _draft.maxHeightId == null
        ? heights.length - 1
        : heights
              .indexWhere((item) => item.id == _draft.maxHeightId)
              .clamp(0, heights.length - 1);

    final picked = await _pickRange(
      sectionLabel: 'Basic Details',
      title: 'Height Range',
      subtitle: 'Selected height range',
      initialRange: RangeValues(startIndex.toDouble(), endIndex.toDouble()),
      min: 0,
      max: (heights.length - 1).toDouble(),
      divisions: heights.length > 1 ? heights.length - 1 : 1,
      rangeLabel: (range) {
        final minIndex = range.start.round().clamp(0, heights.length - 1);
        final maxIndex = range.end.round().clamp(0, heights.length - 1);
        return '${heights[minIndex].name} to ${heights[maxIndex].name}';
      },
      saveLabel: 'Save',
    );
    if (picked == null) return;
    final minIndex = picked.start.round().clamp(0, heights.length - 1);
    final maxIndex = picked.end.round().clamp(0, heights.length - 1);
    _updateDraft(
      _draft.copyWith(
        minHeightId: heights[minIndex].id,
        maxHeightId: heights[maxIndex].id,
      ),
    );
  }

  Future<void> _editIncomeRange(List<LookupItem> incomes) async {
    if (incomes.isEmpty) return;
    final startIndex = _draft.minSalaryId == null
        ? 0
        : incomes
              .indexWhere((item) => item.id == _draft.minSalaryId)
              .clamp(0, incomes.length - 1);
    final endIndex = _draft.maxSalaryId == null
        ? incomes.length - 1
        : incomes
              .indexWhere((item) => item.id == _draft.maxSalaryId)
              .clamp(0, incomes.length - 1);

    final picked = await _pickRange(
      sectionLabel: 'Education & Occupation',
      title: 'Annual Income range',
      subtitle: 'Choose a salary band that feels right',
      initialRange: RangeValues(startIndex.toDouble(), endIndex.toDouble()),
      min: 0,
      max: (incomes.length - 1).toDouble(),
      divisions: incomes.length > 1 ? incomes.length - 1 : 1,
      rangeLabel: (range) {
        final minIndex = range.start.round().clamp(0, incomes.length - 1);
        final maxIndex = range.end.round().clamp(0, incomes.length - 1);
        return '${incomes[minIndex].name} to ${incomes[maxIndex].name}';
      },
      saveLabel: 'Save',
    );
    if (picked == null) return;
    final minIndex = picked.start.round().clamp(0, incomes.length - 1);
    final maxIndex = picked.end.round().clamp(0, incomes.length - 1);
    _updateDraft(
      _draft.copyWith(
        minSalaryId: incomes[minIndex].id,
        maxSalaryId: incomes[maxIndex].id,
      ),
    );
  }

  Future<void> _editLocation(StaticData lookups) async {
    final pickedCountries = await showLookupMultiSelectBottomSheet(
      context: context,
      title: 'Preferred Match Country',
      items: lookups.countries,
      selectedItems: _selectedLookupItems(
        lookups.countries,
        _draft.preferredCountryIds,
      ),
    );
    if (pickedCountries == null) return;
    if (!mounted) return;

    final countryIds = pickedCountries.map((item) => item.id).toList(growable: false);
    final filteredStates = _statesForCountries(lookups.states, countryIds);
    final pickedStates = filteredStates.isEmpty
        ? <LookupItem>[]
        : await showLookupMultiSelectBottomSheet(
            context: context,
            title: 'Preferred Match State',
            items: filteredStates,
            selectedItems: _selectedLookupItems(
              filteredStates,
              _draft.preferredStateIds,
            ),
            previewChips: _prefixedPreview('Country', pickedCountries),
          );
    if (pickedStates == null) return;
    if (!mounted) return;

    final stateIds = pickedStates.map((item) => item.id).toList(growable: false);
    final filteredDistricts = _citiesForLocation(
      lookups.cities,
      lookups.states,
      countryIds,
      stateIds,
    );
    final pickedDistricts = filteredDistricts.isEmpty
        ? <LookupItem>[]
        : await showLookupMultiSelectBottomSheet(
            context: context,
            title: 'Preferred Match District',
            items: filteredDistricts,
            selectedItems: _selectedLookupItems(
              filteredDistricts,
              _draft.preferredCityIds,
            ),
            previewChips: <String>[
              ..._prefixedPreview('Country', pickedCountries),
              ..._prefixedPreview('State', pickedStates),
            ],
          );
    if (pickedDistricts == null) return;

    _updateDraft(
      _draft.copyWith(
        preferredCountryIds: countryIds,
        preferredStateIds: stateIds,
        preferredCityIds: pickedDistricts.map((item) => item.id).toList(growable: false),
      ),
      queueAutoSave: false,
    );
    _queueAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final lookupsAsync = ref.watch(staticDataProvider);
    final preferencesAsync = ref.watch(myPreferencesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _saving
              ? null
              : () => _save(silent: false, navigateToPeople: true),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'Search',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: lookupsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => _ErrorView(message: error.toString()),
        data: (lookups) => preferencesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (error, _) => _ErrorView(message: error.toString()),
          data: (preferences) {
            _hydrate(preferences);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    snap: false,
                    expandedHeight: 190,
                    collapsedHeight: 56,
                    toolbarHeight: 56,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    foregroundColor: scheme.onSurface,
                    titleSpacing: 0,
                    leadingWidth: 48,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Center(
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(20),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.arrow_back_rounded, size: 18),
                          ),
                        ),
                      ),
                    ),
                    title: const Text(
                      'Tell us',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_headerTint, Colors.white],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),
                                Text(
                                  'Tell us what you’re\nlooking for',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontSize: 24,
                                        height: 1.0,
                                        letterSpacing: -0.8,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Make your search more specific',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    height: 1.2,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SummaryChip(
                          label: 'Current Preferences',
                          selected: true,
                          minWidth: 120,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: _summaryChipText(lookups, 'Age'),
                          selected: false,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: _summaryChipText(lookups, 'Location'),
                          selected: false,
                          minWidth: 160,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: _summaryChipText(lookups, 'Education'),
                          selected: false,
                          minWidth: 138,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: _summaryChipText(lookups, 'Occupation'),
                          selected: false,
                          minWidth: 138,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExpandablePreferenceCard(
                    title: 'Basic Details',
                    expanded: _expandedSections.contains('Basic Details'),
                    onToggle: () => _toggleSection('Basic Details'),
                    children: [
                      _PreferenceRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Age range',
                        value:
                            '${_ageRange.start.round()}-${_ageRange.end.round()} Years',
                        onTap: _editAgeRange,
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.straighten_rounded,
                        title: 'Height range',
                        value: _rangeFromLookup(
                          lookups.heights,
                          _draft.minHeightId,
                          _draft.maxHeightId,
                        ),
                        onTap: () => _editHeightRange(lookups.heights),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.place_outlined,
                        title: 'Preferred Match Location',
                        value: _locationPreview(lookups),
                        onTap: () => _editLocation(lookups),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.favorite_border_rounded,
                        title: 'Marital Status',
                        value: _displayCount(
                          _draft.preferredMaritalStatusIds,
                          'Not set',
                        ),
                        onTap: () => _pickStringMultiSelect(
                          title: 'Marital status',
                          items: const [
                            'Single',
                            'Divorced',
                            'Separated',
                            'Widowed',
                          ],
                          selectedValues: _draft.preferredMaritalStatusIds,
                          onChanged: (value) {
                            final next = value.length == 1 &&
                                    value.contains('Single')
                                ? _draft.copyWith(
                                    preferredMaritalStatusIds: value,
                                    acceptPartnerWithChildren: false,
                                    preferNoChildren: false,
                                  )
                                : _draft.copyWith(
                                    preferredMaritalStatusIds: value,
                                  );
                            _updateDraft(next, queueAutoSave: false);
                          },
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.badge_outlined,
                        title: 'Profile Managed By',
                        value: _displayCount(
                          _draft.preferredProfilePostedByIds,
                          'Not set',
                        ),
                        onTap: () => _pickStringMultiSelect(
                          title: 'Profile managed by',
                          items: const [
                            'Self',
                            'Parent',
                            'Sibling',
                            'Relative',
                            'Guardian',
                            'Friend',
                            'Other',
                          ],
                          selectedValues: _draft.preferredProfilePostedByIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredProfilePostedByIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ExpandablePreferenceCard(
                    title: 'Education & Occupation',
                    expanded: _expandedSections.contains(
                      'Education & Occupation',
                    ),
                    onToggle: () => _toggleSection('Education & Occupation'),
                    children: [
                      _PreferenceRow(
                        icon: Icons.school_outlined,
                        title: 'Education',
                        value: _displayCount(
                          _previewNames(
                            lookups.education,
                            _draft.preferredEducationIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Education',
                          items: lookups.education,
                          selectedIds: _draft.preferredEducationIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredEducationIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.work_outline_rounded,
                        title: 'Occupation',
                        value: _displayCount(
                          _previewNames(
                            lookups.occupation,
                            _draft.preferredOccupationIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Occupation',
                          items: lookups.occupation,
                          selectedIds: _draft.preferredOccupationIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredOccupationIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.business_center_outlined,
                        title: 'Employed in',
                        value: _displayCount(
                          _draft.preferredEmployedInIds
                              .map(
                                (id) => lookups.employedIn
                                    .firstWhere(
                                      (item) => item.id == id,
                                      orElse: () => LookupItem(
                                        id: id,
                                        name: id.toString(),
                                      ),
                                    )
                                    .name,
                              )
                              .toList(growable: false),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Employed in',
                          items: lookups.employedIn,
                          selectedIds: _draft.preferredEmployedInIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredEmployedInIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.payments_outlined,
                        title: 'Income range',
                        value: _rangeFromLookup(
                          lookups.incomes,
                          _draft.minSalaryId,
                          _draft.maxSalaryId,
                        ),
                        onTap: () => _editIncomeRange(lookups.incomes),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ExpandablePreferenceCard(
                    title: 'Religion and Ethnicity',
                    expanded: _expandedSections.contains(
                      'Religion and Ethnicity',
                    ),
                    onToggle: () => _toggleSection('Religion and Ethnicity'),
                    children: [
                      _PreferenceRow(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Religion',
                        value: _displayCount(
                          _previewNames(
                            lookups.religions,
                            _draft.preferredReligionIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Religion',
                          items: lookups.religions,
                          selectedIds: _draft.preferredReligionIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredReligionIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.account_tree_outlined,
                        title: 'Caste',
                        value: _displayCount(
                          _previewNames(
                            lookups.castes,
                            _draft.preferredCasteIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Caste',
                          items: lookups.castes,
                          selectedIds: _draft.preferredCasteIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredCasteIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.group_work_outlined,
                        title: 'Subcaste',
                        value: _displayCount(
                          _previewNames(
                            lookups.subcastes,
                            _draft.preferredSubcasteIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Subcaste',
                          items: lookups.subcastes,
                          selectedIds: _draft.preferredSubcasteIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredSubcasteIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.circle_outlined,
                        title: 'Kulam',
                        value: _displayCount(
                          _previewNames(
                            lookups.kulams,
                            _draft.preferredKulamIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Kulam',
                          items: lookups.kulams,
                          selectedIds: _draft.preferredKulamIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredKulamIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.language_rounded,
                        title: 'Mother tongue',
                        value: _displayCount(
                          _previewNames(
                            lookups.motherTongues,
                            _draft.preferredMotherTongueIds,
                          ),
                          'Not set',
                        ),
                        onTap: () => _pickLookupMultiSelect(
                          title: 'Mother tongue',
                          items: lookups.motherTongues,
                          selectedIds: _draft.preferredMotherTongueIds,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(preferredMotherTongueIds: value),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      PreferenceToggleCard(
                        title: 'Require horoscope match',
                        subtitle:
                            'Turn this on to only show matches with horoscope compatibility.',
                        value: _horoscopeEnabled,
                        onChanged: (next) {
                          setState(() => _horoscopeEnabled = next);
                          _updateDraft(
                            _draft.copyWith(requireHoroscopeMatch: next),
                            queueAutoSave: false,
                          );
                        },
                      ),
                      if (_horoscopeEnabled) ...[
                        const _CardDivider(),
                        _PreferenceRow(
                          icon: Icons.circle_outlined,
                          title: 'Rasi',
                          value: _displayCount(
                            _draft.preferredRasiIds
                                .map((id) => id.toString())
                                .toList(growable: false),
                            'Not set',
                          ),
                          onTap: () => _pickStringMultiSelect(
                            title: 'Rasi',
                            items: const [
                              'Aries',
                              'Taurus',
                              'Gemini',
                              'Cancer',
                              'Leo',
                              'Virgo',
                              'Libra',
                              'Scorpio',
                              'Sagittarius',
                              'Capricorn',
                              'Aquarius',
                              'Pisces',
                            ],
                            selectedValues: _draft.preferredRasiIds
                                .map((id) => id.toString())
                                .toList(growable: false),
                            onChanged: (value) => _updateDraft(
                              _draft.copyWith(
                                preferredRasiIds: value
                                    .map((entry) => int.tryParse(entry) ?? 0)
                                    .where((id) => id > 0)
                                    .toList(growable: false),
                              ),
                              queueAutoSave: false,
                            ),
                          ),
                        ),
                        const _CardDivider(),
                        _PreferenceRow(
                          icon: Icons.star_border_rounded,
                          title: 'Nakshatra',
                          value: _displayCount(
                            _draft.preferredNakshatraIds
                                .map((id) => id.toString())
                                .toList(growable: false),
                            'Not set',
                          ),
                          onTap: () => _pickStringMultiSelect(
                            title: 'Nakshatra',
                            items: const [
                              'Ashwini',
                              'Bharani',
                              'Krittika',
                              'Rohini',
                              'Mrigashirsha',
                              'Ardra',
                              'Punarvasu',
                              'Pushya',
                              'Ashlesha',
                            ],
                            selectedValues: _draft.preferredNakshatraIds
                                .map((id) => id.toString())
                                .toList(growable: false),
                            onChanged: (value) => _updateDraft(
                              _draft.copyWith(
                                preferredNakshatraIds: value
                                    .map((entry) => int.tryParse(entry) ?? 0)
                                    .where((id) => id > 0)
                                    .toList(growable: false),
                              ),
                              queueAutoSave: false,
                            ),
                          ),
                        ),
                        const _CardDivider(),
                        _PreferenceRow(
                          icon: Icons.brightness_6_outlined,
                          title: 'Manglik',
                          value: _displayCount(
                            _draft.preferredManglikStatusIds,
                            'Not set',
                          ),
                          onTap: () => _pickStringMultiSelect(
                            title: 'Manglik',
                            items: const ['Yes', 'No', 'Partial'],
                            selectedValues: _draft.preferredManglikStatusIds,
                            onChanged: (value) => _updateDraft(
                              _draft.copyWith(preferredManglikStatusIds: value),
                              queueAutoSave: false,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ExpandablePreferenceCard(
                    title: 'Lifestyle',
                    expanded: _expandedSections.contains('Lifestyle'),
                    onToggle: () => _toggleSection('Lifestyle'),
                    children: [
                      _PreferenceRow(
                        icon: Icons.restaurant_menu_outlined,
                        title: 'Diet',
                        value: _displayCount(
                          _draft.preferredDietIds
                              .map(
                                (id) => const [
                                  'Vegetarian',
                                  'Non-Vegetarian',
                                  'Eggetarian',
                                  'Vegan',
                                  'Other',
                                ][id - 1],
                              )
                              .whereType<String>()
                              .toList(growable: false),
                          'Not set',
                        ),
                        onTap: () => _pickStringMultiSelect(
                          title: 'Diet',
                          items: const [
                            'Vegetarian',
                            'Non-Vegetarian',
                            'Eggetarian',
                            'Vegan',
                            'Other',
                          ],
                          selectedValues: _draft.preferredDietIds
                              .map(
                                (id) => const [
                                  'Vegetarian',
                                  'Non-Vegetarian',
                                  'Eggetarian',
                                  'Vegan',
                                  'Other',
                                ][id - 1],
                              )
                              .whereType<String>()
                              .toList(growable: false),
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(
                              preferredDietIds: value
                                  .map(
                                    (entry) =>
                                        const [
                                          'Vegetarian',
                                          'Non-Vegetarian',
                                          'Eggetarian',
                                          'Vegan',
                                          'Other',
                                        ].indexOf(entry) +
                                        1,
                                  )
                                  .toList(growable: false),
                            ),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.local_bar_outlined,
                        title: 'Drinking',
                        value: _displayCount(
                          _draft.preferredDrinkingIds
                              .map(
                                (id) => const [
                                  'None',
                                  'Occasionally',
                                  'Regularly',
                                ][id - 1],
                              )
                              .whereType<String>()
                              .toList(growable: false),
                          'Not set',
                        ),
                        onTap: () => _pickStringMultiSelect(
                          title: 'Drinking',
                          items: const ['None', 'Occasionally', 'Regularly'],
                          selectedValues: _draft.preferredDrinkingIds
                              .map(
                                (id) => const [
                                  'None',
                                  'Occasionally',
                                  'Regularly',
                                ][id - 1],
                              )
                              .whereType<String>()
                              .toList(growable: false),
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(
                              preferredDrinkingIds: value
                                  .map(
                                    (entry) =>
                                        const [
                                          'None',
                                          'Occasionally',
                                          'Regularly',
                                        ].indexOf(entry) +
                                        1,
                                  )
                                  .where((id) => id > 0)
                                  .toList(growable: false),
                            ),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      _PreferenceRow(
                        icon: Icons.smoking_rooms_outlined,
                        title: 'Smoking',
                        value: _displayCount(
                          _draft.preferredSmokingIds
                              .map(
                                (id) => const [
                                  'None',
                                  'Occasionally',
                                  'Regularly',
                                ][id - 1],
                              )
                              .whereType<String>()
                              .toList(growable: false),
                          'Not set',
                        ),
                        onTap: () => _pickStringMultiSelect(
                          title: 'Smoking',
                          items: const ['None', 'Occasionally', 'Regularly'],
                          selectedValues: _draft.preferredSmokingIds
                              .map(
                                (id) => const [
                                  'None',
                                  'Occasionally',
                                  'Regularly',
                                ][id - 1],
                              )
                              .whereType<String>()
                              .toList(growable: false),
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(
                              preferredSmokingIds: value
                                  .map(
                                    (entry) =>
                                        const [
                                          'None',
                                          'Occasionally',
                                          'Regularly',
                                        ].indexOf(entry) +
                                        1,
                                  )
                                  .where((id) => id > 0)
                                  .toList(growable: false),
                            ),
                            queueAutoSave: false,
                          ),
                        ),
                      ),
                      const _CardDivider(),
                      PreferenceToggleCard(
                        title: 'Require photo',
                        subtitle:
                            'Turn this on to only show matches who have uploaded a photo.',
                        value: _draft.requirePhoto,
                        onChanged: (next) => _updateDraft(
                          _draft.copyWith(requirePhoto: next),
                          queueAutoSave: false,
                        ),
                      ),
                      const _CardDivider(),
                      PreferenceToggleCard(
                        title: 'Phone verified only',
                        subtitle:
                            'Only show matches with a verified phone number.',
                        value: _draft.requirePhoneVerified,
                        onChanged: (next) => _updateDraft(
                          _draft.copyWith(requirePhoneVerified: next),
                          queueAutoSave: false,
                        ),
                      ),
                      if (_showChildrenPreferenceOptions()) ...[
                        const _CardDivider(),
                        PreferenceToggleCard(
                          title: 'Accept partner with children',
                          subtitle:
                              'Include matches who already have children.',
                          value: _draft.acceptPartnerWithChildren,
                          onChanged: (next) => _updateDraft(
                            _draft.copyWith(
                              acceptPartnerWithChildren: next,
                            ),
                            queueAutoSave: false,
                          ),
                        ),
                        const _CardDivider(),
                        PreferenceToggleCard(
                          title: 'Prefer no children',
                          subtitle:
                              'Prioritize matches without children.',
                          value: _draft.preferNoChildren,
                          onChanged: (next) => _updateDraft(
                            _draft.copyWith(preferNoChildren: next),
                            queueAutoSave: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.selected,
    this.minWidth = 0,
  });

  final String label;
  final bool selected;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _selectedChipFill : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _selectedChipBorder : const Color(0xFFD9D9E6),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? const Color(0xFF242433) : const Color(0xFF556070),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ExpandablePreferenceCard extends StatelessWidget {
  const _ExpandablePreferenceCard({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: _cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${children.length} options',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (expanded) ...[const SizedBox(height: 14), ...children],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _selectedChipFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F3),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
