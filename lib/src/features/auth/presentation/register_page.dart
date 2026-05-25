import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../media/data/profile_picture_repository.dart';
import '../../lookups/data/static_data_repository.dart';
import '../../lookups/domain/lookup_item.dart';
import '../../lookups/domain/static_data.dart';
import '../data/auth_repository.dart';
import '../domain/registration_payload.dart';
import 'auth_controller.dart';
import '../../../l10n/app_localizations.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _about = TextEditingController();
  final _imagePicker = ImagePicker();

  int _step = 0;
  DateTime? _dob;
  String _profileFor = 'Self';
  String _gender = 'Male';
  String _maritalStatus = 'Single';
  int? _motherTongueId;
  int? _religionId;
  int? _sectId;
  int? _casteId;
  int? _subcasteId;
  int? _kulamId;
  int? _countryId;
  int? _stateId;
  int? _cityId;
  int? _heightId;
  int? _educationId;
  int? _occupationId;
  int? _employedInId;
  int? _incomeId;
  int? _matrimonyModeId;
  bool? _phoneAvailable;
  bool? _emailAvailable;
  bool _checkingPhone = false;
  bool _checkingEmail = false;
  bool _uploadingPhotos = false;
  List<XFile> _profilePictures = const [];

  List<_ProfileStep> _steps(AppLocalizations loc) => [
    _ProfileStep(loc.account, loc.t('stepAccountSubtitle')),
    _ProfileStep(loc.t('basics'), loc.t('stepBasicsSubtitle')),
    _ProfileStep(loc.t('location'), loc.t('stepLocationSubtitle')),
    _ProfileStep(loc.t('career'), loc.t('stepCareerSubtitle')),
    _ProfileStep(loc.t('mode'), loc.t('stepModeSubtitle')),
    const _ProfileStep('Photos', 'Add at least one profile picture'),
    _ProfileStep(loc.t('review'), loc.t('stepReviewSubtitle')),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    _weight.dispose();
    _about.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  bool _validateStep() {
    if (_step == 0) {
      return _phone.text.trim().isNotEmpty &&
          _password.text.length >= 6 &&
          (_email.text.trim().isEmpty || _email.text.contains('@'));
    }
    if (_step == 1) {
      return _name.text.trim().isNotEmpty && _dob != null;
    }
    if (_step == 4) {
      return _matrimonyModeId != null;
    }
    if (_step == 5) {
      return _profilePictures.isNotEmpty;
    }
    return true;
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validateStep()) {
      _showMessage(ref.read(localizationsProvider).pleaseCompleteStep);
      return;
    }
    if (_step < _steps(ref.read(localizationsProvider)).length - 1) {
      _goToStep(_step + 1);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    _goToStep(_step - 1);
  }

Future<void> _pickDob() async {
  final now = DateTime.now();

  // Step 1: pick the date
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime(now.year - 24, now.month, now.day),
    firstDate: DateTime(now.year - 75),
    lastDate: DateTime(now.year - 18, now.month, now.day),
  );
  if (pickedDate == null) return;

  // Step 2: pick the birth time
  if (!mounted) return;
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 0, minute: 0),
    helpText: 'Select birth time (optional)',
  );

  setState(() {
    _dob = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 0,
      pickedTime?.minute ?? 0,
    );
  });
}

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_validateStep()) {
      _showMessage(ref.read(localizationsProvider).pleaseCompleteDetails);
      return;
    }

    final payload = RegistrationPayload(
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      fullName: _name.text,
      profileCreatedFor: _profileFor,
      dateOfBirth: _dob!,
      gender: _gender,
      maritalStatus: _maritalStatus,
      religionId: _religionId,
      sectId: _sectId,
      motherTongueId: _motherTongueId,
      casteId: _casteId,
      subcasteId: _subcasteId,
      kulamId: _kulamId,
      countryId: _countryId,
      stateId: _stateId,
      cityId: _cityId,
      heightId: _heightId,
      weight: int.tryParse(_weight.text.trim()),
      educationDegreeId: _educationId,
      occupationRoleId: _occupationId,
      employedInId: _employedInId,
      expectedSalaryId: _incomeId,
      aboutMe: _about.text.trim().isEmpty ? null : _about.text.trim(),
      matrimonyModeId: _matrimonyModeId,
    );

    await ref.read(authControllerProvider.notifier).register(payload);
    if (!mounted || ref.read(authControllerProvider).hasError) return;

    setState(() => _uploadingPhotos = true);
    try {
      await ref
          .read(profilePictureRepositoryProvider)
          .uploadProfilePictures(_profilePictures);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _showMessage('Account created, but photo upload failed. Please retry.');
    } finally {
      if (mounted) setState(() => _uploadingPhotos = false);
    }
  }

  Future<void> _pickProfilePictures() async {
    final files = await _imagePicker.pickMultiImage(limit: 8);
    setState(() => _profilePictures = files);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final lookups = ref.watch(staticDataProvider);
    final auth = ref.watch(authControllerProvider);
    final loc = ref.watch(localizationsProvider);
    final steps = _steps(loc);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          tooltip: loc.back,
          onPressed: _back,
          icon: const Icon(CupertinoIcons.chevron_back),
        ),
        title: Text(loc.createProfile),
      ),
      body: SafeArea(
        child: lookups.when(
          data: (data) => Form(
            key: _formKey,
            child: Column(
              children: [
                _ProgressHeader(step: _step, steps: steps),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepSurface(
                        title: loc.t('secureAccessTitle'),
                        subtitle: loc.t('secureAccessSubtitle'),
                        children: [
                          _PremiumTextField(
                            controller: _phone,
                            label: loc.phoneNumber,
                            hint: loc.enterMobileNumber,
                            icon: CupertinoIcons.phone,
                            keyboardType: TextInputType.phone,
                            suffix: _checkingPhone
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _phoneAvailable == true
                                ? const Icon(
                                    CupertinoIcons.check_mark_circled,
                                    color: Colors.green,
                                    size: 20,
                                  )
                                : _phoneAvailable == false
                                ? const Icon(
                                    CupertinoIcons.xmark_circle,
                                    color: Colors.red,
                                    size: 20,
                                  )
                                : null,
                            onChanged: (value) =>
                                _checkPhoneAvailability(value),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? loc.phoneRequired
                                : _phoneAvailable == false
                                ? loc.t('phoneAlreadyRegistered')
                                : null,
                          ),
                          _PremiumTextField(
                            controller: _email,
                            label: loc.t('email'),
                            hint: loc.t('optionalRecommended'),
                            icon: CupertinoIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                            suffix: _checkingEmail
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _emailAvailable == true
                                ? const Icon(
                                    CupertinoIcons.check_mark_circled,
                                    color: Colors.green,
                                    size: 20,
                                  )
                                : _emailAvailable == false
                                ? const Icon(
                                    CupertinoIcons.xmark_circle,
                                    color: Colors.red,
                                    size: 20,
                                  )
                                : null,
                            onChanged: (value) =>
                                _checkEmailAvailability(value),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isNotEmpty && !text.contains('@')) {
                                return loc.t('enterValidEmail');
                              }
                              if (text.isNotEmpty && _emailAvailable == false) {
                                return loc.t('emailAlreadyRegistered');
                              }
                              return null;
                            },
                          ),
                          _PremiumTextField(
                            controller: _password,
                            label: loc.password,
                            hint: loc.t('minimumSixCharacters'),
                            icon: CupertinoIcons.lock,
                            obscureText: true,
                            validator: (value) =>
                                value == null || value.length < 6
                                ? loc.passwordMinLength
                                : null,
                          ),
                        ],
                      ),
                      _StepSurface(
                        title: loc.t('profileBasicsTitle'),
                        subtitle: loc.t('profileBasicsSubtitle'),
                        children: [
                          _PremiumTextField(
                            controller: _name,
                            label: loc.t('fullName'),
                            hint: loc.t('nameShownOnProfile'),
                            icon: CupertinoIcons.person,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? loc.t('fullNameRequired')
                                : null,
                          ),
                          _PillSelector<String>(
                            label: loc.t('profileCreatedFor'),
                            value: _profileFor,
                            values: const [
                              'Self',
                              'Son',
                              'Daughter',
                              'Brother',
                              'Sister',
                              'Relative',
                              'Friend',
                            ],
                            labelBuilder: loc.choice,
                            onChanged: (value) =>
                                setState(() => _profileFor = value),
                          ),
                          _PillSelector<String>(
                            label: loc.t('gender'),
                            value: _gender,
                            values: const ['Male', 'Female', 'Other'],
                            labelBuilder: loc.choice,
                            onChanged: (value) =>
                                setState(() => _gender = value),
                          ),
                          _PillSelector<String>(
                            label: loc.t('maritalStatus'),
                            value: _maritalStatus,
                            values: const [
                              'Single',
                              'Divorced',
                              'Separated',
                              'Widowed',
                            ],
                            labelBuilder: loc.choice,
                            onChanged: (value) =>
                                setState(() => _maritalStatus = value),
                          ),
                          _ActionField(
                            label: loc.t('dateOfBirth'),
                            value: _dob == null
                                ? loc.chooseDate
                                : DateFormat('d MMM yyyy, hh:mm a').format(_dob!),
                            icon: CupertinoIcons.calendar,
                            onTap: _pickDob,
                          ),
                          _LookupActionField(
                            label: loc.t('motherTongue'),
                            valueId: _motherTongueId,
                            items: data.motherTongues,
                            onChanged: (id) =>
                                setState(() => _motherTongueId = id),
                          ),
                          _LookupActionField(
                            label: loc.t('religion'),
                            valueId: _religionId,
                            items: _religionItems(
                              data.casteGroups,
                              data.religions,
                            ),
                            onChanged: (id) => setState(() {
                              _religionId = id;
                              _sectId = null;
                              _casteId = null;
                              _subcasteId = null;
                              _kulamId = null;
                            }),
                          ),
                          if (_sectsForSelection(data.sects).isNotEmpty ||
                              _sectId != null)
                            _LookupActionField(
                              label: loc.t('sect'),
                              valueId: _sectId,
                              items: _sectsForSelection(data.sects),
                              disabledValue: _religionId == null
                                  ? loc.t('selectReligionFirst')
                                  : loc.t('noSectsFound'),
                              onChanged: (id) => setState(() {
                                _sectId = id;
                                _casteId = null;
                                _subcasteId = null;
                                _kulamId = null;
                              }),
                            ),
                          _LookupActionField(
                            label: loc.t('caste'),
                            valueId: _casteId,
                            items: _castesForSelection(
                              castes: data.castes,
                              casteGroups: data.casteGroups,
                              sects: data.sects,
                            ),
                            disabledValue: _casteDisabledValue(data.sects, loc),
                            onChanged: (id) => setState(() {
                              _casteId = id;
                              _subcasteId = null;
                              _kulamId = null;
                            }),
                          ),
                          if (_subcastesForSelection(
                                data.subcastes,
                              ).isNotEmpty ||
                              _subcasteId != null)
                            _LookupActionField(
                              label: loc.t('subcaste'),
                              valueId: _subcasteId,
                              items: _subcastesForSelection(data.subcastes),
                              disabledValue: _casteId == null
                                  ? loc.t('selectCasteFirst')
                                  : loc.t('noSubcastesFound'),
                              onChanged: (id) =>
                                  setState(() => _subcasteId = id),
                            ),
                          if (_kulamsForSelection(data.kulams).isNotEmpty ||
                              _kulamId != null)
                            _LookupActionField(
                              label: loc.t('kulam'),
                              valueId: _kulamId,
                              items: _kulamsForSelection(data.kulams),
                              disabledValue: _subcasteId == null
                                  ? loc.t('selectSubcasteFirst')
                                  : loc.t('noKulamsFound'),
                              onChanged: (id) => setState(() => _kulamId = id),
                            ),
                          _LookupActionField(
                            label: loc.t('height'),
                            valueId: _heightId,
                            items: data.heights,
                            onChanged: (id) => setState(() => _heightId = id),
                          ),
                          _PremiumTextField(
                            controller: _weight,
                            label: loc.t('weight'),
                            hint: loc.t('enterWeightKg'),
                            icon: CupertinoIcons.gauge,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final weight = int.tryParse(text);
                              if (weight == null || weight <= 0) {
                                return loc.t('enterValidWeight');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      _StepSurface(
                        title: loc.t('locationTitle'),
                        subtitle: loc.t('locationSubtitle'),
                        children: [
                          _LookupActionField(
                            label: loc.t('country'),
                            valueId: _countryId,
                            items: data.countries,
                            onChanged: (id) => setState(() {
                              _countryId = id;
                              _stateId = null;
                              _cityId = null;
                            }),
                          ),
                          _LookupActionField(
                            label: loc.t('state'),
                            valueId: _stateId,
                            items: _statesForCountry(data.states),
                            disabledValue: _countryId == null
                                ? loc.t('selectCountryFirst')
                                : loc.t('noStatesFound'),
                            onChanged: (id) => setState(() {
                              _stateId = id;
                              _cityId = null;
                            }),
                          ),
                          _LookupActionField(
                            label: loc.t('city'),
                            valueId: _cityId,
                            items: _citiesForSelection(data.cities),
                            disabledValue: _countryId == null
                                ? loc.t('selectCountryFirst')
                                : loc.t('noCitiesFound'),
                            onChanged: (id) => setState(() => _cityId = id),
                          ),
                        ],
                      ),
                      _StepSurface(
                        title: loc.t('careerTitle'),
                        subtitle: loc.t('careerSubtitle'),
                        children: [
                          _LookupActionField(
                            label: loc.t('education'),
                            valueId: _educationId,
                            items: data.education,
                            onChanged: (id) =>
                                setState(() => _educationId = id),
                          ),
                          _LookupActionField(
                            label: loc.t('occupation'),
                            valueId: _occupationId,
                            items: data.occupation,
                            onChanged: (id) =>
                                setState(() => _occupationId = id),
                          ),
                          _LookupActionField(
                            label: loc.t('employedIn'),
                            valueId: _employedInId,
                            items: data.employedIn,
                            onChanged: (id) =>
                                setState(() => _employedInId = id),
                          ),
                          _LookupActionField(
                            label: loc.t('expectedSalary'),
                            valueId: _incomeId,
                            items: data.incomes,
                            onChanged: (id) => setState(() => _incomeId = id),
                          ),
                          _PremiumTextField(
                            controller: _about,
                            label: loc.t('aboutProfile'),
                            hint: loc.t('aboutProfileHint'),
                            icon: CupertinoIcons.text_alignleft,
                            minLines: 4,
                            maxLines: 5,
                          ),
                        ],
                      ),
                      _StepSurface(
                        title: loc.t('matrimonyModeTitle'),
                        subtitle: loc.t('matrimonyModeSubtitle'),
                        children: [
                          if (data.matrimonyModes.isEmpty)
                            Text(loc.t('noMatrimonyModesAvailable'))
                          else
                            ...data.matrimonyModes.map((mode) {
                              final selected = _matrimonyModeId == mode.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => setState(
                                    () => _matrimonyModeId = mode.id,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : const Color(0xFFE2E8F0),
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            selected
                                                ? CupertinoIcons.check_mark
                                                : CupertinoIcons.heart,
                                            color: selected
                                                ? Colors.white
                                                : Colors.black54,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mode.displayName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              if (mode.description != null &&
                                                  mode.description!.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    mode.description!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors.black54,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                      _StepSurface(
                        title: 'Add profile photos',
                        subtitle:
                            'Upload at least one clear photo. The first photo becomes your primary picture.',
                        children: [
                          _PhotoSelectionPanel(
                            files: _profilePictures,
                            onPick: _pickProfilePictures,
                            onRemove: (file) => setState(
                              () => _profilePictures = _profilePictures
                                  .where((item) => item.path != file.path)
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                      _ReviewStep(
                        name: _name.text,
                        phone: _phone.text,
                        email: _email.text,
                        dob: _dob,
                        profileFor: _profileFor,
                        gender: _gender,
                        maritalStatus: _maritalStatus,
                        motherTongue: _labelFor(
                          data.motherTongues,
                          _motherTongueId,
                          loc,
                        ),
                        religion: _labelFor(
                          _religionItems(data.casteGroups, data.religions),
                          _religionId,
                          loc,
                        ),
                        sect: _labelFor(data.sects, _sectId, loc),
                        caste: _labelFor(data.castes, _casteId, loc),
                        subcaste: _labelFor(data.subcastes, _subcasteId, loc),
                        kulam: _labelFor(data.kulams, _kulamId, loc),
                        weight: _weight.text,
                        city: _labelFor(data.cities, _cityId, loc),
                        education: _labelFor(data.education, _educationId, loc),
                        occupation: _labelFor(
                          data.occupation,
                          _occupationId,
                          loc,
                        ),
                        employedIn: _labelFor(
                          data.employedIn,
                          _employedInId,
                          loc,
                        ),
                        matrimonyMode: _modeLabelFor(
                          data.matrimonyModes,
                          _matrimonyModeId,
                          loc,
                        ),
                        photoCount: _profilePictures.length,
                        loc: loc,
                      ),
                    ],
                  ),
                ),
                if (auth.hasError)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _ErrorBanner(auth.error.toString()),
                  ),
                _BottomBar(
                  isLast: _step == steps.length - 1,
                  isLoading: auth.isLoading || _uploadingPhotos,
                  onBack: _back,
                  onNext: _next,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
          error: (error, _) => _LoadError(message: error.toString()),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  String _labelFor(List<LookupItem> items, int? id, AppLocalizations loc) {
    if (id == null) return loc.notSelected;
    return items.where((item) => item.id == id).firstOrNull?.name ??
        loc.notSelected;
  }

  String _modeLabelFor(
    List<MatrimonyMode> modes,
    int? id,
    AppLocalizations loc,
  ) {
    if (id == null) return loc.notSelected;
    return modes.where((mode) => mode.id == id).firstOrNull?.displayName ??
        loc.notSelected;
  }

  List<LookupItem> _religionItems(
    List<LookupItem> casteGroups,
    List<LookupItem> religions,
  ) {
    return casteGroups.isNotEmpty ? casteGroups : religions;
  }

  List<LookupItem> _sectsForSelection(List<LookupItem> sects) {
    if (_religionId == null) return const [];
    return sects
        .where((sect) => sect.parentId == _religionId)
        .toList(growable: false);
  }

  List<LookupItem> _castesForSelection({
    required List<LookupItem> castes,
    required List<LookupItem> casteGroups,
    required List<LookupItem> sects,
  }) {
    if (_religionId == null) return const [];
    if (_sectId != null) {
      return castes
          .where((caste) => caste.parentId == _sectId)
          .toList(growable: false);
    }

    if (_sectsForSelection(sects).isNotEmpty) return const [];

    final casteGroup = casteGroups
        .where((group) => group.id == _religionId)
        .firstOrNull;
    final dependentCasteIds = casteGroup?.dependentCasteIds ?? const [];
    if (dependentCasteIds.isNotEmpty) {
      final allowedIds = dependentCasteIds.toSet();
      return castes
          .where((caste) => allowedIds.contains(caste.id))
          .toList(growable: false);
    }

    return castes
        .where((caste) => caste.parentId == _religionId)
        .toList(growable: false);
  }

  List<LookupItem> _subcastesForSelection(List<LookupItem> subcastes) {
    if (_casteId == null) return const [];
    return subcastes
        .where((subcaste) => subcaste.parentId == _casteId)
        .toList(growable: false);
  }

  List<LookupItem> _kulamsForSelection(List<LookupItem> kulams) {
    if (_subcasteId == null) return const [];
    return kulams
        .where((kulam) => kulam.parentId == _subcasteId)
        .toList(growable: false);
  }

  String _casteDisabledValue(List<LookupItem> sects, AppLocalizations loc) {
    if (_religionId == null) return loc.t('selectReligionFirst');
    if (_sectsForSelection(sects).isNotEmpty && _sectId == null) {
      return loc.t('selectSectFirst');
    }
    return loc.t('noCastesFound');
  }

  List<LookupItem> _statesForCountry(List<LookupItem> states) {
    if (_countryId == null) return const [];
    return states
        .where(
          (state) =>
              state.countryCode == null || state.countryCode == _countryId,
        )
        .toList(growable: false);
  }

  List<LookupItem> _citiesForSelection(List<LookupItem> cities) {
    if (_countryId == null) return const [];
    return cities
        .where((city) {
          final matchesCountry =
              city.countryCode == null || city.countryCode == _countryId;
          final matchesState =
              _stateId == null ||
              city.stateId == null ||
              city.stateId == _stateId;
          return matchesCountry && matchesState;
        })
        .toList(growable: false);
  }

  void _checkPhoneAvailability(String? value) {
    if (value == null || value.trim().isEmpty) {
      setState(() {
        _phoneAvailable = null;
        _checkingPhone = false;
      });
      return;
    }

    // Debounce - only check if we have a valid looking phone number
    if (value.trim().length < 10) {
      setState(() {
        _phoneAvailable = null;
        _checkingPhone = false;
      });
      return;
    }

    setState(() => _checkingPhone = true);

    // Use a small delay to debounce rapid typing
    Future.delayed(const Duration(milliseconds: 500), () async {
      // Check if the value has changed since we started
      if (value != _phone.text.trim()) {
        setState(() => _checkingPhone = false);
        return;
      }

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.checkAvailability(phone: value.trim());

      if (mounted) {
        setState(() {
          _phoneAvailable = result.phone;
          _checkingPhone = false;
        });
      }
    });
  }

  void _checkEmailAvailability(String? value) {
    if (value == null || value.trim().isEmpty) {
      setState(() {
        _emailAvailable = null;
        _checkingEmail = false;
      });
      return;
    }

    // Only check if it looks like a valid email
    if (!value.contains('@') || !value.contains('.')) {
      setState(() {
        _emailAvailable = null;
        _checkingEmail = false;
      });
      return;
    }

    setState(() => _checkingEmail = true);

    // Use a small delay to debounce rapid typing
    Future.delayed(const Duration(milliseconds: 500), () async {
      // Check if the value has changed since we started
      if (value != _email.text.trim()) {
        setState(() => _checkingEmail = false);
        return;
      }

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.checkAvailability(email: value.trim());

      if (mounted) {
        setState(() {
          _emailAvailable = result.email;
          _checkingEmail = false;
        });
      }
    });
  }
}

class _ProfileStep {
  const _ProfileStep(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.steps});

  final int step;
  final List<_ProfileStep> steps;

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / steps.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  steps[step].title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${step + 1}/${steps.length}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            steps[step].subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepSurface extends StatelessWidget {
  const _StepSurface({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        minLines: minLines,
        maxLines: obscureText ? 1 : maxLines,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _PillSelector<T> extends StatelessWidget {
  const _PillSelector({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelBuilder,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((item) {
              final selected = item == value;
              return ChoiceChip(
                label: Text(labelBuilder?.call(item) ?? item.toString()),
                selected: selected,
                onSelected: (_) => onChanged(item),
                showCheckmark: false,
                avatar: selected
                    ? const Icon(CupertinoIcons.check_mark, size: 15)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PhotoSelectionPanel extends StatelessWidget {
  const _PhotoSelectionPanel({
    required this.files,
    required this.onPick,
    required this.onRemove,
  });

  final List<XFile> files;
  final VoidCallback onPick;
  final ValueChanged<XFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onPick,
          icon: const Icon(CupertinoIcons.photo_on_rectangle),
          label: Text(files.isEmpty ? 'Choose photos' : 'Change photos'),
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Text(
              'At least one profile picture is required to create the account.',
            ),
          )
        else
          ...files.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(file.name),
                subtitle: Text(index == 0 ? 'Primary photo' : 'Profile photo'),
                trailing: IconButton(
                  tooltip: 'Remove photo',
                  onPressed: () => onRemove(file),
                  icon: const Icon(CupertinoIcons.trash),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(CupertinoIcons.chevron_down),
          ),
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}

class _LookupActionField extends StatelessWidget {
  const _LookupActionField({
    required this.label,
    required this.valueId,
    required this.items,
    required this.onChanged,
    this.disabledValue,
  });

  final String label;
  final int? valueId;
  final List<LookupItem> items;
  final ValueChanged<int?> onChanged;
  final String? disabledValue;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final selected = valueId == null
        ? null
        : items.where((item) => item.id == valueId).firstOrNull;
    final enabled = items.isNotEmpty;
    return _ActionField(
      label: label,
      value:
          selected?.name ??
          (enabled
              ? loc.selectOrTypeToSearch
              : disabledValue ?? loc.noOptionsFound),
      icon: CupertinoIcons.search,
      onTap: enabled
          ? () async {
              final picked = await showModalBottomSheet<LookupItem>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _LookupPickerSheet(title: label, items: items),
              );
              if (picked != null) onChanged(picked.id);
            }
          : null,
    );
  }
}

class _LookupPickerSheet extends StatefulWidget {
  const _LookupPickerSheet({required this.title, required this.items});

  final String title;
  final List<LookupItem> items;

  @override
  State<_LookupPickerSheet> createState() => _LookupPickerSheetState();
}

class _LookupPickerSheetState extends State<_LookupPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
        .take(80)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoSearchTextField(
                      controller: _search,
                      placeholder: AppLocalizations.of(context).typeToSearch,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      title: Text(item.name),
                      trailing: const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 18,
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.profileFor,
    required this.gender,
    required this.maritalStatus,
    required this.motherTongue,
    required this.religion,
    required this.sect,
    required this.caste,
    required this.subcaste,
    required this.kulam,
    required this.weight,
    required this.city,
    required this.education,
    required this.occupation,
    required this.employedIn,
    required this.matrimonyMode,
    required this.photoCount,
    required this.loc,
  });

  final String name;
  final String phone;
  final String email;
  final DateTime? dob;
  final String profileFor;
  final String gender;
  final String maritalStatus;
  final String motherTongue;
  final String religion;
  final String sect;
  final String caste;
  final String subcaste;
  final String kulam;
  final String weight;
  final String city;
  final String education;
  final String occupation;
  final String employedIn;
  final String matrimonyMode;
  final int photoCount;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('reviewProfileTitle'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.t('reviewProfileSubtitle'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              _ReviewRow(loc.t('name'), name.isEmpty ? loc.notEntered : name),
              _ReviewRow(
                loc.t('phone'),
                phone.isEmpty ? loc.notEntered : phone,
              ),
              _ReviewRow(loc.t('email'), email.isEmpty ? loc.notAdded : email),
              _ReviewRow(
                loc.t('dateOfBirth'),
                dob == null ? loc.notSelected : DateFormat.yMMMd().format(dob!),
              ),
              _ReviewRow(loc.t('profileFor'), loc.choice(profileFor)),
              _ReviewRow(loc.t('gender'), loc.choice(gender)),
              _ReviewRow(loc.t('maritalStatus'), loc.choice(maritalStatus)),
              _ReviewRow(loc.t('motherTongue'), motherTongue),
              _ReviewRow(loc.t('religion'), religion),
              if (sect != loc.notSelected) _ReviewRow(loc.t('sect'), sect),
              _ReviewRow(loc.t('caste'), caste),
              if (subcaste != loc.notSelected)
                _ReviewRow(loc.t('subcaste'), subcaste),
              if (kulam != loc.notSelected) _ReviewRow(loc.t('kulam'), kulam),
              _ReviewRow(
                loc.t('weight'),
                weight.trim().isEmpty ? loc.notEntered : weight,
              ),
              _ReviewRow(loc.t('city'), city),
              _ReviewRow(loc.t('education'), education),
              _ReviewRow(loc.t('occupation'), occupation),
              _ReviewRow(loc.t('employedIn'), employedIn),
              _ReviewRow(loc.t('matrimonyMode'), matrimonyMode),
              _ReviewRow('Photos', '$photoCount selected'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLast,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isLast;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: loc.back,
              onPressed: isLoading ? null : onBack,
              icon: const Icon(CupertinoIcons.chevron_back),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isLoading ? null : (isLast ? onSubmit : onNext),
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isLast ? loc.createProfile : loc.continueText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 34),
              const SizedBox(height: 12),
              Text(
                loc.t('couldNotLoadProfileOptions'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
