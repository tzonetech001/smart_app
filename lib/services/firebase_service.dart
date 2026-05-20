import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  /// Initializes Firebase for the current platform.
  ///
  /// Make sure your Firebase config values in `lib/firebase_options.dart`
  /// are replaced with the values from your Firebase project.
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
