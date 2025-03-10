import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? photoUrl;
  final List<String> groups;
  final Map<String, dynamic> gameStatuses;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.photoUrl,
    List<String>? groups,
    Map<String, dynamic>? gameStatuses,
    required this.createdAt,
    DateTime? lastActive,
  }) : 
    this.groups = groups ?? [],
    this.gameStatuses = gameStatuses ?? {},
    this.lastActive = lastActive ?? DateTime.now();

  // Create a copy of this UserModel with some fields replaced
  UserModel copyWith({
    String? username,
    String? photoUrl,
    List<String>? groups,
    Map<String, dynamic>? gameStatuses,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      groups: groups ?? this.groups,
      gameStatuses: gameStatuses ?? this.gameStatuses,
      createdAt: this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Convert UserModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'groups': groups,
      'gameStatuses': gameStatuses,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  // Create UserModel from a Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      groups: List<String>.from(map['groups'] ?? []),
      gameStatuses: Map<String, dynamic>.from(map['gameStatuses'] ?? {}),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      lastActive: map['lastActive'] != null 
          ? DateTime.parse(map['lastActive']) 
          : DateTime.now(),
    );
  }
} 