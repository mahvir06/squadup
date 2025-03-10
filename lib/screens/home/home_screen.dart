import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/game_status_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'groups_tab.dart';
import 'status_tab.dart';
import 'profile_tab.dart';
import '../../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _tabs = [
    const StatusTab(),
    const GroupsTab(),
    const ProfileTab(),
  ];
  
  final List<String> _tabTitles = [
    'Status',
    'Groups',
    'Profile',
  ];
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }
  
  Future<void> _initializeUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initialize();
    
    if (FirebaseService.isMockMode && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Running in mock mode. Some features may be limited.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
  
  Future<void> _signOut() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final success = await userProvider.signOut();
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Sign out failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentIndex]),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: _toggleTheme,
          ),
          
          // Sign out
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: userProvider.isLoading ? null : _signOut,
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 