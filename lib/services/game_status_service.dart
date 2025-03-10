import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/game_status_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

class GameStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Set a user's status for a game
  Future<void> setGameStatus({
    required String userId,
    required String gameId,
    required bool isDown,
    DateTime? availableUntil,
    String? note,
  }) async {
    try {
      final DateTime now = DateTime.now();
      
      // Create the game status object
      final GameStatusModel gameStatus = GameStatusModel(
        id: 'temp-id', // This will be replaced by Firestore
        userId: userId,
        gameId: gameId,
        isDown: isDown,
        availableUntil: availableUntil,
        note: note,
        createdAt: now,
        updatedAt: now,
      );
      
      // Check if status already exists
      final QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.gameStatusCollection)
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Update existing status
        final String docId = querySnapshot.docs.first.id;
        await _firestore
            .collection(AppConstants.gameStatusCollection)
            .doc(docId)
            .update(gameStatus.toMap());
      } else {
        // Create new status
        await _firestore
            .collection(AppConstants.gameStatusCollection)
            .add(gameStatus.toMap());
      }
      
      // Update user's last active timestamp
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'lastActive': now.toIso8601String()});
    } catch (e) {
      throw Exception('Error setting game status: ${e.toString()}');
    }
  }

  // Get a user's status for a game
  Future<GameStatusModel?> getGameStatus(String userId, String gameId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.gameStatusCollection)
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      return GameStatusModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Error getting game status: ${e.toString()}');
    }
  }

  // Get users who are down to play a specific game in a group
  Future<List<UserModel>> getUsersDownToPlay(String groupId, String gameId) async {
    try {
      // Get the group
      final DocumentSnapshot groupDoc = await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }
      
      final GroupModel group = GroupModel.fromMap(
        groupDoc.data() as Map<String, dynamic>,
        groupId,
      );
      
      // Get game statuses for this game
      final QuerySnapshot statusesSnapshot = await _firestore
          .collection(AppConstants.gameStatusCollection)
          .where('gameId', isEqualTo: gameId)
          .where('isDown', isEqualTo: true)
          .where('userId', whereIn: group.members)
          .get();
      
      if (statusesSnapshot.docs.isEmpty) {
        return [];
      }
      
      // Get user IDs who are down to play
      final List<String> userIds = statusesSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String)
          .toList();
      
      // Get user details
      final QuerySnapshot usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      
      return usersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting users down to play: ${e.toString()}');
    }
  }

  // Check if enough users are down to play a game in a group
  Future<bool> checkIfSquadReady(String groupId, String gameId) async {
    try {
      // Get the game status
      final QuerySnapshot gameSnapshot = await _firestore
          .collection(AppConstants.gamesCollection)
          .where(FieldPath.documentId, isEqualTo: gameId)
          .limit(1)
          .get();
      
      if (gameSnapshot.docs.isEmpty) {
        throw Exception('Game not found');
      }
      
      final int minPlayers = (gameSnapshot.docs.first.data() as Map<String, dynamic>)['minPlayers'] as int;
      
      // Get users down to play
      final List<UserModel> usersDownToPlay = await getUsersDownToPlay(groupId, gameId);
      
      // Check if we have enough players
      return usersDownToPlay.length >= minPlayers;
    } catch (e) {
      throw Exception('Error checking if squad is ready: ${e.toString()}');
    }
  }

  // Send notification to group members when enough players are ready
  Future<void> notifySquadReady(String groupId, String gameId) async {
    try {
      // Get the group
      final DocumentSnapshot groupDoc = await _firestore
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }
      
      final GroupModel group = GroupModel.fromMap(
        groupDoc.data() as Map<String, dynamic>,
        groupId,
      );
      
      // Get the game
      final DocumentSnapshot gameDoc = await _firestore
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .get();
      
      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }
      
      final String gameName = (gameDoc.data() as Map<String, dynamic>)['name'] as String;
      
      // Get users down to play
      final List<UserModel> usersDownToPlay = await getUsersDownToPlay(groupId, gameId);
      
      // Create a notification document
      await _firestore.collection('notifications').add({
        'type': AppConstants.squadReadyNotification,
        'groupId': groupId,
        'gameId': gameId,
        'gameName': gameName,
        'groupName': group.name,
        'usersDownToPlay': usersDownToPlay.map((user) => user.id).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
      });
      
      // In a real app, you would also send push notifications here
    } catch (e) {
      throw Exception('Error notifying squad ready: ${e.toString()}');
    }
  }

  // Clean up expired game statuses
  Future<void> cleanupExpiredStatuses() async {
    try {
      final DateTime now = DateTime.now();
      
      // Get all users
      final QuerySnapshot usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      
      for (final doc in usersSnapshot.docs) {
        final UserModel user = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        // Get all game statuses for this user
        final QuerySnapshot statusesSnapshot = await _firestore
            .collection(AppConstants.gameStatusCollection)
            .where('userId', isEqualTo: user.id)
            .where('isDown', isEqualTo: true)
            .get();
        
        for (final statusDoc in statusesSnapshot.docs) {
          final GameStatusModel status = GameStatusModel.fromMap(
            statusDoc.data() as Map<String, dynamic>,
            statusDoc.id,
          );
          
          // Check if status has expired
          if (status.availableUntil != null && status.availableUntil!.isBefore(now)) {
            // Update status to not down
            await _firestore
                .collection(AppConstants.gameStatusCollection)
                .doc(statusDoc.id)
                .update({
              'isDown': false,
              'updatedAt': now.toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      throw Exception('Error cleaning up expired statuses: ${e.toString()}');
    }
  }
} 