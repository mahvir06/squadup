import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user with email and password
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      
      if (user == null) {
        throw Exception('Failed to create user');
      }
      
      // Create user document in Firestore
      final DateTime now = DateTime.now();
      final UserModel newUser = UserModel(
        id: user.uid,
        username: username,
        email: email,
        photoUrl: null,
        groups: [],
        gameStatuses: {},
        createdAt: now,
        lastActive: now,
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap());
      
      // Save user info to shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, user.uid);
      await prefs.setString(AppConstants.userEmailKey, email);
      await prefs.setBool(AppConstants.userLoggedInKey, true);
      
      return newUser;
    } catch (e) {
      throw Exception('Error signing up: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in user with email and password
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      
      if (user == null) {
        throw Exception('Failed to sign in');
      }
      
      // Update last active timestamp
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'lastActive': DateTime.now().toIso8601String()});
      
      // Get user data from Firestore
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      
      if (!doc.exists) {
        throw Exception('User document does not exist');
      }
      
      final UserModel userData = UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        user.uid,
      );
      
      // Save user info to shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, user.uid);
      await prefs.setString(AppConstants.userEmailKey, email);
      await prefs.setBool(AppConstants.userLoggedInKey, true);
      
      return userData;
    } catch (e) {
      throw Exception('Error signing in: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userEmailKey);
      await prefs.setBool(AppConstants.userLoggedInKey, false);
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error resetting password: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.userLoggedInKey) ?? false;
  }

  // Get user data
  Future<UserModel?> getUserData() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        return null;
      }
      
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
    } catch (e) {
      throw Exception('Error getting user data: ${e.toString()}');
    }
  }
} 