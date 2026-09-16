import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the Planten application.
///
/// Generated based on project credentials in `android/app/google-services.json`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaGf9SbdFROmrPV5_A-xiW15axSXvT4KQ',
    appId: '1:504521081852:android:0a433c03a22c2579256879',
    messagingSenderId: '504521081852',
    projectId: 'planten-16301',
    storageBucket: 'planten-16301.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAaGf9SbdFROmrPV5_A-xiW15axSXvT4KQ',
    appId: '1:504521081852:ios:0a433c03a22c2579256879',
    messagingSenderId: '504521081852',
    projectId: 'planten-16301',
    storageBucket: 'planten-16301.firebasestorage.app',
    iosBundleId: 'com.example.planten',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAaGf9SbdFROmrPV5_A-xiW15axSXvT4KQ',
    appId: '1:504521081852:web:0a433c03a22c2579256879',
    messagingSenderId: '504521081852',
    projectId: 'planten-16301',
    storageBucket: 'planten-16301.firebasestorage.app',
  );
}
