// DefaultFirebaseOptions for FoundIt Application
// Configured from Firebase google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7MHJYcieASePHk34v_XzbQHFt6o1C8gY',
    appId: '1:519371653363:web:0000000000000000000000',
    messagingSenderId: '519371653363',
    projectId: 'foundit-6bc8a',
    storageBucket: 'foundit-6bc8a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7MHJYcieASePHk34v_XzbQHFt6o1C8gY',
    appId: '1:519371653363:android:bd6d850a26e553d1957786',
    messagingSenderId: '519371653363',
    projectId: 'foundit-6bc8a',
    storageBucket: 'foundit-6bc8a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7MHJYcieASePHk34v_XzbQHFt6o1C8gY',
    appId: '1:519371653363:ios:0000000000000000000000',
    messagingSenderId: '519371653363',
    projectId: 'foundit-6bc8a',
    storageBucket: 'foundit-6bc8a.firebasestorage.app',
    iosBundleId: 'com.savitha.foundit_app',
  );
}
