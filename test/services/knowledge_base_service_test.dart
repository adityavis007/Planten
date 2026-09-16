import 'package:flutter_test/flutter_test.dart';
import 'package:planten/services/knowledge_base_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KnowledgeBaseService service;

  setUp(() {
    service = KnowledgeBaseService();
  });

  test('KnowledgeBaseService loads data and queries correctly', () async {
    // Note: In a real flutter test, rootBundle.loadString looks into the assets defined in pubspec.yaml.
    // However, during 'flutter test', it might need the files to be accessible.
    // For the sake of this task, we assume the asset is present as per Task 10.
    
    // We can manually populate the service or use a mock if needed, 
    // but the task is to verify it loads the json.
    
    // Since we are running in the IDE environment, let's try to initialize.
    // If it fails due to rootBundle not being available in pure unit tests, 
    // we might need to refactor to accept a bundle or use a mock.
    
    await service.init();
    
    final guidance = service.getGuidanceByDiseaseId('tomato_early_blight');
    expect(guidance, isNotNull);
    expect(guidance?.diseaseId, 'tomato_early_blight');
    expect(guidance?.crop, 'tomato');

    final tomatoGuidance = service.getGuidanceForCrop('tomato');
    expect(tomatoGuidance.isNotEmpty, true);
    expect(tomatoGuidance.any((e) => e.diseaseId == 'tomato_early_blight'), true);
  });

  test('KnowledgeBaseService returns null for non-existent disease', () async {
    await service.init();
    final guidance = service.getGuidanceByDiseaseId('non_existent');
    expect(guidance, isNull);
  });
}
