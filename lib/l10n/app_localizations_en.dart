// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Planten';

  @override
  String get appTagline => 'Your AI Crop Doctor';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get login => 'Login';

  @override
  String get loginTitle => 'Login';

  @override
  String get signupTitle => 'Create Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get enterEmail => 'Enter your email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get enterConfirmPassword => 'Re-enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'OR';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get createAccount => 'Create Account';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordInstructions =>
      'Enter your email to receive a password reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetEmailSent => 'Password reset link sent to your email.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneNumber => 'Enter 10-digit mobile number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyOtp => 'Verify & Proceed';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendOtpIn(Object seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get invalidPhoneNumber => 'Please enter a valid mobile number';

  @override
  String get invalidOtp => 'Please enter a valid 6-digit OTP';

  @override
  String get profileSetupTitle => 'Farmer Profile';

  @override
  String get farmerName => 'Farmer Name';

  @override
  String get enterFarmerName => 'Enter your full name';

  @override
  String get village => 'Village';

  @override
  String get enterVillage => 'Enter your village name';

  @override
  String get district => 'District';

  @override
  String get enterDistrict => 'Enter your district';

  @override
  String get state => 'State';

  @override
  String get enterState => 'Enter your state';

  @override
  String get primaryCrops => 'Primary Crops Grown';

  @override
  String get photoBackupConsent => 'Cloud Photo Backup (Optional)';

  @override
  String get photoBackupConsentDesc =>
      'Allow backing up leaf photos to cloud storage for model improvement.';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String get homeTitle => 'Home';

  @override
  String get activeCrop => 'Active Crop';

  @override
  String get changeCrop => 'Change';

  @override
  String get selectCrop => 'Select Crop';

  @override
  String get scanLeafCta => 'Scan Leaf for Disease';

  @override
  String get recentScans => 'Recent Scans';

  @override
  String get noRecentScans =>
      'No recent scans. Tap scan to diagnose your crop.';

  @override
  String get viewAll => 'View All';

  @override
  String get scanTitle => 'Scan Crop Leaf';

  @override
  String get alignLeafGuide => 'Align infected leaf inside the box';

  @override
  String get tapToCapture => 'Tap shutter button to capture';

  @override
  String get galleryUpload => 'Upload from Gallery';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get analyzeLeaf => 'Analyze Leaf';

  @override
  String get photoTooDarkWarning =>
      'Photo appears too dark. Please take photo in good daylight.';

  @override
  String get photoBlurWarning =>
      'Photo appears blurry. Please hold camera steady.';

  @override
  String get resultTitle => 'Diagnosis Result';

  @override
  String get healthyPlant => 'Healthy Plant';

  @override
  String get healthyPlantDesc =>
      'No visible signs of disease, pest damage, or nutrient deficiency detected.';

  @override
  String likelyDisease(Object diseaseName) {
    return 'Likely $diseaseName';
  }

  @override
  String possibleDisease(Object diseaseName) {
    return 'Possible $diseaseName';
  }

  @override
  String get uncertainDiagnosis => 'Uncertain Diagnosis';

  @override
  String get uncertainDiagnosisNotice =>
      'The app is uncertain about this leaf condition. Please do not apply chemicals blindly and consult a certified agriculture officer.';

  @override
  String get confidence => 'Confidence';

  @override
  String get confidenceHigh => 'High Confidence';

  @override
  String get confidenceMedium => 'Medium Confidence';

  @override
  String get confidenceLow => 'Low Confidence';

  @override
  String get severity => 'Severity';

  @override
  String get severityLow => 'Low Severity';

  @override
  String get severityMedium => 'Medium Severity';

  @override
  String get severityHigh => 'High Severity';

  @override
  String get symptomsTitle => 'Symptoms';

  @override
  String get preventionTitle => 'Preventive & Cultural Actions';

  @override
  String get safetyDisclaimer =>
      'Important Safety Disclaimer: Planten provides preventive farm support and never prescribes chemical dosages. Always consult a certified local Krishi Vigyan Kendra (KVK) or agriculture officer before applying chemical products.';

  @override
  String get consultExpert => 'Consult Agriculture Expert';

  @override
  String get kisanCallCenter => 'Kisan Call Center (Toll Free: 1800-180-1551)';

  @override
  String get callNow => 'Call Now';

  @override
  String get saveToHistory => 'Saved to Scan History';

  @override
  String get historyTitle => 'Scan History';

  @override
  String get allCrops => 'All Crops';

  @override
  String noHistoryForCrop(Object cropName) {
    return 'No scans recorded yet for $cropName.';
  }

  @override
  String get profileTitle => 'Farmer Profile';

  @override
  String get languagePreference => 'Language Preference';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get offlineModeActive =>
      'Offline Mode: AI diagnosis works without internet.';

  @override
  String syncPending(Object count) {
    return '$count scan(s) pending sync';
  }

  @override
  String get allSynced => 'All scans synced to cloud';

  @override
  String get disclaimer => 'Legal Disclaimer & Advisory';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get weatherToday => 'Today\'s Weather';

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get rainChance => 'Rain Chance';

  @override
  String get weatherError => 'Unable to load weather';

  @override
  String get retry => 'Retry';

  @override
  String get cachedWeather => 'Cached';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get weatherDetails => 'Weather Details';

  @override
  String get sprayAdvisoryTitle => 'Farming Spray Advisory';

  @override
  String get sprayFavorable => 'Favorable conditions for field work & spraying';

  @override
  String get sprayUnfavorable =>
      'Avoid spraying chemicals today (High rain/wind risk)';

  @override
  String get sprayAdvisoryFavorableSubtitle =>
      'Wind < 20 km/h and low rain risk';

  @override
  String get sprayAdvisoryUnfavorableSubtitle =>
      'High wind or rain may wash away chemicals';

  @override
  String get hourlyForecast => '24-Hour Forecast';

  @override
  String get dailyForecast => '7-Day Forecast';

  @override
  String get feelsLike => 'Feels like';

  @override
  String get daylight => 'Daylight';

  @override
  String get daytime => 'Daytime';

  @override
  String get nighttime => 'Night';

  @override
  String get uvIndex => 'UV Index';

  @override
  String get minMax => 'Min / Max';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteScan => 'Delete Scan';

  @override
  String get deleteScanConfirm =>
      'Are you sure you want to delete this scan record?';

  @override
  String get scanDeleted => 'Scan deleted successfully';

  @override
  String get clearHistory => 'Clear All History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to delete all scan history? This action cannot be undone.';

  @override
  String get historyCleared => 'All scan history cleared';

  @override
  String get nutritionTitle => 'Fertilizer & Nutrition';

  @override
  String get organicNutritionLabel => 'Bio & Organic Boost';

  @override
  String get fertilizerClassLabel => 'Balanced Nutrients';

  @override
  String get dosageDisclaimerNote =>
      'Always follow package instructions or expert guidance.';
}
