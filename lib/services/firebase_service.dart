import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_options.dart';

class FirebaseService {
  static bool _mockMode = false;
  
  // Getter to check if app is in mock mode
  static bool get isMockMode => _mockMode;
  
  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      if (const bool.fromEnvironment('MOCK_MODE', defaultValue: true)) {
        _mockMode = true;
        debugPrint('Running in mock mode with limited features');
        return;
      }
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      _mockMode = true;
      debugPrint('Failed to initialize Firebase: $e');
      debugPrint('Running in mock mode with limited features');
    }
  }
} 