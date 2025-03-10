import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'providers/user_provider.dart';
import 'providers/group_provider.dart';
import 'providers/game_status_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => GameStatusProvider()),
      ],
      child: const SquadUpApp(),
    );
  }
}

class SquadUpApp extends StatefulWidget {
  const SquadUpApp({super.key});

  @override
  State<SquadUpApp> createState() => _SquadUpAppState();
}

class _SquadUpAppState extends State<SquadUpApp> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Initialize providers
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.initialize();
    
    // We'll initialize other providers in their respective screens
    // to avoid initialization issues
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: AppConstants.appName,
      theme: themeProvider.themeData,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
