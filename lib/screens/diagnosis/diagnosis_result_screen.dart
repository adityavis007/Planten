/// Diagnosis result screen forwarder.
///
/// Re-exports the full [ResultScreen] implementation from `lib/screens/result/result_screen.dart`
/// to support alternate architectural module naming.
library;

export '../result/result_screen.dart';

import '../result/result_screen.dart';

/// Semantic alias for [ResultScreen].
typedef DiagnosisResultScreen = ResultScreen;
