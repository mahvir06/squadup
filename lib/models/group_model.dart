import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> members;
  final List<String> admins;
  final List<String> enabledGames;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.members,
    required this.admins,
    required this.enabledGames,
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
    String? createdBy,
    List<String>? members,
    List<String>? admins,
    List<String>? enabledGames,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      enabledGames: enabledGames ?? this.enabledGames,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Convert GroupModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'members': members,
      'admins': admins,
      'enabledGames': enabledGames,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  // Create GroupModel from a Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      createdBy: map['createdBy'] as String,
      members: List<String>.from(map['members']),
      admins: List<String>.from(map['admins']),
      enabledGames: List<String>.from(map['enabledGames'] ?? []),
      isPublic: map['isPublic'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      imageUrl: map['imageUrl'],
    );
  }
} 