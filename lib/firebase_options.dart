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
          'DefaultFirebaseOptions are not supported for this platform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDuipYmYnoRbc5CS9TewnB2NyD16elrGFY',
    appId: '1:431753014905:web:3ba627769f3b7828892ea8',
    messagingSenderId: '431753014905',
    projectId: 'messageflutterapp-3124e',
    authDomain: 'messageflutterapp-3124e.firebaseapp.com',
    storageBucket: 'messageflutterapp-3124e.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDuipYmYnoRbc5CS9TewnB2NyD16elrGFY',
    appId: '1:431753014905:android:4b61316f17ade433892ea8',
    messagingSenderId: '431753014905',
    projectId: 'messageflutterapp-3124e',
    storageBucket: 'messageflutterapp-3124e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuipYmYnoRbc5CS9TewnB2NyD16elrGFY',
    appId: '1:431753014905:ios:758f1bb288c67f39892ea8',
    messagingSenderId: '431753014905',
    projectId: 'messageflutterapp-3124e',
    storageBucket: 'messageflutterapp-3124e.appspot.com',
    iosBundleId: 'com.example.chattingAppFirebase',
  );
}
