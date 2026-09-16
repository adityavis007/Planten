// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'प्लांटन';

  @override
  String get appTagline => 'आपका डिजिटल फसल डॉक्टर';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get loginTitle => 'लॉग इन करें';

  @override
  String get signupTitle => 'नया खाता बनाएं';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get enterEmail => 'अपना ईमेल पता दर्ज करें';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get enterPassword => 'अपना पासवर्ड दर्ज करें';

  @override
  String get confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get enterConfirmPassword => 'अपना पासवर्ड पुनः दर्ज करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get dontHaveAccount => 'खाता नहीं है? नया खाता बनाएं';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? लॉग इन करें';

  @override
  String get continueWithGoogle => 'गूगल के साथ जारी रखें';

  @override
  String get orDivider => 'या';

  @override
  String get invalidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खा रहे हैं';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get resetPasswordInstructions =>
      'पासवर्ड रीसेट लिंक प्राप्त करने के लिए अपना ईमेल दर्ज करें।';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get resetEmailSent =>
      'पासवर्ड रीसेट लिंक आपके ईमेल पर भेज दिया गया है।';

  @override
  String get phoneNumber => 'मोबाइल नंबर';

  @override
  String get enterPhoneNumber => '10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get sendOtp => 'ओटीपी भेजें';

  @override
  String get enterOtp => 'ओटीपी दर्ज करें';

  @override
  String get verifyOtp => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get resendOtp => 'ओटीपी पुनः भेजें';

  @override
  String resendOtpIn(Object seconds) {
    return '${seconds}s में ओटीपी पुनः भेजें';
  }

  @override
  String get invalidPhoneNumber =>
      'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें';

  @override
  String get invalidOtp => 'कृपया 6 अंकों का सही ओटीपी दर्ज करें';

  @override
  String get profileSetupTitle => 'किसान प्रोफाइल';

  @override
  String get farmerName => 'किसान का नाम';

  @override
  String get enterFarmerName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get village => 'गाँव';

  @override
  String get enterVillage => 'अपने गाँव का नाम दर्ज करें';

  @override
  String get district => 'ज़िला';

  @override
  String get enterDistrict => 'अपना ज़िला दर्ज करें';

  @override
  String get state => 'राज्य';

  @override
  String get enterState => 'अपना राज्य दर्ज करें';

  @override
  String get primaryCrops => 'मुख्य उगाई जाने वाली फसलें';

  @override
  String get photoBackupConsent => 'क्लाउड फोटो बैकअप (वैकल्पिक)';

  @override
  String get photoBackupConsentDesc =>
      'भविष्य में रोग पहचान को और बेहतर बनाने के लिए पत्तियों की तस्वीरें सुरक्षित क्लाउड में सहेजने की अनुमति दें।';

  @override
  String get saveAndContinue => 'सहेजें और आगे बढ़ें';

  @override
  String get homeTitle => 'होम';

  @override
  String get activeCrop => 'चुनी गई फसल';

  @override
  String get changeCrop => 'बदलें';

  @override
  String get selectCrop => 'अपनी फसल चुनें';

  @override
  String get scanLeafCta => 'रोग जांच के लिए पत्ती स्कैन करें';

  @override
  String get recentScans => 'हाल के स्कैन';

  @override
  String get noRecentScans =>
      'कोई हालिया स्कैन नहीं। अपनी फसल की जांच के लिए स्कैन बटन दबाएं।';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get scanTitle => 'पत्ती की फोटो लें';

  @override
  String get alignLeafGuide => 'प्रभावित पत्ती को चौखट के अंदर रखें';

  @override
  String get tapToCapture => 'फोटो लेने के लिए नीचे दिया गया बटन दबाएं';

  @override
  String get galleryUpload => 'गैलरी से फोटो चुनें';

  @override
  String get retakePhoto => 'साफ़ फोटो दोबारा लें';

  @override
  String get analyzeLeaf => 'रोग की जांच करें';

  @override
  String get photoTooDarkWarning =>
      'फोटो में रोशनी कम है। कृपया अच्छी धूप या उजाले में फोटो लें।';

  @override
  String get photoBlurWarning =>
      'फोटो धुंधली है। कृपया हाथ स्थिर रखकर दोबारा फोटो लें।';

  @override
  String get resultTitle => 'जांच परिणाम';

  @override
  String get healthyPlant => 'फसल स्वस्थ है';

  @override
  String get healthyPlantDesc =>
      'पौधे में किसी भी रोग, कीट या पोषक तत्व की कमी के लक्षण नहीं मिले हैं। फसल पूरी तरह हरी-भरी और स्वस्थ है।';

  @override
  String likelyDisease(Object diseaseName) {
    return 'संभावित रोग: $diseaseName';
  }

  @override
  String possibleDisease(Object diseaseName) {
    return 'यह रोग हो सकता है (पुष्टि आवश्यक): $diseaseName';
  }

  @override
  String get uncertainDiagnosis =>
      'निदान अनिश्चित — कृषि विशेषज्ञ से संपर्क करें';

  @override
  String get uncertainDiagnosisNotice =>
      'ऐप इस पत्ती के लक्षण की पहचान को लेकर पूरी तरह आश्वस्त नहीं है। अपनी फसल पर बिना सोचे-समझे रासायनिक दवा न डालें और सीधे कृषि विशेषज्ञ या कृषि केंद्र से संपर्क करें।';

  @override
  String get confidence => 'सटीकता';

  @override
  String get confidenceHigh => 'उच्च सटीकता';

  @override
  String get confidenceMedium => 'मध्यम सटीकता';

  @override
  String get confidenceLow => 'कम सटीकता';

  @override
  String get severity => 'गंभीरता';

  @override
  String get severityLow => 'कम गंभीरता';

  @override
  String get severityMedium => 'मध्यम गंभीरता';

  @override
  String get severityHigh => 'अधिक गंभीरता (तुरंत ध्यान दें)';

  @override
  String get symptomsTitle => 'लक्षण';

  @override
  String get preventionTitle => 'रोकथाम और देशी प्रबंधन के उपाय';

  @override
  String get safetyDisclaimer =>
      'महत्वपूर्ण सलाह: प्लांटन केवल वैज्ञानिक व देशी रोकथाम के उपाय सुझाता है और रासायनिक दवाओं की मात्रा नहीं बताता। कोई भी कीटनाशक डालने से पहले नजदीकी कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से सलाह लें।';

  @override
  String get consultExpert => 'कृषि अधिकारी से सलाह लें';

  @override
  String get kisanCallCenter => 'किसान कॉल सेंटर (टोल-फ्री: 1800-180-1551)';

  @override
  String get callNow => 'कॉल करें';

  @override
  String get saveToHistory => 'इतिहास में सुरक्षित किया गया';

  @override
  String get historyTitle => 'जांच इतिहास';

  @override
  String get allCrops => 'सभी फसलें';

  @override
  String noHistoryForCrop(Object cropName) {
    return '$cropName के लिए कोई पिछला स्कैन मौजूद नहीं है।';
  }

  @override
  String get profileTitle => 'किसान प्रोफाइल';

  @override
  String get languagePreference => 'भाषा चुनें';

  @override
  String get offlineMode => 'ऑफलाइन मोड';

  @override
  String get offlineModeActive =>
      'ऑफलाइन मोड: बिना इंटरनेट के भी एआई जांच सामान्य रूप से चालू है।';

  @override
  String syncPending(Object count) {
    return '$count स्कैन अपलोड होना बाकी';
  }

  @override
  String get allSynced => 'सभी स्कैन क्लाउड में सुरक्षित हैं';

  @override
  String get disclaimer => 'कानूनी अस्वीकरण व सलाह';

  @override
  String get logout => 'लॉग आउट करें';

  @override
  String get logoutConfirm => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';

  @override
  String get weatherToday => 'आज का मौसम';

  @override
  String get humidity => 'नमी';

  @override
  String get wind => 'हवा';

  @override
  String get rainChance => 'बारिश';

  @override
  String get weatherError => 'मौसम लोड करने में असमर्थ';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get cachedWeather => 'कैश किया गया';

  @override
  String get currentLocation => 'वर्तमान स्थान';

  @override
  String get weatherDetails => 'मौसम विवरण';

  @override
  String get sprayAdvisoryTitle => 'कृषि छिड़काव सलाह';

  @override
  String get sprayFavorable =>
      'कीटनाशक छिड़काव और कृषि कार्य के लिए मौसम अनुकूल है';

  @override
  String get sprayUnfavorable =>
      'आज कीटनाशक का छिड़काव न करें (बारिश/तेज हवा की संभावना)';

  @override
  String get sprayAdvisoryFavorableSubtitle =>
      'हवा की गति < 20 किमी/घंटा और बारिश का कम जोखिम';

  @override
  String get sprayAdvisoryUnfavorableSubtitle =>
      'तेज हवा या बारिश से दवा बहने या उड़ने का खतरा';

  @override
  String get hourlyForecast => '24 घंटे का पूर्वानुमान';

  @override
  String get dailyForecast => '7 दिनों का पूर्वानुमान';

  @override
  String get feelsLike => 'महसूस';

  @override
  String get daylight => 'धूप / दिन का समय';

  @override
  String get daytime => 'दिन';

  @override
  String get nighttime => 'रात';

  @override
  String get uvIndex => 'पराबैंगनी सूचकांक';

  @override
  String get minMax => 'न्यूनतम / अधिकतम';

  @override
  String get delete => 'हटाएं';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get deleteScan => 'स्कैन हटाएं';

  @override
  String get deleteScanConfirm =>
      'क्या आप वाकई इस स्कैन रिकॉर्ड को हटाना चाहते हैं?';

  @override
  String get scanDeleted => 'स्कैन सफलतापूर्वक हटा दिया गया';

  @override
  String get clearHistory => 'सारा इतिहास हटाएं';

  @override
  String get clearHistoryConfirm =>
      'क्या आप वाकई सभी स्कैन रिकॉर्ड हटाना चाहते हैं? यह क्रिया वापस नहीं ली जा सकती।';

  @override
  String get historyCleared => 'सारा स्कैन इतिहास हटा दिया गया';

  @override
  String get nutritionTitle => 'खाद एवं फसल पोषण';

  @override
  String get organicNutritionLabel => 'जैविक एवं प्राकृतिक खाद';

  @override
  String get fertilizerClassLabel => 'संतुलित उर्वरक एवं पोषण';

  @override
  String get dosageDisclaimerNote =>
      'हमेशा पैकेट पर लिखे निर्देश या कृषि विशेषज्ञ की सलाह अनुसार ही प्रयोग करें।';
}
