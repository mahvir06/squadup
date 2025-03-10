class GameModel {
  final String id;
  final String name;
  final int minPlayers;
  final int? maxPlayers;
  final List<String> platforms;
  final String? imageUrl;

  GameModel({
    required this.id,
    required this.name,
    required this.minPlayers,
    this.maxPlayers,
    required this.platforms,
    this.imageUrl,
  });

  // Create a copy of this GameModel with some fields replaced
  GameModel copyWith({
    String? id,
    String? name,
    int? minPlayers,
    int? maxPlayers,
    List<String>? platforms,
    String? imageUrl,
  }) {
    return GameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      platforms: platforms ?? this.platforms,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Convert GameModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'platforms': platforms,
      'imageUrl': imageUrl,
    };
  }

  // Create GameModel from a Map
  factory GameModel.fromMap(Map<String, dynamic> map, String id) {
    return GameModel(
      id: id,
      name: map['name'] ?? '',
      minPlayers: map['minPlayers'] ?? 1,
      maxPlayers: map['maxPlayers'],
      platforms: List<String>.from(map['platforms'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }
} 