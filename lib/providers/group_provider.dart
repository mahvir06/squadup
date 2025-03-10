import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';

class GroupProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  
  List<GroupModel> _userGroups = [];
  GroupModel? _currentGroup;
  List<GroupModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  
  // Mock data for testing
  final List<GroupModel> _mockGroups = [];
  
  // Getters
  List<GroupModel> get userGroups => _userGroups;
  GroupModel? get currentGroup => _currentGroup;
  List<GroupModel> get searchResults => _searchResults;
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
  
  // Load user's groups
  Future<void> loadUserGroups(String userId) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, return mock groups
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Create some mock groups if none exist
      if (_mockGroups.isEmpty) {
        _mockGroups.addAll([
          GroupModel(
            id: 'mock-group-1',
            name: 'Casual Gamers',
            description: 'A group for casual gaming sessions',
            admins: [userId],
            members: [userId],
            supportedGames: ['valorant', 'minecraft'],
            isPublic: true,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          GroupModel(
            id: 'mock-group-2',
            name: 'Competitive Squad',
            description: 'Serious players only',
            admins: ['other-user-id'],
            members: ['other-user-id', userId],
            supportedGames: ['league_of_legends', 'valorant'],
            isPublic: false,
            createdAt: DateTime.now().subtract(const Duration(days: 60)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);
      }
      
      // Filter groups where user is a member
      _userGroups = _mockGroups.where((group) => group.members.contains(userId)).toList();
      _setLoading(false);
      return;
    }
    
    try {
      final querySnapshot = await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .where('members', arrayContains: userId)
          .get();
      
      _userGroups = querySnapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user groups: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Get a specific group
  Future<GroupModel?> getGroup(String groupId) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, find the group in mock data
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      final group = _mockGroups.firstWhere(
        (group) => group.id == groupId,
        orElse: () => GroupModel(
          id: groupId,
          name: 'Unknown Group',
          description: 'This group does not exist',
          admins: [],
          members: [],
          supportedGames: [],
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      _currentGroup = group;
      _setLoading(false);
      return group;
    }
    
    try {
      final docSnapshot = await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (docSnapshot.exists) {
        _currentGroup = GroupModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
        return _currentGroup;
      }
      
      return null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting group: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Create a new group
  Future<bool> createGroup({
    required String name,
    required String description,
    required String adminId,
    required List<String> supportedGames,
    required bool isPublic,
  }) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, create a mock group
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      final newGroup = GroupModel(
        id: 'mock-group-${_mockGroups.length + 1}',
        name: name,
        description: description,
        admins: [adminId],
        members: [adminId],
        supportedGames: supportedGames,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _mockGroups.add(newGroup);
      _userGroups.add(newGroup);
      
      _setLoading(false);
      return true;
    }
    
    try {
      final group = GroupModel(
        id: '',
        name: name,
        description: description,
        admins: [adminId],
        members: [adminId],
        supportedGames: supportedGames,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .add(group.toMap());
      
      // Refresh user groups
      await loadUserGroups(adminId);
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating group: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update a group
  Future<bool> updateGroup({
    required String groupId,
    required String name,
    required String description,
    required List<String> supportedGames,
    required bool isPublic,
  }) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, update the mock group
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      final index = _mockGroups.indexWhere((group) => group.id == groupId);
      if (index >= 0) {
        final updatedGroup = GroupModel(
          id: groupId,
          name: name,
          description: description,
          admins: _mockGroups[index].admins,
          members: _mockGroups[index].members,
          supportedGames: supportedGames,
          isPublic: isPublic,
          createdAt: _mockGroups[index].createdAt,
          updatedAt: DateTime.now(),
        );
        
        _mockGroups[index] = updatedGroup;
        
        // Update in user groups if present
        final userGroupIndex = _userGroups.indexWhere((group) => group.id == groupId);
        if (userGroupIndex >= 0) {
          _userGroups[userGroupIndex] = updatedGroup;
        }
        
        if (_currentGroup?.id == groupId) {
          _currentGroup = updatedGroup;
        }
        
        _setLoading(false);
        return true;
      }
      
      _error = 'Group not found';
      _setLoading(false);
      return false;
    }
    
    try {
      await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'name': name,
        'description': description,
        'supportedGames': supportedGames,
        'isPublic': isPublic,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Refresh current group
      if (_currentGroup?.id == groupId) {
        await getGroup(groupId);
      }
      
      // Refresh user groups
      final adminId = _currentGroup?.admins.isNotEmpty == true ? _currentGroup?.admins.first : null;
      if (adminId != null) {
        await loadUserGroups(adminId);
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating group: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Join a group
  Future<bool> joinGroup(String groupId, String userId) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, join the mock group
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      final index = _mockGroups.indexWhere((group) => group.id == groupId);
      if (index >= 0) {
        if (_mockGroups[index].members.contains(userId)) {
          _error = 'You are already a member of this group';
          _setLoading(false);
          return false;
        }
        
        final updatedGroup = GroupModel(
          id: groupId,
          name: _mockGroups[index].name,
          description: _mockGroups[index].description,
          admins: _mockGroups[index].admins,
          members: [..._mockGroups[index].members, userId],
          supportedGames: _mockGroups[index].supportedGames,
          isPublic: _mockGroups[index].isPublic,
          createdAt: _mockGroups[index].createdAt,
          updatedAt: DateTime.now(),
        );
        
        _mockGroups[index] = updatedGroup;
        _userGroups.add(updatedGroup);
        
        _setLoading(false);
        return true;
      }
      
      _error = 'Group not found';
      _setLoading(false);
      return false;
    }
    
    try {
      // Get the group
      final docSnapshot = await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!docSnapshot.exists) {
        _error = 'Group not found';
        return false;
      }
      
      final group = GroupModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
      
      if (!group.isPublic) {
        _error = 'This group is private';
        return false;
      }
      
      if (group.members.contains(userId)) {
        _error = 'You are already a member of this group';
        return false;
      }
      
      // Add user to members
      await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Refresh user groups
      await loadUserGroups(userId);
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error joining group: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Leave a group
  Future<bool> leaveGroup(String groupId, String userId) async {
    _setLoading(true);
    _error = null;
    
    if (FirebaseService.isMockMode) {
      // In mock mode, leave the mock group
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      final index = _mockGroups.indexWhere((group) => group.id == groupId);
      if (index >= 0) {
        if (!_mockGroups[index].members.contains(userId)) {
          _error = 'You are not a member of this group';
          _setLoading(false);
          return false;
        }
        
        if (_mockGroups[index].admins.contains(userId) && _mockGroups[index].admins.length == 1 && _mockGroups[index].members.length > 1) {
          _error = 'Admin cannot leave the group. Transfer admin role first';
          _setLoading(false);
          return false;
        }
        
        if (_mockGroups[index].members.length == 1) {
          // Last member, remove the group
          _mockGroups.removeAt(index);
        } else {
          // Remove user from members
          final updatedMembers = [..._mockGroups[index].members]..remove(userId);
          final updatedAdmins = [..._mockGroups[index].admins]..remove(userId);
          
          final updatedGroup = GroupModel(
            id: groupId,
            name: _mockGroups[index].name,
            description: _mockGroups[index].description,
            admins: updatedAdmins,
            members: updatedMembers,
            supportedGames: _mockGroups[index].supportedGames,
            isPublic: _mockGroups[index].isPublic,
            createdAt: _mockGroups[index].createdAt,
            updatedAt: DateTime.now(),
          );
          
          _mockGroups[index] = updatedGroup;
        }
        
        // Remove from user groups
        _userGroups.removeWhere((group) => group.id == groupId);
        
        _setLoading(false);
        return true;
      }
      
      _error = 'Group not found';
      _setLoading(false);
      return false;
    }
    
    try {
      // Get the group
      final docSnapshot = await _getFirestore()
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .get();
      
      if (!docSnapshot.exists) {
        _error = 'Group not found';
        return false;
      }
      
      final group = GroupModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
      
      if (!group.members.contains(userId)) {
        _error = 'You are not a member of this group';
        return false;
      }
      
      if (group.admins.contains(userId) && group.admins.length == 1 && group.members.length > 1) {
        _error = 'Admin cannot leave the group. Transfer admin role first';
        return false;
      }
      
      if (group.members.length == 1) {
        // Last member, delete the group
        await _getFirestore()
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .delete();
      } else {
        // Remove user from members and admins
        await _getFirestore()
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .update({
          'members': FieldValue.arrayRemove([userId]),
          'admins': FieldValue.arrayRemove([userId]),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Refresh user groups
      await loadUserGroups(userId);
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error leaving group: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Search for public groups
  Future<void> searchGroups(String query) async {
    _setLoading(true);
    _error = null;
    _searchResults = [];
    
    if (FirebaseService.isMockMode) {
      // In mock mode, search mock groups
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      if (query.isEmpty) {
        _searchResults = _mockGroups.where((group) => group.isPublic).toList();
      } else {
        final lowercaseQuery = query.toLowerCase();
        _searchResults = _mockGroups.where((group) => 
          group.isPublic && 
          (group.name.toLowerCase().contains(lowercaseQuery) || 
           group.description.toLowerCase().contains(lowercaseQuery))
        ).toList();
      }
      
      _setLoading(false);
      return;
    }
    
    try {
      QuerySnapshot querySnapshot;
      
      if (query.isEmpty) {
        // Get all public groups
        querySnapshot = await _getFirestore()
            .collection(AppConstants.groupsCollection)
            .where('isPublic', isEqualTo: true)
            .limit(20)
            .get();
      } else {
        // Get public groups that match the query
        // Note: This is a simple implementation and might not be efficient for large datasets
        // For production, consider using a search service like Algolia
        querySnapshot = await _getFirestore()
            .collection(AppConstants.groupsCollection)
            .where('isPublic', isEqualTo: true)
            .get();
        
        final allGroups = querySnapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        final lowercaseQuery = query.toLowerCase();
        _searchResults = allGroups.where((group) => 
          group.name.toLowerCase().contains(lowercaseQuery) || 
          group.description.toLowerCase().contains(lowercaseQuery)
        ).toList();
        
        _setLoading(false);
        return;
      }
      
      _searchResults = querySnapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error searching groups: $_error');
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