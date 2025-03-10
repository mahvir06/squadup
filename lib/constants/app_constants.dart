import 'package:flutter/material.dart';

class AppConstants {
  // App name
  static const String appName = 'SquadUp';
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String gamesCollection = 'games';
  static const String gameStatusCollection = 'gameStatus';
  
  // Shared preferences keys
  static const String userIdKey = 'userId';
  static const String userEmailKey = 'userEmail';
  static const String userLoggedInKey = 'userLoggedIn';
  static const String darkModeKey = 'darkMode';
  static const String themePreference = 'theme_preference';
  
  // Notification types
  static const String squadReadyNotification = 'squadReady';
  static const String groupInviteNotification = 'groupInvite';
  static const String friendRequestNotification = 'friendRequest';
  
  // Minimum players required to form a squad
  static const int minSquadSize = 2;
  
  // Default games
  static const List<Map<String, dynamic>> defaultGames = [
    {
      'name': 'Fortnite',
      'minPlayers': 1,
      'maxPlayers': 4,
      'platforms': ['PC', 'PlayStation', 'Xbox', 'Switch', 'Mobile'],
      'imageUrl': null,
    },
    {
      'name': 'Call of Duty: Warzone',
      'minPlayers': 1,
      'maxPlayers': 4,
      'platforms': ['PC', 'PlayStation', 'Xbox'],
      'imageUrl': null,
    },
    {
      'name': 'Apex Legends',
      'minPlayers': 1,
      'maxPlayers': 3,
      'platforms': ['PC', 'PlayStation', 'Xbox', 'Switch'],
      'imageUrl': null,
    },
    {
      'name': 'League of Legends',
      'minPlayers': 1,
      'maxPlayers': 5,
      'platforms': ['PC'],
      'imageUrl': null,
    },
    {
      'name': 'Valorant',
      'minPlayers': 1,
      'maxPlayers': 5,
      'platforms': ['PC'],
      'imageUrl': null,
    },
    {
      'name': 'Minecraft',
      'minPlayers': 1,
      'maxPlayers': null,
      'platforms': ['PC', 'PlayStation', 'Xbox', 'Switch', 'Mobile'],
      'imageUrl': null,
    },
    {
      'name': 'Among Us',
      'minPlayers': 4,
      'maxPlayers': 15,
      'platforms': ['PC', 'PlayStation', 'Xbox', 'Switch', 'Mobile'],
      'imageUrl': null,
    },
    {
      'name': 'Rocket League',
      'minPlayers': 1,
      'maxPlayers': 4,
      'platforms': ['PC', 'PlayStation', 'Xbox', 'Switch'],
      'imageUrl': null,
    },
  ];
} 