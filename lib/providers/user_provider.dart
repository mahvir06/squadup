import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';

class UserProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => FirebaseService.isMockMode ? _user != null : _getAuth().currentUser != null;
  
  // Lazy initialization of Firebase services
  FirebaseAuth _getAuth() {
    if (FirebaseService.isMockMode) {
      throw Exception('Firebase Auth is not available in mock mode');
    }
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }
  
  FirebaseFirestore _getFirestore() {
    if (FirebaseService.isMockMode) {
      throw Exception('Firestore is not available in mock mode');
    }
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }
  
  // Initialize user data
  Future<void> initialize() async {
    if (FirebaseService.isMockMode) {
      // In mock mode, create a mock user
      _user = UserModel(
        id: 'mock-user-id',
        email: 'user@example.com',
        username: 'MockUser',
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }
    
    if (_getAuth().currentUser != null) {
      await _fetchUserData(_getAuth().currentUser!.uid);
    }
  }
  
  // Listen to auth state changes
  void listenToAuthChanges() {
    if (FirebaseService.isMockMode) {
      // In mock mode, we don't listen to auth changes
      return;
    }
    
    _getAuth().authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchUserData(user.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }
  
  // Fetch user data from Firestore
  Future<void> _fetchUserData(String userId) async {
    if (FirebaseService.isMockMode) {
      // In mock mode, create a mock user
      _user = UserModel(
        id: 'mock-user-id',
        email: 'user@example.com',
        username: 'MockUser',
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    _error = null;
    
    try {
      final docSnapshot = await _getFirestore()
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (docSnapshot.exists) {
        _user = UserModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      } else {
        _error = 'User data not found';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching user data: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, create a mock user
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _user = UserModel(
        id: 'mock-user-id',
        email: email,
        username: 'MockUser',
        createdAt: DateTime.now(),
      );
      _setLoading(false);
      return true;
    }
    
    try {
      final userCredential = await _getAuth().signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _fetchUserData(userCredential.user!.uid);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'No user found with this email';
          break;
        case 'wrong-password':
          _error = 'Wrong password';
          break;
        case 'invalid-email':
          _error = 'Invalid email format';
          break;
        default:
          _error = e.message ?? 'An error occurred during sign in';
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, create a mock user
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _user = UserModel(
        id: 'mock-user-id',
        email: email,
        username: username,
        createdAt: DateTime.now(),
      );
      _setLoading(false);
      return true;
    }
    
    try {
      // Check if username is already taken
      final usernameQuery = await _getFirestore()
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        _error = 'Username is already taken';
        return false;
      }
      
      // Create user with email and password
      final userCredential = await _getAuth().createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Create user document in Firestore
        final user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          username: username,
          createdAt: DateTime.now(),
        );
        
        await _getFirestore()
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .set(user.toMap());
        
        _user = user;
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'Email is already in use';
          break;
        case 'weak-password':
          _error = 'Password is too weak';
          break;
        case 'invalid-email':
          _error = 'Invalid email format';
          break;
        default:
          _error = e.message ?? 'An error occurred during sign up';
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign out
  Future<bool> signOut() async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, just clear the user
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _user = null;
      _setLoading(false);
      return true;
    }
    
    try {
      await _getAuth().signOut();
      _user = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, just simulate a delay
      await Future.delayed(const Duration(seconds: 1));
      _setLoading(false);
      return true;
    }
    
    try {
      await _getAuth().sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'No user found with this email';
          break;
        case 'invalid-email':
          _error = 'Invalid email format';
          break;
        default:
          _error = e.message ?? 'An error occurred during password reset';
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({
    String? username,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, just update the local user
      await Future.delayed(const Duration(seconds: 1));
      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          email: _user!.email,
          username: username ?? _user!.username,
          photoUrl: photoUrl ?? _user!.photoUrl,
          createdAt: _user!.createdAt,
        );
      }
      _setLoading(false);
      return true;
    }
    
    try {
      if (_user == null) {
        _error = 'User not logged in';
        return false;
      }
      
      // Check if username is already taken (if changing username)
      if (username != null && username != _user!.username) {
        final usernameQuery = await _getFirestore()
            .collection(AppConstants.usersCollection)
            .where('username', isEqualTo: username)
            .get();
        
        if (usernameQuery.docs.isNotEmpty) {
          _error = 'Username is already taken';
          return false;
        }
      }
      
      // Update user document in Firestore
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      await _getFirestore()
          .collection(AppConstants.usersCollection)
          .doc(_user!.id)
          .update(updates);
      
      // Update local user
      _user = UserModel(
        id: _user!.id,
        email: _user!.email,
        username: username ?? _user!.username,
        photoUrl: photoUrl ?? _user!.photoUrl,
        groups: _user!.groups,
        gameStatuses: _user!.gameStatuses,
        createdAt: _user!.createdAt,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
} 