import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lookups/data/static_data_repository.dart';
import '../../lookups/domain/lookup_item.dart';
import '../../lookups/domain/static_data.dart';
import '../data/my_profile_repository.dart';

class ProfileDetailsEditPage extends ConsumerStatefulWidget {
  const ProfileDetailsEditPage({
    super.key,
    required this.profileView,
  });

  final MyProfileView profileView;

  @override
  ConsumerState<ProfileDetailsEditPage> createState() =>
      _ProfileDetailsEditPageState();
}

class _ProfileDetailsEditPageState extends ConsumerState<ProfileDetailsEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, String> _fieldErrors = <String, String>{};

  late final TextEditingController _fullnameController;
  late final TextEditingController _aboutController;
  late final TextEditingController _weightController;

  DateTime _selectedDateOfBirth = DateTime.now();
  String _selectedProfileCreatedFor = 'Self';
  int? _selectedMotherTongueId;
  int? _selectedHeightId;
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedCityId;
  int? _selectedEducationId;
  int? _selectedOccupationId;
  int? _selectedEmployedInId;
  int? _selectedSalaryId;

  String? _lockedFieldKey;
  String? _lockedFieldMessage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profileView.profile;
    _fullnameController = TextEditingController(text: profile.fullname);
    _aboutController = TextEditingController(text: profile.aboutMe ?? '');
    _weightController = TextEditingController(
      text: profile.weight?.toString() ?? '',
    );
    _selectedDateOfBirth = profile.dateOfBirth;
    _selectedProfileCreatedFor = profile.profileCreatedFor.isEmpty
        ? 'Self'
        : profile.profileCreatedFor;
    _selectedMotherTongueId = profile.motherTongueId;
    _selectedHeightId = profile.heightId;
    _selectedCountryId = profile.countryId;
    _selectedStateId = profile.stateId;
    _selectedCityId = profile.cityId;
    _selectedEducationId = profile.educationDegreeId;
    _selectedOccupationId = profile.occupationRoleId;
    _selectedEmployedInId = profile.employedInId;
    _selectedSalaryId = profile.expectedSalaryId;
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _aboutController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showLockedMessage(String fieldKey) {
    setState(() {
      _lockedFieldKey = fieldKey;
      _lockedFieldMessage =
          'This field is locked. Please contact support assistance.';
    });
  }

  void _prepareForPopup() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearError(String fieldKey) {
    if (!_fieldErrors.containsKey(fieldKey)) return;
    setState(() => _fieldErrors.remove(fieldKey));
  }

  bool _validateInputs() {
    final errors = <String, String>{};

    if (_fullnameController.text.trim().isEmpty) {
      errors['fullname'] = 'Full name is required';
    }

    if (_selectedProfileCreatedFor.trim().isEmpty) {
      errors['profileCreatedFor'] = 'Select who this profile is created for';
    }

    if (_selectedMotherTongueId == null) {
      errors['motherTongueId'] = 'Select a mother tongue';
    }

    if (_selectedHeightId == null) {
      errors['heightId'] = 'Select a height';
    }

    if (_selectedCountryId == null) {
      errors['countryId'] = 'Select a country';
    }

    if (_selectedStateId == null) {
      errors['stateId'] = 'Select a state';
    }

    if (_selectedCityId == null) {
      errors['cityId'] = 'Select a city';
    }

    if (_selectedEducationId == null) {
      errors['educationDegreeId'] = 'Select an education value';
    }

    if (_selectedOccupationId == null) {
      errors['occupationRoleId'] = 'Select an occupation';
    }

    if (_selectedEmployedInId == null) {
      errors['employedInId'] = 'Select employed in';
    }

    if (_selectedSalaryId == null) {
      errors['expectedSalaryId'] = 'Select salary';
    }

    final weight = _weightController.text.trim();
    if (weight.isNotEmpty) {
      final parsedWeight = double.tryParse(weight);
      if (parsedWeight == null || parsedWeight <= 0) {
        errors['weight'] = 'Enter a valid weight';
      }
    }

    if (errors.isEmpty) return true;

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return false;
  }

  Future<void> _pickDateOfBirth() async {
    _prepareForPopup();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateOfBirth),
    );
    if (time == null) return;

    setState(() {
      _selectedDateOfBirth = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  List<LookupItem> _statesForCountry(List<LookupItem> states, int? countryId) {
    if (countryId == null) return const <LookupItem>[];
    return states
        .where((state) => state.countryCode == countryId)
        .toList(growable: false);
  }

  List<LookupItem> _citiesForLocation(
    List<LookupItem> cities,
    List<LookupItem> states,
    int? countryId,
    int? stateId,
  ) {
    if (countryId == null) return const <LookupItem>[];

    final allowedStates = _statesForCountry(states, countryId)
        .map((state) => state.id)
        .toSet();
    final selectedStateIds = stateId != null && allowedStates.contains(stateId)
        ? <int>{stateId}
        : <int>{};

    return cities.where((city) {
      final cityStateId = city.stateId ?? city.parentId;
      if (selectedStateIds.isNotEmpty) {
        return cityStateId != null && selectedStateIds.contains(cityStateId);
      }

      if (cityStateId != null) {
        return allowedStates.contains(cityStateId);
      }

      final cityCountryCode = city.countryCode;
      return cityCountryCode != null && countryId == cityCountryCode;
    }).toList(growable: false);
  }

  LookupItem? _lookupItem(List<LookupItem> items, int? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _formatDateTime(DateTime value) {
    final date = MaterialLocalizations.of(context).formatFullDate(value);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: false,
    );
    return '$date, $time';
  }

  String _nameForLookup(List<LookupItem> items, int? id) {
    return _lookupItem(items, id)?.name ?? 'Not set';
  }

  Future<LookupItem?> _showSingleLookupBottomSheet({
    required String title,
    required List<LookupItem> items,
    required int? selectedId,
  }) {
    _prepareForPopup();
    return showModalBottomSheet<LookupItem?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
                      onPressed: () {
                        Navigator.of(sheetContext).pop(
                          _lookupItem(items, selectedId),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item.id == selectedId;
                      return Material(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFF94A3B8),
                          ),
                          title: Text(item.name),
                          onTap: () {
                            Navigator.of(sheetContext).pop(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showSingleStringBottomSheet({
    required String title,
    required List<String> options,
    required String selectedItem,
  }) {
    _prepareForPopup();
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.64,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(selectedItem),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = options[index];
                      final isSelected = item == selectedItem;
                      return Material(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFF94A3B8),
                          ),
                          title: Text(item),
                          onTap: () {
                            Navigator.of(sheetContext).pop(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfileCreatedFor() async {
    final picked = await _showSingleStringBottomSheet(
      title: 'Profile created for',
      options: const [
        'Self',
        'Parent',
        'Sibling',
        'Relative',
        'Guardian',
        'Friend',
        'Other',
      ],
      selectedItem: _selectedProfileCreatedFor,
    );
    if (picked == null || picked.isEmpty) return;
    setState(() => _selectedProfileCreatedFor = picked);
    _clearError('profileCreatedFor');
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    final updates = <String, dynamic>{};

    void addValue(String key, Object? value) {
      if (value != null) {
        updates[key] = value;
      }
    }

    addValue('fullname', _fullnameController.text.trim());
    addValue('profileCreatedFor', _selectedProfileCreatedFor);
    addValue('dateOfBirth', _selectedDateOfBirth.toIso8601String());
    addValue('motherTongueId', _selectedMotherTongueId);
    addValue('heightId', _selectedHeightId);
    addValue('countryId', _selectedCountryId);
    addValue('stateId', _selectedStateId);
    addValue('cityId', _selectedCityId);
    addValue('educationDegreeId', _selectedEducationId);
    addValue('occupationRoleId', _selectedOccupationId);
    addValue('employedInId', _selectedEmployedInId);
    addValue('expectedSalaryId', _selectedSalaryId);

    final about = _aboutController.text.trim();
    if (about.isNotEmpty) {
      updates['aboutMe'] = about;
    }

    final weight = _weightController.text.trim();
    if (weight.isNotEmpty) {
      final parsedWeight = double.tryParse(weight);
      if (parsedWeight == null || parsedWeight <= 0) {
        setState(() => _fieldErrors['weight'] = 'Enter a valid weight');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix the highlighted fields.')),
        );
        return;
      }
      updates['weight'] = parsedWeight;
    }

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to update yet.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(myProfileRepositoryProvider)
          .updateMyProfile(widget.profileView.accountId, updates);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _editTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    String helper = 'Tap to choose',
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError ? const Color(0xFFDC2626) : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasError
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: hasError
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: hasError
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value.isEmpty ? helper : value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: hasError
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF475569),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: hasError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _lockedField({
    required String fieldKey,
    required String label,
    required String value,
  }) {
    final isActive = _lockedFieldKey == fieldKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showLockedMessage(fieldKey),
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value.isEmpty ? 'Not added' : value,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF475569),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isActive && _lockedFieldMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              _lockedFieldMessage!,
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lookupsAsync = ref.watch(staticDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile Details'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: lookupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (StaticData lookups) {
          final effectiveStates = _statesForCountry(
            lookups.states,
            _selectedCountryId,
          );
          final effectiveStateId =
              _lookupItem(effectiveStates, _selectedStateId)?.id;
          final effectiveCities = _citiesForLocation(
            lookups.cities,
            lookups.states,
            _selectedCountryId,
            effectiveStateId,
          );
          final effectiveCityId =
              _lookupItem(effectiveCities, _selectedCityId)?.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _sectionCard(
                  title: 'Identity',
                  subtitle: 'Update your main identity fields here.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullnameController,
                        onChanged: (_) => _clearError('fullname'),
                        decoration: InputDecoration(
                          labelText: 'Full name',
                          border: const OutlineInputBorder(),
                          errorText: _fieldErrors['fullname'],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'Profile created for',
                        value: _selectedProfileCreatedFor,
                        onTap: _pickProfileCreatedFor,
                        errorText: _fieldErrors['profileCreatedFor'],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of birth with time',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_formatDateTime(_selectedDateOfBirth)),
                              ),
                              const Icon(Icons.edit_outlined),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'Mother tongue',
                        value: _nameForLookup(lookups.motherTongues, _selectedMotherTongueId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Mother tongue',
                          items: lookups.motherTongues,
                          selectedId: _selectedMotherTongueId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() => _selectedMotherTongueId = item.id);
                          _clearError('motherTongueId');
                        }),
                        errorText: _fieldErrors['motherTongueId'],
                      ),
                    ],
                  ),
                ),
                _sectionCard(
                  title: 'Contact',
                  subtitle: 'These details are loaded from the account table.',
                  child: Column(
                    children: [
                      _lockedField(
                        fieldKey: 'email',
                        label: 'Email',
                        value: widget.profileView.primaryEmail ?? 'Not added',
                      ),
                      const SizedBox(height: 12),
                      _lockedField(
                        fieldKey: 'phone',
                        label: 'Phone',
                        value: widget.profileView.primaryPhone ?? 'Not added',
                      ),
                    ],
                  ),
                ),
                _sectionCard(
                  title: 'Physical details',
                  subtitle: 'Only height and weight can be updated here.',
                  child: Column(
                    children: [
                      _editTile(
                        label: 'Height',
                        value: _nameForLookup(lookups.heights, _selectedHeightId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Height',
                          items: lookups.heights,
                          selectedId: _selectedHeightId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() => _selectedHeightId = item.id);
                          _clearError('heightId');
                        }),
                        errorText: _fieldErrors['heightId'],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _clearError('weight'),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: const OutlineInputBorder(),
                          errorText: _fieldErrors['weight'],
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionCard(
                  title: 'Location',
                  subtitle: 'Country, state and city are editable. Other location data is locked.',
                  child: Column(
                    children: [
                      _editTile(
                        label: 'Country',
                        value: _nameForLookup(lookups.countries, _selectedCountryId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Country',
                          items: lookups.countries,
                          selectedId: _selectedCountryId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() {
                            _selectedCountryId = item.id;
                            _selectedStateId = null;
                            _selectedCityId = null;
                          });
                          _clearError('countryId');
                          _clearError('stateId');
                          _clearError('cityId');
                        }),
                        errorText: _fieldErrors['countryId'],
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'State',
                        value: _nameForLookup(effectiveStates, effectiveStateId),
                        onTap: effectiveStates.isEmpty
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Choose a country first'),
                                  ),
                                )
                            : () => _showSingleLookupBottomSheet(
                                  title: 'State',
                                  items: effectiveStates,
                                  selectedId: effectiveStateId,
                                ).then((item) {
                                  if (!mounted) return;
                                  if (item == null) return;
                                  setState(() {
                                    _selectedStateId = item.id;
                                    _selectedCityId = null;
                                  });
                                  _clearError('stateId');
                                  _clearError('cityId');
                                }),
                        errorText: _fieldErrors['stateId'],
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'City',
                        value: _nameForLookup(effectiveCities, effectiveCityId),
                        onTap: effectiveCities.isEmpty
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Choose a country and state first'),
                                  ),
                                )
                            : () => _showSingleLookupBottomSheet(
                                  title: 'City',
                                  items: effectiveCities,
                                  selectedId: effectiveCityId,
                                ).then((item) {
                                  if (!mounted) return;
                                  if (item == null) return;
                                  setState(() => _selectedCityId = item.id);
                                  _clearError('cityId');
                                }),
                        errorText: _fieldErrors['cityId'],
                      ),
                      const SizedBox(height: 14),
                      _lockedField(
                        fieldKey: 'religion',
                        label: 'Religion',
                        value: _lookupItem(lookups.religions, widget.profileView.profile.religionId)?.name ??
                            'Not added',
                      ),
                      const SizedBox(height: 12),
                      _lockedField(
                        fieldKey: 'caste',
                        label: 'Caste',
                        value: _lookupItem(lookups.castes, widget.profileView.profile.casteId)?.name ??
                            'Not added',
                      ),
                      const SizedBox(height: 12),
                      _lockedField(
                        fieldKey: 'subcaste',
                        label: 'Subcaste',
                        value: _lookupItem(lookups.subcastes, widget.profileView.profile.subcasteId)?.name ??
                            'Not added',
                      ),
                      const SizedBox(height: 12),
                      _lockedField(
                        fieldKey: 'kulam',
                        label: 'Kulam',
                        value: _lookupItem(lookups.kulams, widget.profileView.profile.kulamId)?.name ??
                            'Not added',
                      ),
                    ],
                  ),
                ),
                _sectionCard(
                  title: 'Education & career',
                  subtitle: 'Education, occupation, employed-in and salary are editable. Other fields are locked.',
                  child: Column(
                    children: [
                      _editTile(
                        label: 'Education',
                        value: _nameForLookup(lookups.education, _selectedEducationId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Education',
                          items: lookups.education,
                          selectedId: _selectedEducationId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() => _selectedEducationId = item.id);
                          _clearError('educationDegreeId');
                        }),
                        errorText: _fieldErrors['educationDegreeId'],
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'Occupation',
                        value: _nameForLookup(lookups.occupation, _selectedOccupationId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Occupation',
                          items: lookups.occupation,
                          selectedId: _selectedOccupationId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() => _selectedOccupationId = item.id);
                          _clearError('occupationRoleId');
                        }),
                        errorText: _fieldErrors['occupationRoleId'],
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'Employed in',
                        value: _nameForLookup(lookups.employedIn, _selectedEmployedInId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Employed in',
                          items: lookups.employedIn,
                          selectedId: _selectedEmployedInId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() => _selectedEmployedInId = item.id);
                          _clearError('employedInId');
                        }),
                        errorText: _fieldErrors['employedInId'],
                      ),
                      const SizedBox(height: 14),
                      _editTile(
                        label: 'Salary',
                        value: _nameForLookup(lookups.incomes, _selectedSalaryId),
                        onTap: () => _showSingleLookupBottomSheet(
                          title: 'Salary',
                          items: lookups.incomes,
                          selectedId: _selectedSalaryId,
                        ).then((item) {
                          if (!mounted) return;
                          if (item == null) return;
                          setState(() => _selectedSalaryId = item.id);
                          _clearError('expectedSalaryId');
                        }),
                        errorText: _fieldErrors['expectedSalaryId'],
                      ),
                    ],
                  ),
                ),
                _sectionCard(
                  title: 'About me',
                  subtitle: 'You can edit your self-description here.',
                  child: TextFormField(
                    controller: _aboutController,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'About me',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                _sectionCard(
                  title: 'Quick summary',
                  subtitle: 'Review the current profile snapshot.',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _summaryChip('Name', _fullnameController.text),
                      _summaryChip('Profile created for', _selectedProfileCreatedFor),
                      _summaryChip('DOB', _formatDateTime(_selectedDateOfBirth)),
                      _summaryChip(
                        'Mother tongue',
                        _nameForLookup(lookups.motherTongues, _selectedMotherTongueId),
                      ),
                      _summaryChip(
                        'Height',
                        _nameForLookup(lookups.heights, _selectedHeightId),
                      ),
                      _summaryChip(
                        'Location',
                        [
                          _nameForLookup(lookups.countries, _selectedCountryId),
                          _nameForLookup(effectiveStates, effectiveStateId),
                          _nameForLookup(effectiveCities, effectiveCityId),
                        ].where((item) => item != 'Not set').join(', '),
                      ),
                      _summaryChip(
                        'Education',
                        _nameForLookup(lookups.education, _selectedEducationId),
                      ),
                      _summaryChip(
                        'Occupation',
                        _nameForLookup(lookups.occupation, _selectedOccupationId),
                      ),
                      _summaryChip(
                        'Salary',
                        _nameForLookup(lookups.incomes, _selectedSalaryId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_rounded),
          label: const Text('Save changes'),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String? value) {
    final display = (value == null || value.trim().isEmpty) ? 'Not set' : value;
    return Chip(
      label: Text('$label: $display'),
      visualDensity: VisualDensity.compact,
    );
  }
}
