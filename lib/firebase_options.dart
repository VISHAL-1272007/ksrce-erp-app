import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for the KSRCE-CAMPUS-ERP project.
///
/// Generated manually from the Firebase web config provided in chat.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are configured for the web app only. '
          'Please add Android/iOS/Desktop Firebase config if you plan to run on this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnBvm51xQtO87_qY1W8eViJNCxaOlBTBA',
    appId: '1:709654657509:web:de8ad504795fceebf9570c',
    messagingSenderId: '709654657509',
    projectId: 'ksrce-campus-erp',
    authDomain: 'ksrce-campus-erp.firebaseapp.com',
    storageBucket: 'ksrce-campus-erp.firebasestorage.app',
    measurementId: 'G-70KBETLD0P',
    databaseURL: 'https://ksrce-campus-erp-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
}
