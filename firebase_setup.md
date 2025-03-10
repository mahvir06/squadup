# Firebase Setup Guide for SquadUp

This guide will help you set up Firebase for your SquadUp app.

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click on "Add project"
3. Enter "SquadUp" as the project name
4. Follow the prompts to set up your project
5. Once your project is created, you'll be taken to the project dashboard

## Step 2: Set Up Firebase Authentication

1. In the Firebase Console, go to "Authentication" in the left sidebar
2. Click on "Get started"
3. Enable the "Email/Password" sign-in method
4. Save your changes

## Step 3: Set Up Firestore Database

1. In the Firebase Console, go to "Firestore Database" in the left sidebar
2. Click on "Create database"
3. Start in test mode (you can adjust security rules later)
4. Choose a location for your database (pick one close to your users)
5. Click "Enable"

## Step 4: Add Firebase to Your Flutter App

### For iOS:

1. In the Firebase Console, click on the iOS icon (🍎) to add an iOS app
2. Enter your iOS bundle ID (e.g., `com.yourusername.squadup`)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place this file in the `ios/Runner` directory of your Flutter project
7. Follow the remaining setup instructions provided by Firebase

### For Android:

1. In the Firebase Console, click on the Android icon to add an Android app
2. Enter your Android package name (e.g., `com.yourusername.squadup`)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `google-services.json` file
6. Place this file in the `android/app` directory of your Flutter project
7. Follow the remaining setup instructions provided by Firebase

## Step 5: Update Firebase Options in Your App

1. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run the FlutterFire configure command:
   ```bash
   flutterfire configure --project=your-firebase-project-id
   ```

3. This will generate a `firebase_options.dart` file in your `lib` directory
4. Replace the placeholder `firebase_options.dart` file with the generated one

## Step 6: Initialize Firebase in Your App

The app is already set up to initialize Firebase using the `FirebaseService` class. Once you've completed the steps above, the app should connect to your Firebase project automatically.

## Step 7: Run Your App

Now you can run your app with:

```bash
flutter run
```

Your app should now be connected to Firebase!

## Troubleshooting

If you encounter any issues:

1. Make sure you've placed the Firebase configuration files in the correct directories
2. Check that your bundle ID/package name matches what you registered in Firebase
3. Ensure you've followed all the setup steps provided by Firebase
4. Try cleaning your Flutter project with `flutter clean` and then running `flutter pub get` 