import 'package:firebase_core/firebase_core.dart';
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

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAC4TfDM4RoHkDnogdP_gPwJ1CtLkQc_xg',
    appId: '1:514105496890:web:a4d37f6aefa8465f1e2c03',
    messagingSenderId: '514105496890',
    projectId: 'jamboo-ee445',
    authDomain: 'jamboo-ee445.firebaseapp.com',
    storageBucket: 'jamboo-ee445.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOvDnUwPF_zRxuUTi4XdW0Xbbn6cKUgzg',
    appId: '1:514105496890:android:c4058674fdbe65161e2c03',
    messagingSenderId: '514105496890',
    projectId: 'jamboo-ee445',
    storageBucket: 'jamboo-ee445.firebasestorage.app',
  );
}