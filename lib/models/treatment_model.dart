/// Treatment model interoperability export.
///
/// Exports the complete [TreatmentGuidance] domain model and provides
/// a [TreatmentModel] alias for unified naming conventions across modules.
library;

export 'treatment_guidance.dart';

import 'treatment_guidance.dart';

/// Semantic type alias for [TreatmentGuidance].
typedef TreatmentModel = TreatmentGuidance;
