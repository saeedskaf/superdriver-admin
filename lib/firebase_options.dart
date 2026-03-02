import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Placeholder – run `flutterfire configure` to regenerate this file
/// with your own Firebase project credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4z03VI9MJ0S-_PcHJeVSTpyxB6oEnPUM',
    appId: '1:1033397193331:android:2bd71c754bb909c364b806',
    messagingSenderId: '1033397193331',
    projectId: 'superdriver-narj',
    storageBucket: 'superdriver-narj.firebasestorage.app',
  );

  // Generated Firebase options for this project.

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDhw8sew3XKyQL-3fNiuj2FlrciJeDCbLM',
    appId: '1:1033397193331:ios:bfd0cd05543d7f8b64b806',
    messagingSenderId: '1033397193331',
    projectId: 'superdriver-narj',
    storageBucket: 'superdriver-narj.firebasestorage.app',
    iosBundleId: 'com.narj.superdriver.admin',
  );

}
