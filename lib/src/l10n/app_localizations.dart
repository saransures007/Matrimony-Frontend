import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLocale { en, ta }

extension AppLocaleExtension on AppLocale {
  String get code => switch (this) {
    AppLocale.en => 'en',
    AppLocale.ta => 'ta',
  };

  String get name => switch (this) {
    AppLocale.en => 'English',
    AppLocale.ta => 'தமிழ்',
  };

  Locale get locale => Locale(code);
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final supportedLocales = AppLocale.values
      .map((locale) => locale.locale)
      .toList(growable: false);

  String t(String key) {
    final languageCode = locale.languageCode;
    return _localizedValues[languageCode]?[key] ??
        _localizedValues[AppLocale.en.code]?[key] ??
        key;
  }

  String enterOtpSent(String number) =>
      t('enterOtpSent').replaceFirst('{number}', number);
  String couldNotLoadLookupData(Object error) =>
      t('couldNotLoadLookupData').replaceFirst('{error}', error.toString());

  String choice(String value) => t('choice.$value');

  String get ok => t('ok');
  String get cancel => t('cancel');
  String get save => t('save');
  String get loading => t('loading');
  String get error => t('error');
  String get retry => t('retry');
  String get appName => t('appName');
  String get account => t('account');
  String get search => t('search');
  String get messages => t('messages');
  String get signOut => t('signOut');
  String get userProfile => t('userProfile');
  String get authenticatedSession => t('authenticatedSession');
  String get verification => t('verification');
  String get verificationSubtitle => t('verificationSubtitle');
  String get privacyControls => t('privacyControls');
  String get privacyControlsSubtitle => t('privacyControlsSubtitle');
  String get subscription => t('subscription');
  String get subscriptionSubtitle => t('subscriptionSubtitle');
  String get matchIntelligence => t('matchIntelligence');
  String get matchIntelligenceSubtitle => t('matchIntelligenceSubtitle');
  String get appTheme => t('appTheme');
  String get appThemeSubtitle => t('appThemeSubtitle');
  String get lightMode => t('lightMode');
  String get darkMode => t('darkMode');
  String get systemDefault => t('systemDefault');
  String get language => t('language');
  String get languageSubtitle => t('languageSubtitle');
  String get emailPhoneUsername => t('emailPhoneUsername');
  String get password => t('password');
  String get signIn => t('signIn');
  String get createAccount => t('createAccount');
  String get loginWithOtpInstead => t('loginWithOtpInstead');
  String get loginWithPasswordInstead => t('loginWithPasswordInstead');
  String get enterLoginId => t('enterLoginId');
  String get passwordMinLength => t('passwordMinLength');
  String get mobileNumber => t('mobileNumber');
  String get phoneNumber => t('phoneNumber');
  String get enterMobileNumber => t('enterMobileNumber');
  String get enterValidPhone => t('enterValidPhone');
  String get phoneRequired => t('phoneRequired');
  String get sendOtp => t('sendOtp');
  String get verifyLogin => t('verifyLogin');
  String get enterCompleteOtp => t('enterCompleteOtp');
  String get changePhoneNumber => t('changePhoneNumber');
  String get otpLogin => t('otpLogin');
  String get secureOtpLogin => t('secureOtpLogin');
  String get otpLoginSubtitle => t('otpLoginSubtitle');
  String get discoverMatches => t('discoverMatches');
  String get matchesInYourMode => t('matchesInYourMode');
  String get couldNotLoadMatches => t('couldNotLoadMatches');
  String get noMatchesYet => t('noMatchesYet');
  String get noMatchesSubtitle => t('noMatchesSubtitle');
  String get supportVerification => t('supportVerification');
  String get supportVerificationText => t('supportVerificationText');
  String get matchRequest => t('matchRequest');
  String get matchRequestText => t('matchRequestText');
  String get messagesReadyText => t('messagesReadyText');
  String get back => t('back');
  String get continueText => t('continue');
  String get createProfile => t('createProfile');
  String get pleaseCompleteStep => t('pleaseCompleteStep');
  String get pleaseCompleteDetails => t('pleaseCompleteDetails');
  String get notSelected => t('notSelected');
  String get notEntered => t('notEntered');
  String get notAdded => t('notAdded');
  String get chooseDate => t('chooseDate');
  String get selectOrTypeToSearch => t('selectOrTypeToSearch');
  String get noOptionsFound => t('noOptionsFound');
  String get typeToSearch => t('typeToSearch');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocale.values.any(
      (supported) => supported.code == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final supportedLocale = AppLocale.values.firstWhere(
      (supported) => supported.code == locale.languageCode,
      orElse: () => AppLocale.en,
    );
    return AppLocalizations(supportedLocale.locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

final localeProvider = StateProvider<AppLocale>((ref) => AppLocale.en);

final localizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale.locale);
});

const _localizedValues = <String, Map<String, String>>{
  'en': {
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'appName': 'SKS Matrimony',
    'account': 'Account',
    'search': 'Search',
    'messages': 'Messages',
    'signOut': 'Sign out',
    'userProfile': 'User profile',
    'authenticatedSession': 'Authenticated session stored securely on device',
    'verification': 'Verification',
    'verificationSubtitle': 'Identity, phone, education, and occupation checks',
    'privacyControls': 'Privacy controls',
    'privacyControlsSubtitle':
        'Photo visibility, contact permissions, and blocked profiles',
    'subscription': 'Subscription',
    'subscriptionSubtitle': 'Paid contact unlocks, boosts, and premium filters',
    'matchIntelligence': 'Match intelligence',
    'matchIntelligenceSubtitle':
        'Ranking, horoscope matching, and fraud-risk signals',
    'appTheme': 'App Theme',
    'appThemeSubtitle': 'Light, Dark or System default mode',
    'lightMode': 'Light Mode',
    'darkMode': 'Dark Mode',
    'systemDefault': 'System Default',
    'language': 'Language',
    'languageSubtitle': 'Choose your preferred language',
    'emailPhoneUsername': 'Email, phone, or username',
    'password': 'Password',
    'signIn': 'Sign in',
    'createAccount': 'Create account',
    'loginWithOtpInstead': 'Login with OTP instead',
    'loginWithPasswordInstead': 'Login with Password instead',
    'enterLoginId': 'Enter your login id',
    'passwordMinLength': 'Password must be at least 6 characters',
    'mobileNumber': 'Mobile Number',
    'phoneNumber': 'Phone Number',
    'enterMobileNumber': 'Enter your mobile number',
    'enterValidPhone': 'Enter a valid 10-digit phone number',
    'phoneRequired': 'Phone number is required',
    'sendOtp': 'Send OTP',
    'verifyLogin': 'Verify & Login',
    'enterCompleteOtp': 'Please enter complete 6-digit OTP',
    'enterOtpSent': 'Enter the 6-digit OTP sent to +91 {number}',
    'changePhoneNumber': 'Change phone number',
    'otpLogin': 'OTP Login',
    'secureOtpLogin': 'Secure OTP Login',
    'otpLoginSubtitle':
        'Enter your phone number to receive a one-time password',
    'discoverMatches': 'Discover matches',
    'matchesInYourMode': 'Matches in your mode',
    'couldNotLoadLookupData': 'Could not load lookup data: {error}',
    'couldNotLoadMatches': 'Could not load matches',
    'noMatchesYet': 'No matches yet',
    'noMatchesSubtitle':
        'Matches will appear here once other profiles join your matrimony mode.',
    'supportVerification': 'Support verification',
    'supportVerificationText':
        'Upload ID verification to unlock trusted badges.',
    'matchRequest': 'Match request',
    'matchRequestText': 'Interests and chat threads will appear here.',
    'messagesReadyText':
        'Realtime chat should use Socket.io with room-level authorization, delivery receipts, media scanning, and encrypted transport. The UI is ready for the messaging module once backend socket events are exposed.',
    'back': 'Back',
    'continue': 'Continue',
    'createProfile': 'Create profile',
    'pleaseCompleteStep': 'Please complete the required details in this step.',
    'pleaseCompleteDetails': 'Please complete the required details.',
    'notSelected': 'Not selected',
    'notEntered': 'Not entered',
    'notAdded': 'Not added',
    'chooseDate': 'Choose date',
    'selectOrTypeToSearch': 'Select or type to search',
    'noOptionsFound': 'No options found',
    'typeToSearch': 'Type to search',
    'stepAccountSubtitle': 'Secure login details',
    'basics': 'Basics',
    'stepBasicsSubtitle': 'Personal identity',
    'location': 'Location',
    'stepLocationSubtitle': 'Where matches can find you',
    'career': 'Career',
    'stepCareerSubtitle': 'Education and work',
    'mode': 'Mode',
    'stepModeSubtitle': 'Choose your matrimony type',
    'review': 'Review',
    'stepReviewSubtitle': 'Confirm and create',
    'secureAccessTitle': 'Start with secure access',
    'secureAccessSubtitle': 'Your phone is used for login and account safety.',
    'phoneAlreadyRegistered': 'This phone number is already registered',
    'email': 'Email',
    'optionalRecommended': 'Optional, but recommended',
    'enterValidEmail': 'Enter a valid email',
    'emailAlreadyRegistered': 'This email is already registered',
    'minimumSixCharacters': 'Minimum 6 characters',
    'profileBasicsTitle': 'Tell us about the profile',
    'profileBasicsSubtitle': 'These basics help us recommend relevant matches.',
    'fullName': 'Full name',
    'nameShownOnProfile': 'Name shown on profile',
    'fullNameRequired': 'Full name is required',
    'profileCreatedFor': 'Profile created for',
    'profileFor': 'Profile for',
    'gender': 'Gender',
    'maritalStatus': 'Marital status',
    'dateOfBirth': 'Date of birth',
    'motherTongue': 'Mother tongue',
    'religion': 'Religion',
    'sect': 'Sect',
    'caste': 'Caste',
    'subcaste': 'Subcaste',
    'kulam': 'Kulam',
    'height': 'Height',
    'weight': 'Weight',
    'enterWeightKg': 'Enter weight in kg',
    'enterValidWeight': 'Enter a valid weight',
    'selectReligionFirst': 'Select religion first',
    'selectSectFirst': 'Select sect first',
    'selectCasteFirst': 'Select caste first',
    'selectSubcasteFirst': 'Select subcaste first',
    'noSectsFound': 'No sects found',
    'noCastesFound': 'No castes found',
    'noSubcastesFound': 'No subcastes found',
    'noKulamsFound': 'No kulams found',
    'locationTitle': 'Set location preferences',
    'locationSubtitle':
        'Location powers nearby discovery and family search filters.',
    'country': 'Country',
    'state': 'State',
    'city': 'City',
    'selectCountryFirst': 'Select country first',
    'noStatesFound': 'No states found',
    'noCitiesFound': 'No cities found',
    'careerTitle': 'Add education and work',
    'careerSubtitle':
        'Premium filters use these details to improve match quality.',
    'education': 'Education',
    'occupation': 'Occupation',
    'employedIn': 'Employed in',
    'expectedSalary': 'Expected salary',
    'aboutProfile': 'About profile',
    'aboutProfileHint': 'A short, genuine introduction',
    'matrimonyModeTitle': 'Choose your matrimony mode',
    'matrimonyModeSubtitle':
        'Select the type of matrimony service that fits your preference.',
    'matrimonyMode': 'Matrimony mode',
    'noMatrimonyModesAvailable': 'No matrimony modes available',
    'reviewProfileTitle': 'Review your profile',
    'reviewProfileSubtitle':
        'You can go back and edit anything before creating the account.',
    'name': 'Name',
    'phone': 'Phone',
    'couldNotLoadProfileOptions': 'Could not load profile options',
    'choice.Self': 'Self',
    'choice.Son': 'Son',
    'choice.Daughter': 'Daughter',
    'choice.Brother': 'Brother',
    'choice.Sister': 'Sister',
    'choice.Relative': 'Relative',
    'choice.Friend': 'Friend',
    'choice.Male': 'Male',
    'choice.Female': 'Female',
    'choice.Other': 'Other',
    'choice.Single': 'Single',
    'choice.Divorced': 'Divorced',
    'choice.Separated': 'Separated',
    'choice.Widowed': 'Widowed',
  },
  'ta': {
    'ok': 'சரி',
    'cancel': 'ரத்து செய்',
    'save': 'சேமி',
    'loading': 'ஏற்றப்படுகிறது...',
    'error': 'பிழை',
    'retry': 'மீண்டும் முயற்சி',
    'appName': 'SKS திருமணத் துணை',
    'account': 'கணக்கு',
    'search': 'தேடல்',
    'messages': 'செய்திகள்',
    'signOut': 'வெளியேறு',
    'userProfile': 'பயனர் சுயவிவரம்',
    'authenticatedSession':
        'அங்கீகரிக்கப்பட்ட அமர்வு சாதனத்தில் பாதுகாப்பாக சேமிக்கப்பட்டுள்ளது',
    'verification': 'சரிபார்ப்பு',
    'verificationSubtitle':
        'அடையாளம், தொலைபேசி, கல்வி மற்றும் தொழில் சரிபார்ப்புகள்',
    'privacyControls': 'தனியுரிமை கட்டுப்பாடுகள்',
    'privacyControlsSubtitle':
        'புகைப்படக் காட்சி, தொடர்பு அனுமதிகள் மற்றும் தடுக்கப்பட்ட சுயவிவரங்கள்',
    'subscription': 'சந்தா',
    'subscriptionSubtitle':
        'கட்டண தொடர்பு திறப்பு, பூஸ்ட் மற்றும் பிரீமியம் வடிகட்டிகள்',
    'matchIntelligence': 'பொருத்த அறிவு',
    'matchIntelligenceSubtitle':
        'தரவரிசை, ஜாதகப் பொருத்தம் மற்றும் மோசடி அபாய அறிகுறிகள்',
    'appTheme': 'செயலி தீம்',
    'appThemeSubtitle': 'லைட், டார்க் அல்லது கணினி இயல்புநிலை',
    'lightMode': 'லைட் முறை',
    'darkMode': 'டார்க் முறை',
    'systemDefault': 'கணினி இயல்புநிலை',
    'language': 'மொழி',
    'languageSubtitle': 'உங்கள் விருப்ப மொழியைத் தேர்ந்தெடுக்கவும்',
    'emailPhoneUsername': 'மின்னஞ்சல், தொலைபேசி அல்லது பயனர்பெயர்',
    'password': 'கடவுச்சொல்',
    'signIn': 'உள்நுழை',
    'createAccount': 'கணக்கு உருவாக்கு',
    'loginWithOtpInstead': 'OTP மூலம் உள்நுழை',
    'loginWithPasswordInstead': 'கடவுச்சொல் மூலம் உள்நுழை',
    'enterLoginId': 'உங்கள் உள்நுழைவு ஐடியை உள்ளிடவும்',
    'passwordMinLength': 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்',
    'mobileNumber': 'மொபைல் எண்',
    'phoneNumber': 'தொலைபேசி எண்',
    'enterMobileNumber': 'உங்கள் மொபைல் எண்ணை உள்ளிடவும்',
    'enterValidPhone': 'சரியான 10 இலக்க தொலைபேசி எண்ணை உள்ளிடவும்',
    'phoneRequired': 'தொலைபேசி எண் அவசியம்',
    'sendOtp': 'OTP அனுப்பு',
    'verifyLogin': 'சரிபார்த்து உள்நுழை',
    'enterCompleteOtp': 'முழு 6 இலக்க OTP-ஐ உள்ளிடவும்',
    'enterOtpSent': '+91 {number} எண்ணுக்கு அனுப்பிய 6 இலக்க OTP-ஐ உள்ளிடவும்',
    'changePhoneNumber': 'தொலைபேசி எண்ணை மாற்று',
    'otpLogin': 'OTP உள்நுழைவு',
    'secureOtpLogin': 'பாதுகாப்பான OTP உள்நுழைவு',
    'otpLoginSubtitle':
        'ஒருமுறை பயன்படுத்தும் கடவுச்சொல்லைப் பெற உங்கள் தொலைபேசி எண்ணை உள்ளிடவும்',
    'discoverMatches': 'பொருத்தங்களை கண்டறி',
    'matchesInYourMode': 'உங்கள் முறையிலான பொருத்தங்கள்',
    'couldNotLoadLookupData': 'தேர்வு தரவை ஏற்ற முடியவில்லை: {error}',
    'couldNotLoadMatches': 'பொருத்தங்களை ஏற்ற முடியவில்லை',
    'noMatchesYet': 'இன்னும் பொருத்தங்கள் இல்லை',
    'noMatchesSubtitle':
        'உங்கள் திருமண முறையில் மற்ற சுயவிவரங்கள் சேர்ந்ததும் பொருத்தங்கள் இங்கே தோன்றும்.',
    'supportVerification': 'சரிபார்ப்பு உதவி',
    'supportVerificationText':
        'நம்பகமான பதக்கங்களைத் திறக்க அடையாளச் சரிபார்ப்பை பதிவேற்றவும்.',
    'matchRequest': 'பொருத்த கோரிக்கை',
    'matchRequestText': 'விருப்பங்கள் மற்றும் உரையாடல்கள் இங்கே தோன்றும்.',
    'messagesReadyText':
        'நேரடி அரட்டைக்கு Socket.io, அறை அளவிலான அனுமதி, விநியோக ரசீதுகள், மீடியா ஸ்கேனிங் மற்றும் குறியாக்கப்பட்ட போக்குவரத்து தேவை. backend socket events கிடைத்ததும் UI தயாராக உள்ளது.',
    'back': 'பின்',
    'continue': 'தொடர்க',
    'createProfile': 'சுயவிவரம் உருவாக்கு',
    'pleaseCompleteStep': 'இந்த படியில் தேவையான விவரங்களை நிரப்பவும்.',
    'pleaseCompleteDetails': 'தேவையான விவரங்களை நிரப்பவும்.',
    'notSelected': 'தேர்ந்தெடுக்கப்படவில்லை',
    'notEntered': 'உள்ளிடப்படவில்லை',
    'notAdded': 'சேர்க்கப்படவில்லை',
    'chooseDate': 'தேதியைத் தேர்ந்தெடு',
    'selectOrTypeToSearch': 'தேட தேர்ந்தெடுக்கவும் அல்லது தட்டச்சு செய்யவும்',
    'noOptionsFound': 'விருப்பங்கள் இல்லை',
    'typeToSearch': 'தேட தட்டச்சு செய்யவும்',
    'stepAccountSubtitle': 'பாதுகாப்பான உள்நுழைவு விவரங்கள்',
    'basics': 'அடிப்படை',
    'stepBasicsSubtitle': 'தனிப்பட்ட அடையாளம்',
    'location': 'இடம்',
    'stepLocationSubtitle': 'பொருத்தங்கள் உங்களை கண்டுபிடிக்கும் இடம்',
    'career': 'தொழில்',
    'stepCareerSubtitle': 'கல்வி மற்றும் வேலை',
    'mode': 'முறை',
    'stepModeSubtitle': 'உங்கள் திருமண வகையைத் தேர்ந்தெடுக்கவும்',
    'review': 'சரிபார்',
    'stepReviewSubtitle': 'உறுதிசெய்து உருவாக்கு',
    'secureAccessTitle': 'பாதுகாப்பான அணுகலுடன் தொடங்குங்கள்',
    'secureAccessSubtitle':
        'உள்நுழைவு மற்றும் கணக்கு பாதுகாப்பிற்கு உங்கள் தொலைபேசி பயன்படுத்தப்படும்.',
    'phoneAlreadyRegistered':
        'இந்த தொலைபேசி எண் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது',
    'email': 'மின்னஞ்சல்',
    'optionalRecommended': 'விருப்பம், ஆனால் பரிந்துரைக்கப்படுகிறது',
    'enterValidEmail': 'சரியான மின்னஞ்சலை உள்ளிடவும்',
    'emailAlreadyRegistered': 'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது',
    'minimumSixCharacters': 'குறைந்தது 6 எழுத்துகள்',
    'profileBasicsTitle': 'சுயவிவரத்தைப் பற்றி சொல்லுங்கள்',
    'profileBasicsSubtitle':
        'இந்த அடிப்படை விவரங்கள் பொருத்தமான பொருத்தங்களை பரிந்துரைக்க உதவும்.',
    'fullName': 'முழு பெயர்',
    'nameShownOnProfile': 'சுயவிவரத்தில் காட்டப்படும் பெயர்',
    'fullNameRequired': 'முழு பெயர் அவசியம்',
    'profileCreatedFor': 'சுயவிவரம் உருவாக்கப்பட்டது',
    'profileFor': 'சுயவிவரம் யாருக்காக',
    'gender': 'பாலினம்',
    'maritalStatus': 'திருமண நிலை',
    'dateOfBirth': 'பிறந்த தேதி',
    'motherTongue': 'தாய் மொழி',
    'religion': 'மதம்',
    'sect': 'பிரிவு',
    'caste': 'சாதி',
    'subcaste': 'உட்பிரிவு',
    'kulam': 'குலம்',
    'height': 'உயரம்',
    'weight': 'எடை',
    'enterWeightKg': 'எடையை கிலோவில் உள்ளிடவும்',
    'enterValidWeight': 'சரியான எடையை உள்ளிடவும்',
    'selectReligionFirst': 'முதலில் மதத்தைத் தேர்ந்தெடுக்கவும்',
    'selectSectFirst': 'முதலில் பிரிவைத் தேர்ந்தெடுக்கவும்',
    'selectCasteFirst': 'முதலில் சாதியைத் தேர்ந்தெடுக்கவும்',
    'selectSubcasteFirst': 'முதலில் உட்பிரிவைத் தேர்ந்தெடுக்கவும்',
    'noSectsFound': 'பிரிவுகள் இல்லை',
    'noCastesFound': 'சாதிகள் இல்லை',
    'noSubcastesFound': 'உட்பிரிவுகள் இல்லை',
    'noKulamsFound': 'குலங்கள் இல்லை',
    'locationTitle': 'இட விருப்பங்களை அமைக்கவும்',
    'locationSubtitle':
        'அருகிலுள்ள தேடல் மற்றும் குடும்ப தேடல் வடிகட்டிகளுக்கு இடம் உதவும்.',
    'country': 'நாடு',
    'state': 'மாநிலம்',
    'city': 'நகரம்',
    'selectCountryFirst': 'முதலில் நாட்டைத் தேர்ந்தெடுக்கவும்',
    'noStatesFound': 'மாநிலங்கள் இல்லை',
    'noCitiesFound': 'நகரங்கள் இல்லை',
    'careerTitle': 'கல்வி மற்றும் வேலை சேர்க்கவும்',
    'careerSubtitle': 'இந்த விவரங்கள் பொருத்தத் தரத்தை மேம்படுத்த உதவும்.',
    'education': 'கல்வி',
    'occupation': 'தொழில்',
    'employedIn': 'வேலை வகை',
    'expectedSalary': 'எதிர்பார்க்கும் சம்பளம்',
    'aboutProfile': 'சுயவிவரம் பற்றி',
    'aboutProfileHint': 'சுருக்கமான உண்மையான அறிமுகம்',
    'matrimonyModeTitle': 'திருமண முறையைத் தேர்ந்தெடுக்கவும்',
    'matrimonyModeSubtitle':
        'உங்களுக்கு பொருந்தும் திருமண சேவை வகையைத் தேர்ந்தெடுக்கவும்.',
    'matrimonyMode': 'திருமண முறை',
    'noMatrimonyModesAvailable': 'திருமண முறைகள் இல்லை',
    'reviewProfileTitle': 'உங்கள் சுயவிவரத்தை சரிபார்க்கவும்',
    'reviewProfileSubtitle':
        'கணக்கை உருவாக்குவதற்கு முன் திரும்பிச் சென்று எதையும் திருத்தலாம்.',
    'name': 'பெயர்',
    'phone': 'தொலைபேசி',
    'couldNotLoadProfileOptions': 'சுயவிவர விருப்பங்களை ஏற்ற முடியவில்லை',
    'choice.Self': 'நான்',
    'choice.Son': 'மகன்',
    'choice.Daughter': 'மகள்',
    'choice.Brother': 'சகோதரர்',
    'choice.Sister': 'சகோதரி',
    'choice.Relative': 'உறவினர்',
    'choice.Friend': 'நண்பர்',
    'choice.Male': 'ஆண்',
    'choice.Female': 'பெண்',
    'choice.Other': 'மற்றவை',
    'choice.Single': 'திருமணம் ஆகாதவர்',
    'choice.Divorced': 'விவாகரத்து',
    'choice.Separated': 'பிரிந்து வாழ்கிறார்',
    'choice.Widowed': 'துணையை இழந்தவர்',
  },
};
