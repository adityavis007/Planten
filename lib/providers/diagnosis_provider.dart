import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/confidence_evaluation_result.dart';
import '../models/crop.dart';
import '../models/diagnosis_result.dart';
import '../models/raw_inference_output.dart';
import '../models/severity_level.dart';
import '../models/treatment_guidance.dart';
import '../services/confidence_evaluation_engine.dart';
import '../services/firestore_sync_service.dart';
import '../services/history_service.dart';
import '../services/inference_service.dart';
import '../services/knowledge_base_service.dart';
import '../services/local_storage_service.dart';

export '../models/confidence_evaluation_result.dart';
export '../models/diagnosis_result.dart';
export '../models/raw_inference_output.dart';

/// Lifecycle status for on-device leaf diagnosis operations.
enum DiagnosisStatus {
  /// Provider is ready to accept leaf scans.
  idle,

  /// On-device AI inference, image preprocessing, and evaluation in progress.
  processing,

  /// Leaf diagnosis completed successfully.
  success,

  /// An error occurred during leaf diagnosis.
  error,
}

/// State management provider coordinating on-device leaf diagnosis,
/// LiteRT AI inference, confidence evaluation rules, and treatment guidance lookup.
class DiagnosisProvider extends ChangeNotifier {
  final InferenceService _inferenceService;
  final ConfidenceEvaluationEngine _evaluationEngine;
  final KnowledgeBaseService _knowledgeBaseService;
  final LocalStorageService? localStorageService;
  final HistoryService? historyService;
  final FirestoreSyncService? syncService;
  final Uuid _uuid;

  DiagnosisStatus _status = DiagnosisStatus.idle;
  DiagnosisResult? _currentDiagnosis;
  ConfidenceEvaluationResult? _currentEvaluation;
  RawInferenceOutput? _currentRawOutput;
  String? _errorMessage;
  List<DiagnosisResult> _scanHistory = const [];

  DiagnosisProvider({
    InferenceService? inferenceService,
    ConfidenceEvaluationEngine? evaluationEngine,
    KnowledgeBaseService? knowledgeBaseService,
    this.localStorageService,
    this.historyService,
    this.syncService,
    Uuid? uuid,
  })  : _inferenceService = inferenceService ?? InferenceService(),
        _evaluationEngine = evaluationEngine ?? const ConfidenceEvaluationEngine(),
        _knowledgeBaseService = knowledgeBaseService ?? KnowledgeBaseService(),
        _uuid = uuid ?? const Uuid() {
    loadScanHistory();
  }

  /// Current lifecycle status of the diagnosis pipeline.
  DiagnosisStatus get status => _status;

  /// Whether the provider is in idle state.
  bool get isIdle => _status == DiagnosisStatus.idle;

  /// Whether diagnosis is actively running on device.
  bool get isProcessing => _status == DiagnosisStatus.processing;

  /// Whether the last diagnosis succeeded.
  bool get isSuccess => _status == DiagnosisStatus.success;

  /// Whether the last diagnosis failed with an error.
  bool get isError => _status == DiagnosisStatus.error;

  /// The active [DiagnosisResult] produced by the most recent successful diagnosis.
  DiagnosisResult? get currentDiagnosis => _currentDiagnosis;

  /// The confidence evaluation details produced by [ConfidenceEvaluationEngine].
  ConfidenceEvaluationResult? get currentEvaluation => _currentEvaluation;

  /// Raw LiteRT model probabilities and inference latency details.
  RawInferenceOutput? get currentRawOutput => _currentRawOutput;

  /// Error message if [status] is [DiagnosisStatus.error].
  String? get errorMessage => _errorMessage;

  /// Historical leaf scan records, newest first.
  List<DiagnosisResult> get scanHistory => List.unmodifiable(_scanHistory);

  /// Executes the on-device leaf diagnosis flow:
  /// 1. Preprocesses image and runs LiteRT inference via [InferenceService].
  /// 2. Evaluates confidence brackets and crop context via [ConfidenceEvaluationEngine].
  /// 3. Attaches verified cultural treatment steps via [KnowledgeBaseService].
  /// 4. Generates an immutable [DiagnosisResult] and optionally persists to local history.
  Future<DiagnosisResult> diagnoseLeaf(
    File imageFile,
    Crop selectedCrop, {
    bool saveToHistory = true,
  }) async {
    _status = DiagnosisStatus.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!imageFile.existsSync()) {
        throw ArgumentError('Image file does not exist at: ${imageFile.path}');
      }

      // 1. Ensure KnowledgeBaseService is initialized
      if (!_knowledgeBaseService.isInitialized) {
        await _knowledgeBaseService.init();
      }

      // 2. Ensure InferenceService is initialized
      if (!_inferenceService.isInitialized) {
        await _inferenceService.initialize();
      }

      // 3. Run on-device LiteRT inference
      final rawOutput = await _inferenceService.runInference(imageFile);
      _currentRawOutput = rawOutput;

      // 4. Evaluate confidence thresholds (PRD 7.6) and crop context
      final evaluation = _evaluationEngine.evaluate(
        rawOutput: rawOutput,
        selectedCrop: selectedCrop,
      );
      _currentEvaluation = evaluation;

      // 5. Look up verified treatment guidance if disease name is asserted
      TreatmentGuidance? guidance;
      if (evaluation.predictedDiseaseId != null && !evaluation.isHealthy) {
        guidance = _knowledgeBaseService.getGuidanceByDiseaseId(
          evaluation.predictedDiseaseId!,
        );
      }

      // 6. Determine localized names and infection severity
      final String diseaseNameEn;
      final String diseaseNameHi;
      final SeverityLevel severity;

      if (guidance != null) {
        diseaseNameEn = guidance.nameEn;
        diseaseNameHi = guidance.nameHi;
        severity = guidance.severity;
      } else if (evaluation.isHealthy) {
        diseaseNameEn = 'Healthy Plant';
        diseaseNameHi = 'स्वस्थ पौधा';
        severity = SeverityLevel.low;
      } else if (evaluation.isCropMismatch) {
        diseaseNameEn = 'Crop Mismatch Detected';
        diseaseNameHi = 'फसल बेमेल पहचानी गई';
        severity = SeverityLevel.low;
      } else {
        // Uncertain diagnosis (confidence < 60% per PRD 7.6: no disease name asserted)
        diseaseNameEn = 'Uncertain Diagnosis';
        diseaseNameHi = 'निदान अनिश्चित';
        severity = SeverityLevel.medium;
      }

      // 7. Create DiagnosisResult domain model
      final diagnosis = DiagnosisResult(
        id: _uuid.v4(),
        cropId: selectedCrop.id,
        diseaseId: evaluation.predictedDiseaseId ?? '${selectedCrop.id}_uncertain',
        diseaseNameEn: diseaseNameEn,
        diseaseNameHi: diseaseNameHi,
        confidenceScore: evaluation.confidenceScore,
        severity: severity,
        timestamp: DateTime.now(),
        localImagePath: imageFile.path,
        guidance: guidance,
      );

      _currentDiagnosis = diagnosis;
      _status = DiagnosisStatus.success;

      // 8. Auto-persist to offline history if enabled
      if (saveToHistory) {
        if (historyService != null) {
          await historyService!.saveScan(diagnosis);
          _scanHistory = await historyService!.getAllScans();
        } else if (localStorageService != null) {
          await localStorageService!.addOfflineScan(diagnosis);
          _scanHistory = localStorageService!.getOfflineScans();
        }
        _triggerCloudSync();
      }

      notifyListeners();
      return diagnosis;
    } catch (e) {
      _status = DiagnosisStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _triggerCloudSync() {
    try {
      final sync = syncService ?? FirestoreSyncService();
      sync.syncPendingScans().catchError((e) {
        debugPrint('DiagnosisProvider: Background sync note: $e');
        return const SyncResult(status: SyncStatus.error);
      });
    } catch (e) {
      debugPrint('DiagnosisProvider: Cloud sync initiation error: $e');
    }
  }

  /// Reloads offline scan history from [HistoryService] or [LocalStorageService].
  void loadScanHistory() {
    if (historyService != null) {
      historyService!.getAllScans().then((scans) {
        _scanHistory = scans;
        notifyListeners();
      }).catchError((_) {});
    } else if (localStorageService != null) {
      _scanHistory = localStorageService!.getOfflineScans();
      notifyListeners();
    }
  }

  /// Deletes a scan from local offline storage and refreshes history.
  Future<void> deleteScan(String scanId) async {
    if (historyService != null) {
      await historyService!.deleteScan(scanId);
      loadScanHistory();
    } else if (localStorageService != null) {
      await localStorageService!.deleteOfflineScan(scanId);
      loadScanHistory();
    }
  }

  /// Resets the provider back to [DiagnosisStatus.idle] and clears active scan results.
  void reset() {
    _status = DiagnosisStatus.idle;
    _currentDiagnosis = null;
    _currentEvaluation = null;
    _currentRawOutput = null;
    _errorMessage = null;
    notifyListeners();
  }
}
