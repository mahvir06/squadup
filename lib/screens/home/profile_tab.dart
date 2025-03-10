import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  bool _isEditing = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _initializeUsername();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
  
  void _initializeUsername() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      _usernameController.text = userProvider.user!.username;
    }
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final success = await userProvider.updateProfile(
        username: _usernameController.text.trim(),
      );
      
      if (success && mounted) {
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'Failed to update profile'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final success = await userProvider.signOut();
      
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'Failed to sign out'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (userProvider.user == null) {
      return const Center(
        child: Text('Please log in to view your profile'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isLoading ? null : _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: userProvider.user!.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                userProvider.user!.photoUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              userProvider.user!.username.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 40,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Username
                    TextFormField(
                      controller: _usernameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email (read-only)
                    TextFormField(
                      initialValue: userProvider.user!.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Theme toggle
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                    const Divider(),
                    
                    // Sign out button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 