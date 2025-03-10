import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final List<String> members;
  final List<String> admins;
  final List<String> supportedGames;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.admins,
    required this.supportedGames,
    required this.isPublic,
    required this.createdAt,
    DateTime? updatedAt,
    this.imageUrl,
  }) : this.updatedAt = updatedAt ?? createdAt;

  // Create a copy of this GroupModel with some fields replaced
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? members,
    List<String>? admins,
    List<String>? supportedGames,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      supportedGames: supportedGames ?? this.supportedGames,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Convert GroupModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'admins': admins,
      'supportedGames': supportedGames,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  // Create GroupModel from a Map
  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      supportedGames: List<String>.from(map['supportedGames'] ?? []),
      isPublic: map['isPublic'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      imageUrl: map['imageUrl'],
    );
  }
} 