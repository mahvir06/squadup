# SquadUp

SquadUp is a mobile app that helps gamers coordinate play sessions with friends. Instead of sending multiple texts to check who's available to play, users can simply set their status to "down to play" for specific games, and the app will notify everyone when enough people are ready to form a squad.

## Features

- **User Authentication**: Sign up, log in, and manage your profile
- **Game Status**: Set your status as "down to play" for specific games
- **Groups**: Create and join gaming groups with friends or find public groups
- **Notifications**: Get notified when enough people in your group are ready to play
- **Time-Limited Availability**: Set how long you'll be available to play
- **Dark Mode**: Toggle between light and dark themes

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **Firebase**: Backend services
  - Authentication
  - Firestore (database)
  - Cloud Messaging (notifications)
- **Provider**: State management

## Getting Started

### Prerequisites

- Flutter SDK (version 3.6.0 or higher)
- Dart SDK (version 3.6.0 or higher)
- Firebase account

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/squadup.git
   cd squadup
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files (google-services.json and GoogleService-Info.plist)
   - Enable Authentication, Firestore, and Cloud Messaging

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── constants/       # App-wide constants and theme
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   └── home/        # Main app screens
├── services/        # Firebase and other services
├── utils/           # Utility functions
└── widgets/         # Reusable widgets
```

## Future Enhancements

- Voice chat integration
- Game session scheduling
- Friend requests and social features
- Game statistics and history
- Cross-platform play coordination

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to all the gamers who inspired this app
- Flutter and Firebase teams for their amazing tools
