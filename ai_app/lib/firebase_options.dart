/// Firebase configuration generated from the user's Firebase project
/// Project: ai-informal-economy
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux — '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHalvB9gnKpuaHoLA4fkehLqx0nVh78Ew',
    authDomain: 'ai-informal-economy.firebaseapp.com',
    projectId: 'ai-informal-economy',
    storageBucket: 'ai-informal-economy.firebasestorage.app',
    databaseURL: 'https://ai-informal-economy-default-rtdb.firebaseio.com/',
    messagingSenderId: '703282634663',
    appId: '1:703282634663:web:267fd240a7750ba92a6082',
    measurementId: 'G-GZBP67HTQ8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHalvB9gnKpuaHoLA4fkehLqx0nVh78Ew',
    authDomain: 'ai-informal-economy.firebaseapp.com',
    projectId: 'ai-informal-economy',
    storageBucket: 'ai-informal-economy.firebasestorage.app',
    databaseURL: 'https://ai-informal-economy-default-rtdb.firebaseio.com/',
    messagingSenderId: '703282634663',
    appId: '1:703282634663:web:267fd240a7750ba92a6082',
    measurementId: 'G-GZBP67HTQ8',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHalvB9gnKpuaHoLA4fkehLqx0nVh78Ew',
    authDomain: 'ai-informal-economy.firebaseapp.com',
    projectId: 'ai-informal-economy',
    storageBucket: 'ai-informal-economy.firebasestorage.app',
    databaseURL: 'https://ai-informal-economy-default-rtdb.firebaseio.com/',
    messagingSenderId: '703282634663',
    appId: '1:703282634663:web:267fd240a7750ba92a6082',
    measurementId: 'G-GZBP67HTQ8',
    iosClientId: '',
    iosBundleId: 'com.example.aiApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCHalvB9gnKpuaHoLA4fkehLqx0nVh78Ew',
    authDomain: 'ai-informal-economy.firebaseapp.com',
    projectId: 'ai-informal-economy',
    storageBucket: 'ai-informal-economy.firebasestorage.app',
    databaseURL: 'https://ai-informal-economy-default-rtdb.firebaseio.com/',
    messagingSenderId: '703282634663',
    appId: '1:703282634663:web:267fd240a7750ba92a6082',
    measurementId: 'G-GZBP67HTQ8',
    iosClientId: '',
    iosBundleId: 'com.example.aiApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCHalvB9gnKpuaHoLA4fkehLqx0nVh78Ew',
    authDomain: 'ai-informal-economy.firebaseapp.com',
    projectId: 'ai-informal-economy',
    storageBucket: 'ai-informal-economy.firebasestorage.app',
    databaseURL: 'https://ai-informal-economy-default-rtdb.firebaseio.com/',
    messagingSenderId: '703282634663',
    appId: '1:703282634663:web:267fd240a7750ba92a6082',
    measurementId: 'G-GZBP67HTQ8',
  );
}
