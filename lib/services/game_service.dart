import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/game_model.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all games
  Future<List<GameModel>> getAllGames() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.gamesCollection)
          .get();
      
      return snapshot.docs
          .map((doc) => GameModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting games: ${e.toString()}');
    }
  }

  // Get popular games
  Future<List<GameModel>> getPopularGames() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.gamesCollection)
          .limit(5)
          .get();
      
      return snapshot.docs
          .map((doc) => GameModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting popular games: ${e.toString()}');
    }
  }

  // Get a game by ID
  Future<GameModel> getGameById(String gameId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Game not found');
      }
      
      return GameModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Error getting game: ${e.toString()}');
    }
  }

  // Search for games by name
  Future<List<GameModel>> searchGames(String query) async {
    try {
      // Get all games
      final List<GameModel> allGames = await getAllGames();
      
      if (query.isEmpty) {
        return allGames;
      }
      
      // Filter games by name containing the query
      final String lowerQuery = query.toLowerCase();
      return allGames
          .where((game) => game.name.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('Error searching games: ${e.toString()}');
    }
  }

  // Add a new game
  Future<GameModel> addGame({
    required String name,
    required int minPlayers,
    int? maxPlayers,
    required List<String> platforms,
    String? imageUrl,
  }) async {
    try {
      // Create a reference to a new document with auto-generated ID
      final DocumentReference docRef = _firestore.collection(AppConstants.gamesCollection).doc();
      
      final GameModel newGame = GameModel(
        id: docRef.id,
        name: name,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        platforms: platforms,
        imageUrl: imageUrl,
      );
      
      // Save the game to Firestore
      await docRef.set(newGame.toMap());
      
      return newGame;
    } catch (e) {
      throw Exception('Error adding game: ${e.toString()}');
    }
  }

  // Update a game
  Future<GameModel> updateGame({
    required String gameId,
    String? name,
    int? minPlayers,
    int? maxPlayers,
    List<String>? platforms,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (minPlayers != null) updates['minPlayers'] = minPlayers;
      if (maxPlayers != null) updates['maxPlayers'] = maxPlayers;
      if (platforms != null) updates['platforms'] = platforms;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      
      await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .update(updates);
      
      return await getGameById(gameId);
    } catch (e) {
      throw Exception('Error updating game: ${e.toString()}');
    }
  }

  // Delete a game
  Future<void> deleteGame(String gameId) async {
    try {
      await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting game: ${e.toString()}');
    }
  }

  // Initialize default games if none exist
  Future<void> initializeDefaultGames() async {
    try {
      // Check if games collection is empty
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.gamesCollection)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        // Games already exist, no need to initialize
        return;
      }
      
      // Add default games
      for (final gameData in AppConstants.defaultGames) {
        final GameModel game = GameModel(
          id: '',
          name: gameData['name'] as String,
          minPlayers: gameData['minPlayers'] as int,
          maxPlayers: gameData['maxPlayers'] as int?,
          platforms: List<String>.from(gameData['platforms'] as List),
          imageUrl: gameData['imageUrl'] as String?,
        );
        
        await _firestore
            .collection(AppConstants.gamesCollection)
            .add(game.toMap());
      }
    } catch (e) {
      throw Exception('Error initializing default games: ${e.toString()}');
    }
  }
} 