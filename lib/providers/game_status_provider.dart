import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';
import '../models/game_status_model.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';

class GameStatusProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  
  List<GameModel> _allGames = [];
  List<GameStatusModel> _userGameStatuses = [];
  List<UserModel> _usersDownToPlay = [];
  bool _isLoading = false;
  String? _error;
  
  // Mock data storage
  static final Map<String, Map<String, GameStatusModel>> _mockStatusStorage = {};
  
  // Getters
  List<GameModel> get allGames => _allGames;
  List<GameStatusModel> get userGameStatuses => _userGameStatuses;
  List<UserModel> get usersDownToPlay => _usersDownToPlay;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Lazy initialization of Firestore
  FirebaseFirestore _getFirestore() {
    if (FirebaseService.isMockMode) {
      throw Exception('Firestore is not available in mock mode');
    }
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }
  
  // Load all games
  Future<void> loadAllGames() async {
    if (_allGames.isNotEmpty) return;
    
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, create mock games
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _allGames = AppConstants.defaultGames.map((gameData) {
        return GameModel(
          id: gameData['name'].toString().toLowerCase().replaceAll(' ', '_'),
          name: gameData['name'] as String,
          minPlayers: gameData['minPlayers'] as int,
          maxPlayers: gameData['maxPlayers'] as int?,
          platforms: List<String>.from(gameData['platforms'] as List),
          imageUrl: gameData['imageUrl'] as String?,
        );
      }).toList();
      _setLoading(false);
      return;
    }
    
    try {
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.gamesCollection)
          .get();
      
      _allGames = querySnapshot.docs
          .map((doc) => GameModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading games: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Initialize default games if none exist
  Future<void> initializeDefaultGames() async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, just load the default games
      await loadAllGames();
      return;
    }
    
    try {
      // Check if games collection is empty
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.gamesCollection)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Add default games
        for (final gameData in AppConstants.defaultGames) {
          final game = GameModel(
            id: gameData['name'].toString().toLowerCase().replaceAll(' ', '_'),
            name: gameData['name'] as String,
            minPlayers: gameData['minPlayers'] as int,
            maxPlayers: gameData['maxPlayers'] as int?,
            platforms: List<String>.from(gameData['platforms'] as List),
            imageUrl: gameData['imageUrl'] as String?,
          );
          
          await _getFirestore()
              .collection(AppConstants.gamesCollection)
              .doc(game.id)
              .set(game.toMap());
        }
      }
      
      // Load all games
      await loadAllGames();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing default games: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load user's game statuses
  Future<void> loadUserGameStatuses(String userId) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, create mock statuses
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _userGameStatuses = [];
      _setLoading(false);
      return;
    }
    
    try {
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.gameStatusCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      _userGameStatuses = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data == null) return null;
            return GameStatusModel.fromMap({
              ...data,
              'id': doc.id,
            });
          })
          .where((status) => status != null)
          .cast<GameStatusModel>()
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user game statuses: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Get a specific game status
  Future<GameStatusModel?> getGameStatus(String userId, String gameId) async {
    if (FirebaseService.isMockMode) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      return _mockStatusStorage[userId]?[gameId];
    }
    
    try {
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.gameStatusCollection)
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      if (data == null) return null;
      
      return GameStatusModel.fromMap({
        ...Map<String, dynamic>.from(data),
        'id': querySnapshot.docs.first.id,
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting game status: $_error');
      return null;
    }
  }
  
  // Set a game status
  Future<bool> setGameStatus({
    required String userId,
    required String gameId,
    required bool isDown,
    required List<String> downForGroups,
    DateTime? availableUntil,
    String? note,
  }) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      // Initialize user's status map if it doesn't exist
      _mockStatusStorage[userId] ??= {};
      
      // Create or update the status
      final status = GameStatusModel(
        id: 'mock-status-$userId-$gameId',
        userId: userId,
        gameId: gameId,
        isDown: isDown,
        downForGroups: List.from(downForGroups), // Create a copy to prevent reference issues
        availableUntil: availableUntil,
        note: note,
        createdAt: _mockStatusStorage[userId]?[gameId]?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Store the status
      _mockStatusStorage[userId]![gameId] = status;
      
      // Update the local list if this user's statuses are loaded
      final existingIndex = _userGameStatuses.indexWhere(
        (s) => s.userId == userId && s.gameId == gameId,
      );
      
      if (existingIndex >= 0) {
        _userGameStatuses[existingIndex] = status;
      } else {
        _userGameStatuses.add(status);
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    }
    
    try {
      final docRef = _getFirestore()
          .collection(AppConstants.gameStatusCollection)
          .doc('${userId}_${gameId}');

      final data = {
        'userId': userId,
        'gameId': gameId,
        'isDown': isDown,
        'downForGroups': downForGroups,
        'availableUntil': availableUntil?.toIso8601String(),
        'note': note,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update(data);
      } else {
        data['createdAt'] = DateTime.now().toIso8601String();
        await docRef.set(data);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error setting game status: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load users who are down to play a specific game in a group
  Future<void> loadUsersDownToPlay(String groupId, String gameId) async {
    _setLoading(true);
    _error = null;
    _usersDownToPlay = [];
    
    if (FirebaseService.isMockMode) {
      // In mock mode, create mock users
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _usersDownToPlay = [];
      _setLoading(false);
      return;
    }
    
    try {
      // Get the group
      final groupDoc = await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!groupDoc.exists) {
        _error = 'Group not found';
        return;
      }
      
      final List<String> members = List<String>.from(groupDoc.data()?['members'] ?? []);
      
      // Get game statuses for this game
      final statusesSnapshot = await _getFirestore()
          .collection(AppConstants.gameStatusCollection)
          .where('gameId', isEqualTo: gameId)
          .where('isDown', isEqualTo: true)
          .where('userId', whereIn: members)
          .get();
      
      if (statusesSnapshot.docs.isEmpty) {
        return;
      }
      
      // Get user IDs who are down to play
      final List<String> userIds = statusesSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
      
      // Get user details
      final usersSnapshot = await _getFirestore()
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      
      _usersDownToPlay = usersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading users down to play: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<List<GameStatusModel>> getGroupGameStatuses(String groupId) async {
    try {
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.gameStatusCollection)
          .where('downForGroups', arrayContains: groupId)
          .where('isDown', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GameStatusModel.fromMap({
              ...Map<String, dynamic>.from(data),
              'id': doc.id,
            });
          })
          .where((status) => status != null)
          .cast<GameStatusModel>()
          .toList();
    } catch (e) {
      print('Error getting group game statuses: $e');
      return [];
    }
  }

  Future<List<GameStatusModel>> getUserGameStatuses(String userId) async {
    try {
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.gameStatusCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GameStatusModel.fromMap({
              ...Map<String, dynamic>.from(data),
              'id': doc.id,
            });
          })
          .where((status) => status != null)
          .cast<GameStatusModel>()
          .toList();
    } catch (e) {
      print('Error getting user game statuses: $e');
      return [];
    }
  }
} 