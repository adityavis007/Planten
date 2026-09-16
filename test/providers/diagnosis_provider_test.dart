import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/crop.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/providers/diagnosis_provider.dart';
import 'package:planten/services/inference_service.dart';
import 'package:planten/services/knowledge_base_service.dart';
import 'package:planten/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tomatoCrop = Crop(
    id: 'tomato',
    nameEn: 'Tomato',
    nameHi: 'टमाटर',
    iconAssetPath: 'assets/icons/crops/tomato.png',
  );

  const wheatCrop = Crop(
    id: 'wheat',
    nameEn: 'Wheat',
    nameHi: 'गेहूं',
    iconAssetPath: 'assets/icons/crops/wheat.png',
  );

  const sampleGuidance = TreatmentGuidance(
    diseaseId: 'tomato_early_blight',
    crop: 'tomato',
    nameEn: 'Tomato Early Blight',
    nameHi: 'टमाटर का अगेती झुलसा',
    symptomsEn: 'Dark circular spots with concentric rings.',
    symptomsHi: 'पत्तियों पर गोल भूरे छल्लेदार धब्बे।',
    culturalStepsEn: ['Prune infected leaves.', 'Water at base.'],
    culturalStepsHi: ['संक्रमित पत्तियों को नष्ट करें।'],
    managementCategory: 'fungal',
    severityLevel: 'medium',
    disclaimerEn: 'Consult local KVK.',
    disclaimerHi: 'कृषि विज्ञान केंद्र से संपर्क करें।',
  );

  final testLabels = [
    'tomato_early_blight',
    'tomato_late_blight',
    'tomato_healthy',
    'wheat_yellow_rust',
    'wheat_healthy',
  ];

  late Directory tempDir;
  late File sampleImageFile;
  late LocalStorageService localStorageService;
  late KnowledgeBaseService knowledgeBaseService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localStorageService = LocalStorageService();
    await localStorageService.init();

    knowledgeBaseService = KnowledgeBaseService(initialGuidance: [sampleGuidance]);

    tempDir = await Directory.systemTemp.createTemp('diagnosis_provider_test_');
    sampleImageFile = File('${tempDir.path}/leaf.png');

    final testImg = img.Image(width: 50, height: 50);
    for (var y = 0; y < 50; y++) {
      for (var x = 0; x < 50; x++) {
        testImg.setPixelRgb(x, y, 40, 150, 40);
      }
    }
    await sampleImageFile.writeAsBytes(img.encodePng(testImg));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  InferenceService createMockInferenceService(Map<String, double> scores) {
    return InferenceService(
      labels: testLabels,
      customRunner: (tensor) async {
        return testLabels.map((lbl) => scores[lbl] ?? 0.0).toList();
      },
    );
  }

  group('DiagnosisProvider Lifecycle & Initial State', () {
    test('starts with idle status and empty fields', () {
      final provider = DiagnosisProvider(
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      expect(provider.status, DiagnosisStatus.idle);
      expect(provider.isIdle, isTrue);
      expect(provider.isProcessing, isFalse);
      expect(provider.isSuccess, isFalse);
      expect(provider.isError, isFalse);
      expect(provider.currentDiagnosis, isNull);
      expect(provider.currentEvaluation, isNull);
      expect(provider.currentRawOutput, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  group('DiagnosisProvider Successful Diagnosis Flow', () {
    test('diagnoses Likely condition (>85%) with full guidance and persists to history', () async {
      final mockInference = createMockInferenceService({
        'tomato_early_blight': 0.92,
        'tomato_late_blight': 0.05,
        'tomato_healthy': 0.03,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final statusTransitions = <DiagnosisStatus>[];
      provider.addListener(() {
        statusTransitions.add(provider.status);
      });

      final result = await provider.diagnoseLeaf(sampleImageFile, tomatoCrop);

      expect(statusTransitions, [DiagnosisStatus.processing, DiagnosisStatus.success]);
      expect(provider.status, DiagnosisStatus.success);
      expect(provider.isSuccess, isTrue);

      // Verify result and evaluation
      expect(result.cropId, 'tomato');
      expect(result.diseaseId, 'tomato_early_blight');
      expect(result.diseaseNameEn, 'Tomato Early Blight');
      expect(result.diseaseNameHi, 'टमाटर का अगेती झुलसा');
      expect(result.confidenceScore, 0.92);
      expect(result.severity, SeverityLevel.medium);
      expect(result.guidance, isNotNull);
      expect(result.guidance?.symptomsEn, contains('Dark circular spots'));

      expect(provider.currentEvaluation?.category, ConfidenceCategory.likely);
      expect(provider.currentEvaluation?.unlockFullGuidance, isTrue);
      expect(provider.currentEvaluation?.promptRetake, isFalse);

      // Verify persisted scan in history
      expect(provider.scanHistory.length, 1);
      expect(provider.scanHistory.first.id, result.id);
    });

    test('diagnoses Possible condition (60%-85%) with retake prompt', () async {
      final mockInference = createMockInferenceService({
        'tomato_early_blight': 0.72,
        'tomato_late_blight': 0.18,
        'tomato_healthy': 0.10,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final result = await provider.diagnoseLeaf(sampleImageFile, tomatoCrop);

      expect(provider.status, DiagnosisStatus.success);
      expect(result.diseaseId, 'tomato_early_blight');
      expect(provider.currentEvaluation?.category, ConfidenceCategory.possible);
      expect(provider.currentEvaluation?.unlockFullGuidance, isFalse);
      expect(provider.currentEvaluation?.promptRetake, isTrue);
      expect(provider.currentEvaluation?.routeToExpert, isFalse);
    });

    test('diagnoses Uncertain condition (<60%) with expert routing & no disease assertion', () async {
      final mockInference = createMockInferenceService({
        'tomato_early_blight': 0.40,
        'tomato_late_blight': 0.35,
        'tomato_healthy': 0.25,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final result = await provider.diagnoseLeaf(sampleImageFile, tomatoCrop);

      expect(provider.status, DiagnosisStatus.success);
      expect(provider.currentEvaluation?.category, ConfidenceCategory.uncertain);
      expect(provider.currentEvaluation?.predictedDiseaseId, isNull);
      expect(result.diseaseNameEn, 'Uncertain Diagnosis');
      expect(result.diseaseNameHi, 'निदान अनिश्चित');
      expect(result.guidance, isNull);
      expect(provider.currentEvaluation?.routeToExpert, isTrue);
      expect(provider.currentEvaluation?.promptRetake, isTrue);
    });

    test('diagnoses Healthy condition correctly', () async {
      final mockInference = createMockInferenceService({
        'tomato_healthy': 0.95,
        'tomato_early_blight': 0.03,
        'tomato_late_blight': 0.02,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final result = await provider.diagnoseLeaf(sampleImageFile, tomatoCrop);

      expect(provider.status, DiagnosisStatus.success);
      expect(provider.currentEvaluation?.isHealthy, isTrue);
      expect(result.diseaseNameEn, 'Healthy Plant');
      expect(result.diseaseNameHi, 'स्वस्थ पौधा');
      expect(result.severity, SeverityLevel.low);
    });

    test('detects crop mismatch when photo shows tomato but crop is wheat', () async {
      final mockInference = createMockInferenceService({
        'tomato_early_blight': 0.91,
        'wheat_yellow_rust': 0.05,
        'wheat_healthy': 0.04,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final result = await provider.diagnoseLeaf(sampleImageFile, wheatCrop);

      expect(provider.currentEvaluation?.isCropMismatch, isTrue);
      expect(provider.currentEvaluation?.detectedCropId, 'tomato');
      expect(result.diseaseNameEn, 'Crop Mismatch Detected');
      expect(provider.currentEvaluation?.routeToExpert, isTrue);
    });
  });

  group('DiagnosisProvider Error Handling & State Reset', () {
    test('sets error status when image file does not exist', () async {
      final mockInference = createMockInferenceService({});
      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final nonExistentFile = File('${tempDir.path}/missing.png');

      await expectLater(
        () => provider.diagnoseLeaf(nonExistentFile, tomatoCrop),
        throwsA(isA<ArgumentError>()),
      );

      expect(provider.status, DiagnosisStatus.error);
      expect(provider.isError, isTrue);
      expect(provider.errorMessage, contains('does not exist'));
      expect(provider.currentDiagnosis, isNull);
    });

    test('reset restores provider to idle and clears diagnosis', () async {
      final mockInference = createMockInferenceService({
        'tomato_early_blight': 0.90,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      await provider.diagnoseLeaf(sampleImageFile, tomatoCrop);
      expect(provider.status, DiagnosisStatus.success);
      expect(provider.currentDiagnosis, isNotNull);

      provider.reset();
      expect(provider.status, DiagnosisStatus.idle);
      expect(provider.isIdle, isTrue);
      expect(provider.currentDiagnosis, isNull);
      expect(provider.currentEvaluation, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('deleteScan removes item from history', () async {
      final mockInference = createMockInferenceService({
        'tomato_early_blight': 0.90,
      });

      final provider = DiagnosisProvider(
        inferenceService: mockInference,
        knowledgeBaseService: knowledgeBaseService,
        localStorageService: localStorageService,
      );

      final result = await provider.diagnoseLeaf(sampleImageFile, tomatoCrop);
      expect(provider.scanHistory.length, 1);

      await provider.deleteScan(result.id);
      expect(provider.scanHistory, isEmpty);
    });
  });
}
