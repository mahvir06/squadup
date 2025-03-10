import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  FirebaseFirestore? _firestore;
  
  List<GroupModel> _userGroups = [];
  GroupModel? _currentGroup;
  List<GroupModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  
  // Mock data for testing
  final List<GroupModel> _mockGroups = [
    GroupModel(
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
    GroupModel(
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
  ];
  
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
    
    try {
      _userGroups = await _groupService.getUserGroups(userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user groups: $_error');
    } finally {
      _setLoading(false);
    }
  }
  
  // Get a specific group
  Future<void> getGroup(String groupId) async {
    _setLoading(true);
    _error = null;
    
    try {
      if (FirebaseService.isMockMode) {
        final group = _mockGroups.firstWhere(
          (g) => g.id == groupId,
          orElse: () => throw Exception('Group not found'),
        );
        _currentGroup = group;
      } else {
        _currentGroup = await _groupService.getGroup(groupId);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting group: $_error');
      _currentGroup = null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Create a new group
  Future<bool> createGroup({
    required String name,
    required String description,
    required String adminId,
    required List<String> enabledGames,
    required bool isPublic,
    String? imageUrl,
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
        createdBy: adminId,
        members: [adminId],
        admins: [adminId],
        enabledGames: enabledGames,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: imageUrl,
      );
      
      _mockGroups.add(newGroup);
      _userGroups.add(newGroup);
      
      _setLoading(false);
      return true;
    }
    
    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        createdBy: adminId,
        supportedGames: enabledGames,
        isPublic: isPublic,
        imageUrl: imageUrl,
      );
      
      _userGroups.add(group);
      notifyListeners();
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
    String? name,
    String? description,
    List<String>? enabledGames,
    bool? isPublic,
    String? imageUrl,
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
          name: name ?? _mockGroups[index].name,
          description: description ?? _mockGroups[index].description,
          createdBy: _mockGroups[index].createdBy,
          members: _mockGroups[index].members,
          admins: _mockGroups[index].admins,
          enabledGames: enabledGames ?? _mockGroups[index].enabledGames,
          isPublic: isPublic ?? _mockGroups[index].isPublic,
          createdAt: _mockGroups[index].createdAt,
          updatedAt: DateTime.now(),
          imageUrl: imageUrl ?? _mockGroups[index].imageUrl,
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
      final updatedGroup = await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        supportedGames: enabledGames,
        isPublic: isPublic,
        imageUrl: imageUrl,
      );
      
      // Update the group in userGroups list
      final index = _userGroups.indexWhere((g) => g.id == groupId);
      if (index >= 0) {
        _userGroups[index] = updatedGroup;
      }
      
      // Update currentGroup if it's the same group
      if (_currentGroup?.id == groupId) {
        _currentGroup = updatedGroup;
      }
      
      notifyListeners();
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
          createdBy: _mockGroups[index].createdBy,
          members: [..._mockGroups[index].members, userId],
          admins: _mockGroups[index].admins,
          enabledGames: _mockGroups[index].enabledGames,
          isPublic: _mockGroups[index].isPublic,
          createdAt: _mockGroups[index].createdAt,
          updatedAt: DateTime.now(),
          imageUrl: _mockGroups[index].imageUrl,
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
      // Get the group first to check if user can join
      final group = await _groupService.getGroup(groupId);

      // Check if user is already a member
      if (group.members.contains(userId)) {
        _error = 'You are already a member of this group';
        return false;
      }

      // Add member to group
      final success = await _groupService.addMember(groupId, userId);
      if (success) {
        // Refresh user's groups
        await loadUserGroups(userId);
      }
      return success;
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
            createdBy: _mockGroups[index].createdBy,
            members: updatedMembers,
            admins: updatedAdmins,
            enabledGames: _mockGroups[index].enabledGames,
            isPublic: _mockGroups[index].isPublic,
            createdAt: _mockGroups[index].createdAt,
            updatedAt: DateTime.now(),
            imageUrl: _mockGroups[index].imageUrl,
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
      // Get the group first to check if user can leave
      final group = await _groupService.getGroup(groupId);

      // Check if user is a member
      if (!group.members.contains(userId)) {
        _error = 'You are not a member of this group';
        return false;
      }

      // Check if user is the only admin
      if (group.admins.contains(userId) && group.admins.length == 1) {
        _error = 'Admin cannot leave the group. Transfer admin role first';
        return false;
      }

      // Remove member from group
      final success = await _groupService.removeMember(groupId, userId);
      if (success) {
        // Remove group from userGroups list
        _userGroups.removeWhere((g) => g.id == groupId);
        notifyListeners();
      }
      return success;
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
      _searchResults = await _groupService.searchGroups(query);
      notifyListeners();
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

  // Get user groups
  Future<List<GroupModel>> getUserGroups([String? userId]) async {
    if (FirebaseService.isMockMode) {
      // Return the cached groups if available
      if (_userGroups.isNotEmpty) {
        return _userGroups;
      }
      // Otherwise, load them from the service
      final groups = await _groupService.getUserGroups(userId ?? 'mock-user-id');
      _userGroups = groups;
      return groups;
    }

    try {
      final groups = await _groupService.getUserGroups(userId!);
      _userGroups = groups;
      return groups;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting user groups: $_error');
      return [];
    }
  }

  Future<List<UserModel>> getGroupMembers(String groupId) async {
    _setLoading(true);
    _error = null;

    if (FirebaseService.isMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock user data
      final mockUserData = {
        'mock-user-id': UserModel(
          id: 'mock-user-id',
          email: 'user@example.com',
          username: 'You',
          photoUrl: null,
          createdAt: DateTime.now(),
        ),
        'user-alice': UserModel(
          id: 'user-alice',
          email: 'alice@example.com',
          username: 'Alice',
          photoUrl: 'https://i.pravatar.cc/150?u=alice',
          createdAt: DateTime.now(),
        ),
        'user-bob': UserModel(
          id: 'user-bob',
          email: 'bob@example.com',
          username: 'Bob',
          photoUrl: 'https://i.pravatar.cc/150?u=bob',
          createdAt: DateTime.now(),
        ),
        'user-charlie': UserModel(
          id: 'user-charlie',
          email: 'charlie@example.com',
          username: 'Charlie',
          photoUrl: 'https://i.pravatar.cc/150?u=charlie',
          createdAt: DateTime.now(),
        ),
        'user-diana': UserModel(
          id: 'user-diana',
          email: 'diana@example.com',
          username: 'Diana',
          photoUrl: 'https://i.pravatar.cc/150?u=diana',
          createdAt: DateTime.now(),
        ),
        'user-evan': UserModel(
          id: 'user-evan',
          email: 'evan@example.com',
          username: 'Evan',
          photoUrl: 'https://i.pravatar.cc/150?u=evan',
          createdAt: DateTime.now(),
        ),
      };

      final group = _mockGroups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => throw Exception('Group not found'),
      );

      return group.members
          .map((memberId) => mockUserData[memberId]!)
          .toList();
    }

    try {
      return await _groupService.getGroupMembers(groupId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting group members: $_error');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addAdmin(String groupId, String userId) async {
    _setLoading(true);
    _error = null;

    try {
      return await _groupService.addAdmin(groupId, userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding admin: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeAdmin(String groupId, String userId) async {
    _setLoading(true);
    _error = null;

    try {
      return await _groupService.removeAdmin(groupId, userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing admin: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    _setLoading(true);
    _error = null;

    try {
      return await _groupService.removeMember(groupId, userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing member: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 