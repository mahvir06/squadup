import 'package:cloud_firestore/cloud_firestore.dart';

class GameStatusModel {
  final String id;
  final String userId;
  final String gameId;
  final bool isDown;
  final DateTime? availableUntil;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameStatusModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.isDown,
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
      'availableUntil': availableUntil?.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create GameStatusModel from a Map
  factory GameStatusModel.fromMap(Map<String, dynamic> map, String id) {
    return GameStatusModel(
      id: id,
      userId: map['userId'] ?? '',
      gameId: map['gameId'] ?? '',
      isDown: map['isDown'] ?? false,
      availableUntil: map['availableUntil'] != null 
          ? DateTime.parse(map['availableUntil']) 
          : null,
      note: map['note'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }
} 