import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/treatment_guidance.dart';

class KnowledgeBaseService {
  List<TreatmentGuidance> _guidanceList;

  KnowledgeBaseService({List<TreatmentGuidance>? initialGuidance})
      : _guidanceList = initialGuidance ?? [];

  bool get isInitialized => _guidanceList.isNotEmpty;

  Future<void> init() async {
    if (_guidanceList.isNotEmpty) return;
    try {
      final String response = await rootBundle.loadString('assets/knowledge_base/treatment_data.json');
      final List<dynamic> data = json.decode(response);
      _guidanceList = data.map((json) => TreatmentGuidance.fromJson(json)).toList();
    } catch (e) {
      // In production, we might want to log this to a crash reporting service.
      debugPrint('Error loading knowledge base: $e');
      _guidanceList = [];
    }
  }

  TreatmentGuidance? getGuidanceByDiseaseId(String diseaseId) {
    try {
      return _guidanceList.firstWhere((item) => item.diseaseId == diseaseId);
    } catch (e) {
      return null;
    }
  }

  List<TreatmentGuidance> getGuidanceForCrop(String cropId) {
    return _guidanceList.where((item) => item.crop == cropId).toList();
  }

  /// Unmodifiable view of all guidance items in the knowledge base.
  List<TreatmentGuidance> get allGuidance => List.unmodifiable(_guidanceList);

  /// Searches the knowledge base by disease name, crop, symptoms, or cultural steps.
  /// Supports queries in English or Hindi.
  List<TreatmentGuidance> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return _guidanceList.where((item) {
      return item.nameEn.toLowerCase().contains(q) ||
          item.nameHi.toLowerCase().contains(q) ||
          item.crop.toLowerCase().contains(q) ||
          item.diseaseId.toLowerCase().contains(q) ||
          item.symptomsEn.toLowerCase().contains(q) ||
          item.symptomsHi.toLowerCase().contains(q) ||
          item.culturalStepsEn.any((step) => step.toLowerCase().contains(q)) ||
          item.culturalStepsHi.any((step) => step.toLowerCase().contains(q)) ||
          (item.organicNutritionEn?.toLowerCase().contains(q) ?? false) ||
          (item.organicNutritionHi?.toLowerCase().contains(q) ?? false) ||
          (item.fertilizerClassEn?.toLowerCase().contains(q) ?? false) ||
          (item.fertilizerClassHi?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
