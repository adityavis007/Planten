import 'package:flutter/foundation.dart';

/// Immutable domain model representing verified crop farming and cultivation guidance.
@immutable
class CropFarmingGuide {
  /// Unique identifier of the crop (e.g. `'tomato'`, `'potato'`).
  final String cropId;

  /// English name of the crop.
  final String nameEn;

  /// Hindi vernacular name of the crop.
  final String nameHi;

  /// Crop icon asset path.
  final String iconAssetPath;

  /// Growing duration (lifecycle time) in English.
  final String durationEn;

  /// Growing duration (lifecycle time) in Hindi.
  final String durationHi;

  /// Best weather conditions and sowing months in English.
  final String bestWeatherEn;

  /// Best weather conditions and sowing months in Hindi.
  final String bestWeatherHi;

  /// Soil preparation, spacing, irrigation, and nutrition management guidance in English.
  final String managementGuidanceEn;

  /// Soil preparation, spacing, irrigation, and nutrition management guidance in Hindi.
  final String managementGuidanceHi;

  /// Major disease/pest symptoms to watch for in English.
  final String symptomsEn;

  /// Major disease/pest symptoms to watch for in Hindi.
  final String symptomsHi;

  /// Bulleted actionable preventive measures in English.
  final List<String> preventiveActionsEn;

  /// Bulleted actionable preventive measures in Hindi.
  final List<String> preventiveActionsHi;

  /// Important agricultural and chemical safety guidelines in English.
  final String safetyPrecautionsEn;

  /// Important agricultural and chemical safety guidelines in Hindi.
  final String safetyPrecautionsHi;

  /// Advisory source verification string in English.
  final String sourceEn;

  /// Advisory source verification string in Hindi.
  final String sourceHi;

  const CropFarmingGuide({
    required this.cropId,
    required this.nameEn,
    required this.nameHi,
    required this.iconAssetPath,
    required this.durationEn,
    required this.durationHi,
    required this.bestWeatherEn,
    required this.bestWeatherHi,
    required this.managementGuidanceEn,
    required this.managementGuidanceHi,
    required this.symptomsEn,
    required this.symptomsHi,
    required this.preventiveActionsEn,
    required this.preventiveActionsHi,
    required this.safetyPrecautionsEn,
    required this.safetyPrecautionsHi,
    this.sourceEn = 'Verified by ICAR & State Agricultural Universities',
    this.sourceHi = 'आईसीएआर (ICAR) एवं राज्य कृषि विश्वविद्यालयों द्वारा सत्यापित',
  });

  /// Localized crop name based on given language code.
  String localizedName(String languageCode) =>
      languageCode.toLowerCase() == 'hi' ? nameHi : nameEn;

  /// Localized duration based on language code.
  String localizedDuration(String languageCode) =>
      languageCode.toLowerCase() == 'hi' ? durationHi : durationEn;

  /// Localized weather/sowing months based on language code.
  String localizedBestWeather(String languageCode) =>
      languageCode.toLowerCase() == 'hi' ? bestWeatherHi : bestWeatherEn;

  /// Localized management guidance based on language code.
  String localizedManagementGuidance(String languageCode) =>
      languageCode.toLowerCase() == 'hi'
          ? managementGuidanceHi
          : managementGuidanceEn;

  /// Localized symptoms based on language code.
  String localizedSymptoms(String languageCode) =>
      languageCode.toLowerCase() == 'hi' ? symptomsHi : symptomsEn;

  /// Localized preventive actions based on language code.
  List<String> localizedPreventiveActions(String languageCode) =>
      languageCode.toLowerCase() == 'hi'
          ? preventiveActionsHi
          : preventiveActionsEn;

  /// Localized safety precautions based on language code.
  String localizedSafetyPrecautions(String languageCode) =>
      languageCode.toLowerCase() == 'hi'
          ? safetyPrecautionsHi
          : safetyPrecautionsEn;

  /// Localized source verification based on language code.
  String localizedSource(String languageCode) =>
      languageCode.toLowerCase() == 'hi' ? sourceHi : sourceEn;

  /// Resolves [CropFarmingGuide] for a crop ID, defaulting to tomato if not found.
  static CropFarmingGuide fromCropId(String cropId) {
    final normalized = cropId.trim().toLowerCase();
    return allGuides.firstWhere(
      (g) => g.cropId == normalized,
      orElse: () => allGuides.first,
    );
  }

  /// Comprehensive agronomy data for all 5 launch crops.
  static const List<CropFarmingGuide> allGuides = [
    CropFarmingGuide(
      cropId: 'tomato',
      nameEn: 'Tomato',
      nameHi: 'टमाटर',
      iconAssetPath: 'assets/icons/crops/tomato.png',
      durationEn: '90 - 120 Days (Transplant to Harvest)',
      durationHi: '90 - 120 दिन (रोपाई से तुड़ाई तक)',
      bestWeatherEn: 'Oct - Nov (Rabi), Feb - Mar (Zaid) | Optimal: 20°C - 28°C',
      bestWeatherHi: 'अक्टूबर - नवंबर (रबी), फरवरी - मार्च (जायद) | 20°C - 28°C',
      managementGuidanceEn:
          '• Soil: Well-drained sandy loam or clay loam rich in organic matter (pH 6.0 - 7.0).\n'
          '• Spacing: Bed spacing 60 cm row-to-row, 45-50 cm plant-to-plant.\n'
          '• Irrigation: Drip irrigation recommended every 4-7 days. Avoid flooding to prevent collar rot.\n'
          '• Nutrients: Apply 20-25 tonnes/ha FYM + NPK 120:60:60 kg/ha with split nitrogen doses.',
      managementGuidanceHi:
          '• मिट्टी: उत्तम जल निकासी वाली बलुई दोमट मिट्टी (pH 6.0 - 7.0)।\n'
          '• दूरी: कतार से कतार 60 सेमी, पौधे से पौधा 45-50 सेमी की दूरी रखें।\n'
          '• सिंचाई: ड्रिप सिंचाई सर्वोत्तम है; 4-7 दिनों में आवश्यकतानुसार पानी दें। जलभराव से बचें।\n'
          '• खाद व उर्वरक: 20-25 टन/हेक्टेयर गोबर की खाद + एनपीके 120:60:60 किग्रा/हेक्टेयर दें।',
      symptomsEn:
          '• Early Blight: Dark concentric target-board spots on older lower leaves.\n'
          '• Late Blight: Water-soaked dark brown irregular lesions with white mold under leaves.\n'
          '• Leaf Curl: Upward cupping, thickened veins, stunted bush growth, whitefly vector.',
      symptomsHi:
          '• अगेती झुलसा: निचली पुरानी पत्तियों पर गोल भूरे छल्लेदार धब्बे।\n'
          '• पछेती झुलसा: पत्तियों पर पानी से भीगे हुए गहरे काले धब्बे और निचली सतह पर सफेद फफूंद।\n'
          '• पर्ण कुंचन (मरोड़िया): पत्तियां ऊपर की ओर मुड़ना, पौधा बौना होना (सफेद मक्खी द्वारा फैलाव)।',
      preventiveActionsEn: [
        'Treat seeds with Trichoderma viride (4g/kg) or Thiram before nursery sowing.',
        'Follow strict 3-year crop rotation avoiding Solanaceous family crops.',
        'Install yellow sticky traps (15-20 traps/acre) to monitor and control whiteflies.',
        'Prune lower leaves touching soil and maintain clean field sanitation.',
        'Mulch planting beds with clean straw to prevent soil-splash spore transmission.',
      ],
      preventiveActionsHi: [
        'नर्सरी में बीज बोने से पहले ट्राइकोडर्मा (4 ग्राम/किग्रा) या थीरम से बीजोपचार करें।',
        'टमाटर के बाद आलू या बैंगन न लगाएं; कम से कम 3 साल का फसल चक्र अपनाएं।',
        'सफेद मक्खी नियंत्रण के लिए प्रति एकड़ 15-20 पीले चिपचिपे ट्रैप (Yellow Sticky Traps) लगाएं।',
        'जमीन को छूने वाली निचली पत्तियों को काटकर खेत से दूर नष्ट कर दें।',
        'मिट्टी से फफूंद के छीटें पत्तियों पर न पड़ें, इसके लिए पुआल की पलवार (मल्चिंग) करें।',
      ],
      safetyPrecautionsEn:
          '• Wear protective gloves, face mask, and eye goggles during any spray operations.\n'
          '• Strictly adhere to 7-10 day Pre-Harvest Interval (PHI) before picking ripe tomatoes.\n'
          '• Never spray agrochemicals during windy weather or intense midday sunshine.\n'
          '• Safely dispose of empty pesticide containers away from open water sources.',
      safetyPrecautionsHi:
          '• कीटनाशक या फफूंदनाशक छिड़काव के दौरान मास्क, दस्ताने और चश्मा अवश्य पहनें।\n'
          '• पके टमाटर तोड़ने से पहले 7-10 दिन की प्रतीक्षा अवधि (PHI) का अनिवार्य रूप से पालन करें।\n'
          '• तेज हवा या तेज धूप के समय कभी भी रसायनों का छिड़काव न करें।\n'
          '• खाली कीटनाशक डिब्बों को पानी के स्रोतों से दूर जमीन में सुरक्षित नष्ट करें।',
    ),
    CropFarmingGuide(
      cropId: 'potato',
      nameEn: 'Potato',
      nameHi: 'आलू',
      iconAssetPath: 'assets/icons/crops/potato.png',
      durationEn: '80 - 110 Days (Planting to Tuber Harvest)',
      durationHi: '80 - 110 दिन (बुवाई से खुदाई तक)',
      bestWeatherEn: 'Oct 15 - Nov 15 (Winter Season) | Optimal: 15°C - 24°C',
      bestWeatherHi: '15 अक्टूबर - 15 नवंबर (शीतकालीन) | 15°C - 24°C (ठंडी रातें)',
      managementGuidanceEn:
          '• Soil: Deep, loose, fertile sandy loam soil with good aeration (pH 5.2 - 6.5).\n'
          '• Spacing: Ridge planting with 60 cm row spacing and 20 cm tuber-to-tuber.\n'
          '• Earthing Up: Perform first earthing up at 30 days and second at 45 days after sowing.\n'
          '• Irrigation: Light, frequent irrigations; stop watering 10-12 days before harvest for skin hardening.',
      managementGuidanceHi:
          '• मिट्टी: भुरभुरी, गहरी एवं अच्छी जल निकास वाली दोमट मिट्टी (pH 5.2 - 6.5)।\n'
          '• दूरी: मेड़ों पर बुवाई करें; कतार 60 सेमी और कंद से कंद की दूरी 20 सेमी रखें।\n'
          '• मिट्टी चढ़ाना: बुवाई के 30 दिन बाद पहली बार और 45 दिन बाद दूसरी बार मिट्टी चढ़ाएं।\n'
          '• सिंचाई: हल्की व नियमित सिंचाई करें; खुदाई से 10-12 दिन पहले सिंचाई बंद कर दें।',
      symptomsEn:
          '• Early Blight: Brown angular concentric spots on foliage.\n'
          '• Late Blight: Rapidly spreading black-brown rot on leaves with cottony white margins.\n'
          '• Scab & Scurf: Rough lesions or dark black crusts on harvested tuber skins.',
      symptomsHi:
          '• अगेती झुलसा: पत्तियों पर भूरे छल्लेदार धब्बे जो धीरे-धीरे बढ़ते हैं।\n'
          '• पछेती झुलसा: नम मौसम में पत्तियों पर तेजी से फैलने वाले काले धब्बे और किनारों पर सफेद फफूंद।\n'
          '• कंद चेचक/काली पपड़ी: आलू की त्वचा पर खुरदुरे चकत्ते या काले पपड़ीदार निशान।',
      preventiveActionsEn: [
        'Use certified disease-free sprouted seed tubers (35-45g weight).',
        'Dip cut tubers in Mancozeb (2.5g/L) solution for 10 minutes before planting.',
        'Ensure continuous ridge coverage so tubers are never exposed to sunlight (greening).',
        'Destroy volunteer potato plants and practice non-solanaceous crop rotations.',
      ],
      preventiveActionsHi: [
        'प्रमाणित और रोगमुक्त अंकुरित बीज कंदों (35-45 ग्राम वजन) का ही प्रयोग करें।',
        'बुवाई से पहले कंदों को मैंकोजेब (2.5 ग्राम/लीटर) के घोल में 10 मिनट उपचारित करें।',
        'मेड़ों पर पूरी मिट्टी ढकी रखें ताकि आलू धूप में हरे न होने पाएं।',
        'खेत में गिरे पुराने सड़े कंदों को नष्ट करें और फसल चक्र का पालन करें।',
      ],
      safetyPrecautionsEn:
          '• Do not consume greened potato tubers containing solanine toxin.\n'
          '• Wear full protective clothing and respirators during blight fungicide sprayings.\n'
          '• Maintain a strict 14-day PHI between chemical application and harvest.',
      safetyPrecautionsHi:
          '• हरे पड़े हुए आलू के कंदों का सेवन न करें क्योंकि इनमें सोलेनाइन विषैला तत्व होता है।\n'
          '• झुलसा रोधी स्प्रे करते समय पूरे शरीर को ढकने वाले कपड़े और मास्क का प्रयोग करें।\n'
          '• रसायन छिड़काव और आलू खुदाई के बीच कम से कम 14 दिन का अंतर (PHI) रखें।',
    ),
    CropFarmingGuide(
      cropId: 'wheat',
      nameEn: 'Wheat',
      nameHi: 'गेहूं',
      iconAssetPath: 'assets/icons/crops/wheat.png',
      durationEn: '110 - 130 Days (Sowing to Harvesting)',
      durationHi: '110 - 130 दिन (बुवाई से कटाई तक)',
      bestWeatherEn: 'Nov 1 - Nov 25 (Rabi Season) | Optimal: 18°C - 24°C',
      bestWeatherHi: '1 नवंबर - 25 नवंबर (रबी मौसम) | 18°C - 24°C',
      managementGuidanceEn:
          '• Soil: Well-pulverized loam or clay loam soil with adequate moisture retention (pH 6.5 - 7.5).\n'
          '• Seed Rate & Spacing: 100 kg/ha using seed drill at 20-22.5 cm row spacing, 4-5 cm depth.\n'
          '• Critical Irrigations: 5-6 irrigations at Crown Root Initiation (21 DAS), tillering, jointing, flowering, and grain filling.\n'
          '• Fertilizer: N:P:K 120:60:40 kg/ha + 25 kg/ha Zinc Sulphate in zinc-deficient areas.',
      managementGuidanceHi:
          '• मिट्टी: अच्छी जल धारण क्षमता वाली दोमट या मटियार दोमट मिट्टी (pH 6.5 - 7.5)।\n'
          '• बीज दर व दूरी: 100 किग्रा/हेक्टेयर; सीड ड्रिल से 20-22.5 सेमी कतार दूरी, 4-5 सेमी गहराई पर बोएं।\n'
          '• मुख्य सिंचाई: 5-6 सिंचाई; मुख्य रूप से ताज मूल (CRI - 21 दिन), कल्ले फूटते समय, फूल आने पर और दाना भरते समय।\n'
          '• खाद: एन:पी:के 120:60:40 किग्रा/हेक्टेयर और जिंक की कमी वाले खेतों में 25 किग्रा जिंक सल्फेट दें।',
      symptomsEn:
          '• Brown/Yellow Rust: Linear yellow or orange-brown powdery pustules on leaves.\n'
          '• Powdery Mildew: White cottony patches on lower leaf blades and stem bases.\n'
          '• Loose Smut: Heads turning into black powdery mass of fungal spores.',
      symptomsHi:
          '• पीला/भूरा रतुआ (गेरुआ): पत्तियों पर समानांतर पीली या भूरी पाउडर जैसी धारियां/फफोले।\n'
          '• चूर्णिल आसिता (पाउडरी मिल्ड्यू): पत्तियों और तने पर सफेद पाउडर जैसी फफूंद।\n'
          '• कंडुआ रोग (लूज स्मट): गेहूं की बालियां काले पाउडर जैसे चूर्ण में बदल जाना।',
      preventiveActionsEn: [
        'Treat seeds with Carboxin + Thiram (2g/kg) or Trichoderma before sowing.',
        'Sow rust-resistant recommended regional varieties (e.g. DBW-187, HD-2967, PBW-550).',
        'Avoid excessive early nitrogen application which makes leaves soft and prone to rust.',
        'Complete timely sowing before November 25 to protect against terminal heat stress.',
      ],
      preventiveActionsHi: [
        'बुवाई से पहले कार्बोक्सिन + थीरम (2 ग्राम/किग्रा) या ट्राइकोडर्मा से बीजोपचार अवश्य करें।',
        'रतुआ रोधी उन्नत किस्मों (जैसे DBW-187, HD-2967, PBW-550 आदि) की ही बुवाई करें।',
        'शुरुआत में अधिक यूरिया देने से बचें क्योंकि इससे पत्तियां कोमल होकर रोग की चपेट में आती हैं।',
        'पछेती गर्मी के प्रकोप से बचने के लिए 25 नवंबर से पहले बुवाई पूरी कर लें।',
      ],
      safetyPrecautionsEn:
          '• Do not handle chemical-treated seed with bare hands; use protective gloves.\n'
          '• Check wind direction when applying foliar fungicides; avoid inhaling drift.\n'
          '• Stop all chemical applications at least 25 days before grain harvesting.',
      safetyPrecautionsHi:
          '• उपचारित बीजों को नंगे हाथों से न छुएं; रबर के दस्तानों का प्रयोग करें।\n'
          '• फफूंदनाशक स्प्रे करते समय हवा की दिशा का ध्यान रखें ताकि रसायन शरीर पर न आए।\n'
          '• कटाई से कम से कम 25 दिन पहले किसी भी प्रकार के रसायन का छिड़काव बंद कर दें।',
    ),
    CropFarmingGuide(
      cropId: 'chili',
      nameEn: 'Chili',
      nameHi: 'मिर्च',
      iconAssetPath: 'assets/icons/crops/chili.png',
      durationEn: '120 - 150 Days (Transplanting to Final Picking)',
      durationHi: '120 - 150 दिन (रोपाई से अंतिम तुड़ाई तक)',
      bestWeatherEn: 'May - Jun (Kharif), Oct - Nov (Rabi) | Optimal: 22°C - 30°C',
      bestWeatherHi: 'मई - जून (खरीफ), अक्टूबर - नवंबर (रबी) | 22°C - 30°C',
      managementGuidanceEn:
          '• Soil: Well-drained rich sandy loam or black soil with pH 6.5 - 7.5.\n'
          '• Transplanting: 35-40 day old sturdy seedlings planted at 60x45 cm spacing on ridges.\n'
          '• Irrigation: Light irrigations every 5-8 days; avoid water stagnation which causes root rot.\n'
          '• Balanced Feeding: High potassium support during fruit setting enhances color and pungency.',
      managementGuidanceHi:
          '• मिट्टी: उत्तम जलनिकास वाली उपजाऊ दोमट या काली मिट्टी (pH 6.5 - 7.5)।\n'
          '• रोपाई: 35-40 दिन पुरानी स्वस्थ पौध को मेड़ों पर 60x45 सेमी की दूरी पर लगाएं।\n'
          '• सिंचाई: 5-8 दिन में हल्की सिंचाई करें; खेत में पानी ठहरने न दें जिससे जड़ गलन से बचा जा सके।\n'
          '• पोषण: फल बनते समय पोटाश की उचित मात्रा देने से मिर्च में चमक, रंग और तीखापन बढ़ता है।',
      symptomsEn:
          '• Leaf Curl: Upward/downward leaf curling, thick brittle leaves, severe vector attack.\n'
          '• Anthracnose/Dieback: Dark sunken circular spots on ripe pods and dying twigs.\n'
          '• Bacterial Wilt: Sudden daytime wilting while foliage remains green.',
      symptomsHi:
          '• मरोड़िया रोग (लीफ कर्ल): पत्तियां ऊपर या नीचे की ओर मुड़ना, सिकुड़ना और कड़क होना।\n'
          '• फल सड़न व डाईबैक: पकी मिर्च पर धंसे हुए काले गोल धब्बे और टहनियों का ऊपर से सूखना।\n'
          '• जीवाणु उकठा: हरी अवस्था में ही पौधे का अचानक मुरझा कर सूख जाना।',
      preventiveActionsEn: [
        'Install yellow and blue sticky traps (20 traps/acre) for whiteflies, thrips, and mites.',
        'Spray Neem seed kernel extract (NSKE 5%) or 10000 ppm neem oil as preventive repellent.',
        'Dip seedling roots in Trichoderma viride suspension before transplanting.',
        'Collect and burn anthracnose-infected fruits and dried twig ends promptly.',
      ],
      preventiveActionsHi: [
        'सफेद मक्खी, थ्रिप्स और माइट्स के नियंत्रण के लिए पीले और नीले चिपचिपे ट्रैप लगाएं।',
        'रोकथाम के लिए समय-समय पर नीम के तेल (10000 ppm) का छिड़काव करें।',
        'रोपाई से पूर्व पौध की जड़ों को ट्राइकोडर्मा घोल में 15 मिनट डुबोकर उपचारित करें।',
        'रोगग्रस्त सड़ी मिर्चियों और सूखी टहनियों को तुरंत तोड़कर जला दें।',
      ],
      safetyPrecautionsEn:
          '• Wash hands thoroughly with soap after handling chili plants and pods.\n'
          '• Wear goggles and masks when spraying to avoid severe capsaicin/chemical eye irritation.\n'
          '• Maintain 7-day Pre-Harvest Interval (PHI) before harvesting fresh green or red pods.',
      safetyPrecautionsHi:
          '• मिर्च की तुड़ाई या पौधों के काम के बाद हाथों को साबुन से अच्छी तरह धोएं।\n'
          '• छिड़काव के समय चश्मा और मास्क अवश्य पहनें ताकि आंखों में जलन न हो।\n'
          '• फल तोड़ने से कम से कम 7 दिन पहले कीटनाशक छिड़काव बंद कर दें।',
    ),
    CropFarmingGuide(
      cropId: 'cotton',
      nameEn: 'Cotton',
      nameHi: 'कपास',
      iconAssetPath: 'assets/icons/crops/cotton.png',
      durationEn: '150 - 180 Days (Sowing to Final Boll Burst)',
      durationHi: '150 - 180 दिन (बुवाई से अंतिम चुगाई तक)',
      bestWeatherEn: 'Apr - May (North), Jun - Jul (Central/South) | Optimal: 25°C - 35°C',
      bestWeatherHi: 'अप्रैल - मई (उत्तर भारत), जून - जुलाई (मध्य/दक्षिण) | 25°C - 35°C',
      managementGuidanceEn:
          '• Soil: Deep black cotton soils (Vertisols) or alluvial loam with high water capacity (pH 7.0 - 8.5).\n'
          '• Spacing: 90-100 cm row-to-row, 45-60 cm plant-to-plant depending on hybrid vigour.\n'
          '• Irrigation: 4-6 critical irrigations during flowering and boll development stage.\n'
          '• Canopy Management: Avoid excessive nitrogen fertilisation which causes rampant vegetative growth.',
      managementGuidanceHi:
          '• मिट्टी: गहरी काली कपास मिट्टी (वर्टिसोल) या दोमट मिट्टी (pH 7.0 - 8.5)।\n'
          '• दूरी: कतार से कतार 90-100 सेमी, पौधे से पौधा 45-60 सेमी रखें।\n'
          '• सिंचाई: फूल खिलने और टिंडे बनते समय 4-6 आवश्यक सिंचाई करें।\n'
          '• नाइट्रोजन संतुलन: अत्यधिक यूरिया न दें, जिससे अनावश्यक वानस्पतिक वृद्धि से बचा जा सके।',
      symptomsEn:
          '• Leaf Curl Virus: Vein thickening, upward leaf cupping, leafy enations under leaves.\n'
          '• Bacterial Blight: Angular water-soaked dark leaf spots delimited by veins.\n'
          '• Pink Bollworm: Entry holes in flower buds (rosetted flowers) and damaged stained lint.',
      symptomsHi:
          '• लीफ कर्ल वायरस: नसों का मोटा होना, पत्तियां मुड़ना और पत्तियों के नीचे छोटी पत्ती जैसी वृद्धि।\n'
          '• जीवाणु अंगमारी: नसों के बीच कोणीय गहरे काले धब्बे (कोणीय पत्ती धब्बा)।\n'
          '• गुलाबी सुंडी (PBW): फूलों का बंद गुलाब जैसा होना (रोसेट फ्लावर) और टिंडों में छेद।',
      preventiveActionsEn: [
        'Plant 2-3 border rows of non-Bt cotton, maize, or pigeonpea around the field.',
        'Install 5 pheromone traps per acre for early monitoring of pink bollworm moth flights.',
        'Practice clean cultivation and avoid rationing/perennial cultivation of cotton.',
        'Destroy cotton stalks and stubbles immediately after final picking.',
      ],
      preventiveActionsHi: [
        'खेत के चारों ओर मक्का, ज्वार या अरहर की 2-3 सुरक्षा पंक्तियां लगाएं।',
        'गुलाबी सुंडी की निगरानी के लिए प्रति एकड़ 5 फेरोमोन ट्रैप (Pheromone Traps) लगाएं।',
        'कपास की फसल में कभी भी पेड़ी (Ratooning) न रखें।',
        'अंतिम चुगाई के बाद कपास की डंठलों और अवशेषों को रोटावेटर से नष्ट कर दें।',
      ],
      safetyPrecautionsEn:
          '• Strictly follow Central Insecticides Board (CIBRC) approved chemicals and dosages.\n'
          '• Wear full protective coveralls, chemical-resistant gloves, and carbon respirators.\n'
          '• Maintain a mandatory 15-20 day Pre-Harvest Interval (PHI) before picking seed cotton.',
      safetyPrecautionsHi:
          '• केंद्रीय कीटनाशक बोर्ड (CIBRC) द्वारा अनुमोदित दवाओं और मात्रा का ही प्रयोग करें।\n'
          '• छिड़काव के दौरान पूरा शरीर ढकने वाला सुरक्षात्मक सूट, दस्ताने और मास्क पहनें।\n'
          '• कपास चुगाई से कम से कम 15-20 दिन पहले किसी भी कीटनाशक का छिड़काव न करें।',
    ),
  ];
}
