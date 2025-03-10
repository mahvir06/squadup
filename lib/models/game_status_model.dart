import 'package:cloud_firestore/cloud_firestore.dart';

class GameStatusModel {
  final String id;
  final String userId;
  final String gameId;
  final bool isDown;
  final List<String> downForGroups;
  final DateTime? availableUntil;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameStatusModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.isDown,
    required this.downForGroups,
    this.availableUntil,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a copy of this GameStatusModel with some fields replaced
  GameStatusModel copyWith({
    String? id,
    String? userId,
    String? gameId,
    bool? isDown,
    List<String>? downForGroups,
    DateTime? availableUntil,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameStatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      isDown: isDown ?? this.isDown,
      downForGroups: downForGroups ?? this.downForGroups,
      availableUntil: availableUntil ?? this.availableUntil,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert GameStatusModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameId': gameId,
      'isDown': isDown,
      'downForGroups': downForGroups,
      'availableUntil': availableUntil?.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create GameStatusModel from a Map
  factory GameStatusModel.fromMap(Map<String, dynamic> map) {
    return GameStatusModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      gameId: map['gameId'] as String,
      isDown: map['isDown'] as bool,
      downForGroups: List<String>.from(map['downForGroups'] ?? []),
      availableUntil: map['availableUntil'] != null 
          ? DateTime.parse(map['availableUntil'] as String) 
          : null,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
} 