import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlGgz0mY2KhhYLleYFYcnhQMn34FTr03s',
    appId: '1:1055546977704:web:97793ebe6c8f029a5e419d',
    messagingSenderId: '1055546977704',
    projectId: 'smarttuck-845d9',
    authDomain: 'smarttuck-845d9.firebaseapp.com',
    storageBucket: 'smarttuck-845d9.firebasestorage.app',
    measurementId: 'G-BDLBVBV8SQ',
  );
}