import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Planten'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your AI Crop Doctor'**
  String get appTagline;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get enterConfirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link.'**
  String get resetPasswordInstructions;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetEmailSent;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get enterPhoneNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify & Proceed'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resendOtpIn(Object seconds);

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get invalidOtp;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile'**
  String get profileSetupTitle;

  /// No description provided for @farmerName.
  ///
  /// In en, this message translates to:
  /// **'Farmer Name'**
  String get farmerName;

  /// No description provided for @enterFarmerName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFarmerName;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @enterVillage.
  ///
  /// In en, this message translates to:
  /// **'Enter your village name'**
  String get enterVillage;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @enterDistrict.
  ///
  /// In en, this message translates to:
  /// **'Enter your district'**
  String get enterDistrict;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @enterState.
  ///
  /// In en, this message translates to:
  /// **'Enter your state'**
  String get enterState;

  /// No description provided for @primaryCrops.
  ///
  /// In en, this message translates to:
  /// **'Primary Crops Grown'**
  String get primaryCrops;

  /// No description provided for @photoBackupConsent.
  ///
  /// In en, this message translates to:
  /// **'Cloud Photo Backup (Optional)'**
  String get photoBackupConsent;

  /// No description provided for @photoBackupConsentDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow backing up leaf photos to cloud storage for model improvement.'**
  String get photoBackupConsentDesc;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @activeCrop.
  ///
  /// In en, this message translates to:
  /// **'Active Crop'**
  String get activeCrop;

  /// No description provided for @changeCrop.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeCrop;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Select Crop'**
  String get selectCrop;

  /// No description provided for @scanLeafCta.
  ///
  /// In en, this message translates to:
  /// **'Scan Leaf for Disease'**
  String get scanLeafCta;

  /// No description provided for @recentScans.
  ///
  /// In en, this message translates to:
  /// **'Recent Scans'**
  String get recentScans;

  /// No description provided for @noRecentScans.
  ///
  /// In en, this message translates to:
  /// **'No recent scans. Tap scan to diagnose your crop.'**
  String get noRecentScans;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Crop Leaf'**
  String get scanTitle;

  /// No description provided for @alignLeafGuide.
  ///
  /// In en, this message translates to:
  /// **'Align infected leaf inside the box'**
  String get alignLeafGuide;

  /// No description provided for @tapToCapture.
  ///
  /// In en, this message translates to:
  /// **'Tap shutter button to capture'**
  String get tapToCapture;

  /// No description provided for @galleryUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get galleryUpload;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @analyzeLeaf.
  ///
  /// In en, this message translates to:
  /// **'Analyze Leaf'**
  String get analyzeLeaf;

  /// No description provided for @photoTooDarkWarning.
  ///
  /// In en, this message translates to:
  /// **'Photo appears too dark. Please take photo in good daylight.'**
  String get photoTooDarkWarning;

  /// No description provided for @photoBlurWarning.
  ///
  /// In en, this message translates to:
  /// **'Photo appears blurry. Please hold camera steady.'**
  String get photoBlurWarning;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Result'**
  String get resultTitle;

  /// No description provided for @healthyPlant.
  ///
  /// In en, this message translates to:
  /// **'Healthy Plant'**
  String get healthyPlant;

  /// No description provided for @healthyPlantDesc.
  ///
  /// In en, this message translates to:
  /// **'No visible signs of disease, pest damage, or nutrient deficiency detected.'**
  String get healthyPlantDesc;

  /// No description provided for @likelyDisease.
  ///
  /// In en, this message translates to:
  /// **'Likely {diseaseName}'**
  String likelyDisease(Object diseaseName);

  /// No description provided for @possibleDisease.
  ///
  /// In en, this message translates to:
  /// **'Possible {diseaseName}'**
  String possibleDisease(Object diseaseName);

  /// No description provided for @uncertainDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Uncertain Diagnosis'**
  String get uncertainDiagnosis;

  /// No description provided for @uncertainDiagnosisNotice.
  ///
  /// In en, this message translates to:
  /// **'The app is uncertain about this leaf condition. Please do not apply chemicals blindly and consult a certified agriculture officer.'**
  String get uncertainDiagnosisNotice;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High Confidence'**
  String get confidenceHigh;

  /// No description provided for @confidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Confidence'**
  String get confidenceMedium;

  /// No description provided for @confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low Confidence'**
  String get confidenceLow;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low Severity'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Severity'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Severity'**
  String get severityHigh;

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsTitle;

  /// No description provided for @preventionTitle.
  ///
  /// In en, this message translates to:
  /// **'Preventive & Cultural Actions'**
  String get preventionTitle;

  /// No description provided for @safetyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Important Safety Disclaimer: Planten provides preventive farm support and never prescribes chemical dosages. Always consult a certified local Krishi Vigyan Kendra (KVK) or agriculture officer before applying chemical products.'**
  String get safetyDisclaimer;

  /// No description provided for @consultExpert.
  ///
  /// In en, this message translates to:
  /// **'Consult Agriculture Expert'**
  String get consultExpert;

  /// No description provided for @kisanCallCenter.
  ///
  /// In en, this message translates to:
  /// **'Kisan Call Center (Toll Free: 1800-180-1551)'**
  String get kisanCallCenter;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @saveToHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved to Scan History'**
  String get saveToHistory;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get historyTitle;

  /// No description provided for @allCrops.
  ///
  /// In en, this message translates to:
  /// **'All Crops'**
  String get allCrops;

  /// No description provided for @noHistoryForCrop.
  ///
  /// In en, this message translates to:
  /// **'No scans recorded yet for {cropName}.'**
  String noHistoryForCrop(Object cropName);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile'**
  String get profileTitle;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language Preference'**
  String get languagePreference;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @offlineModeActive.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode: AI diagnosis works without internet.'**
  String get offlineModeActive;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} scan(s) pending sync'**
  String syncPending(Object count);

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'All scans synced to cloud'**
  String get allSynced;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Legal Disclaimer & Advisory'**
  String get disclaimer;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Weather'**
  String get weatherToday;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @rainChance.
  ///
  /// In en, this message translates to:
  /// **'Rain Chance'**
  String get rainChance;

  /// No description provided for @weatherError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load weather'**
  String get weatherError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cachedWeather.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cachedWeather;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @weatherDetails.
  ///
  /// In en, this message translates to:
  /// **'Weather Details'**
  String get weatherDetails;

  /// No description provided for @sprayAdvisoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Farming Spray Advisory'**
  String get sprayAdvisoryTitle;

  /// No description provided for @sprayFavorable.
  ///
  /// In en, this message translates to:
  /// **'Favorable conditions for field work & spraying'**
  String get sprayFavorable;

  /// No description provided for @sprayUnfavorable.
  ///
  /// In en, this message translates to:
  /// **'Avoid spraying chemicals today (High rain/wind risk)'**
  String get sprayUnfavorable;

  /// No description provided for @sprayAdvisoryFavorableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wind < 20 km/h and low rain risk'**
  String get sprayAdvisoryFavorableSubtitle;

  /// No description provided for @sprayAdvisoryUnfavorableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High wind or rain may wash away chemicals'**
  String get sprayAdvisoryUnfavorableSubtitle;

  /// No description provided for @hourlyForecast.
  ///
  /// In en, this message translates to:
  /// **'24-Hour Forecast'**
  String get hourlyForecast;

  /// No description provided for @dailyForecast.
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get dailyForecast;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get feelsLike;

  /// No description provided for @daylight.
  ///
  /// In en, this message translates to:
  /// **'Daylight'**
  String get daylight;

  /// No description provided for @daytime.
  ///
  /// In en, this message translates to:
  /// **'Daytime'**
  String get daytime;

  /// No description provided for @nighttime.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get nighttime;

  /// No description provided for @uvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get uvIndex;

  /// No description provided for @minMax.
  ///
  /// In en, this message translates to:
  /// **'Min / Max'**
  String get minMax;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteScan.
  ///
  /// In en, this message translates to:
  /// **'Delete Scan'**
  String get deleteScan;

  /// No description provided for @deleteScanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this scan record?'**
  String get deleteScanConfirm;

  /// No description provided for @scanDeleted.
  ///
  /// In en, this message translates to:
  /// **'Scan deleted successfully'**
  String get scanDeleted;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear All History'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all scan history? This action cannot be undone.'**
  String get clearHistoryConfirm;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'All scan history cleared'**
  String get historyCleared;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer & Nutrition'**
  String get nutritionTitle;

  /// No description provided for @organicNutritionLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio & Organic Boost'**
  String get organicNutritionLabel;

  /// No description provided for @fertilizerClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Balanced Nutrients'**
  String get fertilizerClassLabel;

  /// No description provided for @dosageDisclaimerNote.
  ///
  /// In en, this message translates to:
  /// **'Always follow package instructions or expert guidance.'**
  String get dosageDisclaimerNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
