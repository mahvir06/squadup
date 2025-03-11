import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class GroupService {
  FirebaseFirestore? _firestore;
  
  // Static mock storage
  static final List<GroupModel> _mockGroups = [];

  GroupService() {
    if (!FirebaseService.isMockMode) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  // Add a method to add mock group
  static void addMockGroup(GroupModel group) {
    _mockGroups.add(group);
  }

  // Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required String createdBy,
    required List<String> supportedGames,
    required bool isPublic,
    String? imageUrl,
  }) async {
    try {
      // Create a reference to a new document with auto-generated ID
      final DocumentReference docRef = _firestore!.collection(AppConstants.groupsCollection).doc();
      
      final GroupModel newGroup = GroupModel(
        id: docRef.id,
        name: name,
        description: description,
        createdBy: createdBy,
        members: [createdBy], // Creator is automatically a member
        admins: [createdBy],
        enabledGames: supportedGames,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: imageUrl,
      );
      
      // Save the group to Firestore
      await docRef.set(newGroup.toMap());
      
      // Add the group to the user's groups
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(createdBy)
          .update({
        'groups': FieldValue.arrayUnion([docRef.id]),
      });
      
      return newGroup;
    } catch (e) {
      throw Exception('Error creating group: ${e.toString()}');
    }
  }

  // Get a group by ID
  Future<GroupModel> getGroup(String groupId) async {
    if (FirebaseService.isMockMode) {
      // Return mock group data based on the groupId
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      // Mock groups data
      final mockGroups = {
        'group-1': GroupModel(
          id: 'group-1',
          name: 'Casual Gamers',
          description: 'A group for casual gaming sessions',
          createdBy: 'mock-user-id',
          members: ['mock-user-id', 'user-alice', 'user-bob', 'user-charlie'],
          admins: ['mock-user-id'],
          enabledGames: ['valorant', 'minecraft', 'league_of_legends', 'apex_legends'],
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        'group-2': GroupModel(
          id: 'group-2',
          name: 'Competitive Squad',
          description: 'For serious gamers only',
          createdBy: 'user-alice',
          members: ['mock-user-id', 'user-alice', 'user-diana', 'user-evan'],
          admins: ['user-alice', 'mock-user-id'],
          enabledGames: ['league_of_legends', 'valorant', 'apex_legends'],
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      };
      
      // Return the requested group if it exists
      if (mockGroups.containsKey(groupId)) {
        return mockGroups[groupId]!;
      }
      
      throw Exception('Group not found');
    }

    try {
      final DocumentSnapshot doc = await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Group not found');
      }
      
      return GroupModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error getting group: ${e.toString()}');
    }
  }

  // Get all groups for a user
  Future<List<GroupModel>> getUserGroups(String userId) async {
    if (FirebaseService.isMockMode) {
      // Return mock groups
      final mockGroups = [
        GroupModel(
          id: 'group-1',
          name: 'Casual Gamers',
          description: 'A group for casual gaming sessions',
          createdBy: userId,
          members: [userId, 'user-alice', 'user-bob', 'user-charlie'],
          admins: [userId],
          enabledGames: ['valorant', 'minecraft', 'league_of_legends', 'apex_legends'],
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GroupModel(
          id: 'group-2',
          name: 'Competitive Squad',
          description: 'For serious gamers only',
          createdBy: 'user-alice',
          members: [userId, 'user-alice', 'user-diana', 'user-evan'],
          admins: ['user-alice', userId],
          enabledGames: ['league_of_legends', 'valorant', 'apex_legends'],
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      // Add any newly created groups from the mock storage
      mockGroups.addAll(_mockGroups.where((group) => group.members.contains(userId)));
      
      return mockGroups;
    }

    try {
      final DocumentSnapshot userDoc = await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final UserModel user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userId,
      );
      
      if (user.groups.isEmpty) {
        return [];
      }
      
      final QuerySnapshot groupsSnapshot = await _firestore!
          .collection(AppConstants.groupsCollection)
          .where(FieldPath.documentId, whereIn: user.groups)
          .get();
      
      return groupsSnapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting user groups: ${e.toString()}');
    }
  }

  // Update a group
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    List<String>? supportedGames,
    bool? isPublic,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (supportedGames != null) updates['enabledGames'] = supportedGames;
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      updates['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update(updates);
      
      return await getGroup(groupId);
    } catch (e) {
      throw Exception('Error updating group: ${e.toString()}');
    }
  }

  // Add a member to a group
  Future<bool> addMember(String groupId, String userId) async {
    try {
      // Update group members
      await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'members': FieldValue.arrayUnion([userId]),
      });
      
      // Update user's groups
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'groups': FieldValue.arrayUnion([groupId]),
      });
      
      return true;
    } catch (e) {
      throw Exception('Error adding member to group: ${e.toString()}');
    }
  }

  // Remove a member from a group
  Future<bool> removeMember(String groupId, String userId) async {
    try {
      // Update group members
      await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId]),
      });
      
      // Update user's groups
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'groups': FieldValue.arrayRemove([groupId]),
      });
      
      return true;
    } catch (e) {
      throw Exception('Error removing member from group: ${e.toString()}');
    }
  }

  // Search for public groups
  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      QuerySnapshot snapshot;
      
      if (query.isEmpty) {
        // Get all public groups
        snapshot = await _firestore!
            .collection(AppConstants.groupsCollection)
            .where('isPublic', isEqualTo: true)
            .limit(20)
            .get();
      } else {
        // This is a simple implementation and might not be efficient for large datasets
        // For production, consider using a search service like Algolia
        snapshot = await _firestore!
            .collection(AppConstants.groupsCollection)
            .where('isPublic', isEqualTo: true)
            .get();
        
        final List<GroupModel> groups = snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        
        // Filter groups by name or description containing the query
        final String lowercaseQuery = query.toLowerCase();
        return groups.where((group) => 
          group.name.toLowerCase().contains(lowercaseQuery) || 
          group.description.toLowerCase().contains(lowercaseQuery)
        ).toList();
      }
      
      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error searching groups: ${e.toString()}');
    }
  }

  // Get members of a group
  Future<List<UserModel>> getGroupMembers(String groupId) async {
    if (FirebaseService.isMockMode) {
      // Return mock users
      return [
        UserModel(
          id: 'mock-user-id',
          email: 'you@example.com',
          username: 'You',
          photoUrl: null,
          groups: ['group-1', 'group-2'],
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'user-alice',
          email: 'alice@example.com',
          username: 'Alice',
          photoUrl: null,
          groups: ['group-1', 'group-2'],
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'user-bob',
          email: 'bob@example.com',
          username: 'Bob',
          photoUrl: null,
          groups: ['group-1'],
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'user-charlie',
          email: 'charlie@example.com',
          username: 'Charlie',
          photoUrl: null,
          groups: ['group-1'],
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'user-diana',
          email: 'diana@example.com',
          username: 'Diana',
          photoUrl: null,
          groups: ['group-2'],
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'user-evan',
          email: 'evan@example.com',
          username: 'Evan',
          photoUrl: null,
          groups: ['group-2'],
          createdAt: DateTime.now(),
        ),
      ].where((user) => 
        groupId == 'group-1' ? 
          ['mock-user-id', 'user-alice', 'user-bob', 'user-charlie'].contains(user.id) :
        groupId == 'group-2' ? 
          ['mock-user-id', 'user-alice', 'user-diana', 'user-evan'].contains(user.id) :
        false
      ).toList();
    }

    try {
      final DocumentSnapshot groupDoc = await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }
      
      final GroupModel group = GroupModel.fromMap(
        groupDoc.data() as Map<String, dynamic>
      );
      
      if (group.members.isEmpty) {
        return [];
      }
      
      final QuerySnapshot usersSnapshot = await _firestore!
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: group.members)
          .get();
      
      return usersSnapshot.docs
          .map((doc) => UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
          .toList();
    } catch (e) {
      throw Exception('Error getting group members: ${e.toString()}');
    }
  }

  // Add an admin to a group
  Future<bool> addAdmin(String groupId, String userId) async {
    if (FirebaseService.isMockMode) {
      return true;
    }

    try {
      await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'admins': FieldValue.arrayUnion([userId]),
      });
      
      return true;
    } catch (e) {
      throw Exception('Error adding admin to group: ${e.toString()}');
    }
  }

  // Remove an admin from a group
  Future<bool> removeAdmin(String groupId, String userId) async {
    if (FirebaseService.isMockMode) {
      return true;
    }

    try {
      await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'admins': FieldValue.arrayRemove([userId]),
      });
      
      return true;
    } catch (e) {
      throw Exception('Error removing admin from group: ${e.toString()}');
    }
  }

  // Delete a group
  Future<bool> deleteGroup(String groupId) async {
    if (FirebaseService.isMockMode) {
      return true;
    }

    try {
      // Get the group to get the list of members
      final DocumentSnapshot groupDoc = await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }
      
      final GroupModel group = GroupModel.fromMap(
        groupDoc.data() as Map<String, dynamic>
      );
      
      // Remove the group from each member's groups
      for (final String memberId in group.members) {
        await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(memberId)
            .update({
          'groups': FieldValue.arrayRemove([groupId]),
        });
      }
      
      // Delete the group
      await _firestore!
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .delete();
      
      return true;
    } catch (e) {
      throw Exception('Error deleting group: ${e.toString()}');
    }
  }
} 