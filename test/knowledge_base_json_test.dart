import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Treatment Knowledge Base JSON Verification (Task 10)', () {
    late List<dynamic> data;

    setUpAll(() {
      final file = File('assets/knowledge_base/treatment_data.json');
      expect(file.existsSync(), isTrue, reason: 'treatment_data.json must exist');
      final rawContent = file.readAsStringSync();
      data = jsonDecode(rawContent) as List<dynamic>;
    });

    test('Contains at least 8 crop-disease combinations', () {
      expect(data.length, greaterThanOrEqualTo(8));
      expect(data.length, equals(15));
    });

    test('Validates all required fields for each entry', () {
      final allowedCategories = {'fungal', 'viral', 'bacterial', 'pest', 'healthy'};
      final allowedSeverities = {'low', 'medium', 'high'};

      for (final item in data) {
        final entry = item as Map<String, dynamic>;
        
        expect(entry['disease_id'], isNotEmpty, reason: 'disease_id cannot be empty');
        expect(entry['crop'], isNotEmpty, reason: 'crop cannot be empty');
        expect(entry['name_en'], isNotEmpty, reason: 'name_en cannot be empty');
        expect(entry['name_hi'], isNotEmpty, reason: 'name_hi cannot be empty');
        expect(entry['symptoms_en'], isNotEmpty, reason: 'symptoms_en cannot be empty');
        expect(entry['symptoms_hi'], isNotEmpty, reason: 'symptoms_hi cannot be empty');
        
        final stepsEn = entry['cultural_steps_en'] as List;
        expect(stepsEn.length, greaterThanOrEqualTo(2), reason: 'cultural_steps_en must have >= 2 items');
        
        final stepsHi = entry['cultural_steps_hi'] as List;
        expect(stepsHi.length, greaterThanOrEqualTo(2), reason: 'cultural_steps_hi must have >= 2 items');
        
        expect(allowedCategories.contains(entry['management_category']), isTrue, 
            reason: 'Invalid category: ${entry['management_category']}');
        expect(allowedSeverities.contains(entry['severity_level']), isTrue,
            reason: 'Invalid severity: ${entry['severity_level']}');
        
        expect(entry['disclaimer_en'], isNotEmpty);
        expect(entry['disclaimer_hi'], isNotEmpty);
      }
    });

    test('Guarantees all 5 launch crops are represented', () {
      final crops = data.map((e) => (e as Map<String, dynamic>)['crop']).toSet();
      expect(crops, containsAll(['tomato', 'potato', 'wheat', 'chili', 'cotton']));
    });

    test('Ensures strict PRD constraint: No chemical dosages or commercial brands prescribed', () {
      // Forbidden terms that would suggest unauthorized chemical dosage or specific pesticide brands
      final forbiddenTerms = ['ml/l', 'g/l', 'gm/acre', 'bavistin', 'monocrotophos', 'chlorpyrifos', 'carbendazim 50%'];
      
      for (final item in data) {
        final entry = item as Map<String, dynamic>;
        final combinedText = jsonEncode(entry).toLowerCase();
        
        for (final term in forbiddenTerms) {
          expect(combinedText.contains(term), isFalse, 
              reason: 'Entry ${entry['disease_id']} contains prohibited prescription phrase: $term');
        }
      }
    });
  });
}
