import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'This app is not configured for Firebase on $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_WEB'),
    appId: '1:528435356261:web:03f476710078c8ba515c8c',
    messagingSenderId: '528435356261',
    projectId: 'campuscan-e5678',
    authDomain: 'campuscan-e5678.firebaseapp.com',
    storageBucket: 'campuscan-e5678.firebasestorage.app',
    measurementId: 'G-FGH25ZRVEM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_ANDROID'),
    appId: '1:528435356261:android:1155a9f819c02ff9515c8c',
    messagingSenderId: '528435356261',
    projectId: 'campuscan-e5678',
    storageBucket: 'campuscan-e5678.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_IOS'),
    appId: '1:528435356261:ios:4d2256e3e984cc15515c8c',
    messagingSenderId: '528435356261',
    projectId: 'campuscan-e5678',
    storageBucket: 'campuscan-e5678.firebasestorage.app',
    iosBundleId: 'com.example.awx',
  );

  // FlutterFire uses the Apple app registration for macOS when the bundle ID
  // matches the Apple app registered in Firebase.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_MACOS'),
    appId: '1:528435356261:ios:4d2256e3e984cc15515c8c',
    messagingSenderId: '528435356261',
    projectId: 'campuscan-e5678',
    storageBucket: 'campuscan-e5678.firebasestorage.app',
    iosBundleId: 'com.example.awx',
  );

}
