import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/game_status_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  List<String> _selectedGames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
      await gameStatusProvider.loadAllGames();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleGame(String gameId) {
    setState(() {
      if (_selectedGames.contains(gameId)) {
        _selectedGames.remove(gameId);
      } else {
        _selectedGames.add(gameId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one game'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      if (userProvider.user == null) {
        throw Exception('User not logged in');
      }

      final success = await groupProvider.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        adminId: userProvider.user!.id,
        supportedGames: _selectedGames,
        isPublic: _isPublic,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupProvider.error ?? 'Failed to create group'),
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
    final gameStatusProvider = Provider.of<GameStatusProvider>(context);
    final List<GameModel> allGames = gameStatusProvider.allGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _isLoading && allGames.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'Enter a name for your group',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Group description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your group',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Public/Private toggle
                    SwitchListTile(
                      title: const Text('Public Group'),
                      subtitle: Text(
                        _isPublic
                            ? 'Anyone can find and join this group'
                            : 'Only invited members can join this group',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Supported games
                    const Text(
                      'Supported Games',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the games your group plays',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Game list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allGames.length,
                      itemBuilder: (context, index) {
                        final game = allGames[index];
                        final bool isSelected = _selectedGames.contains(game.id);

                        return CheckboxListTile(
                          title: Text(game.name),
                          subtitle: Text(
                            'Players: ${game.minPlayers}${game.maxPlayers != null ? ' - ${game.maxPlayers}' : '+'} • Platforms: ${game.platforms.join(', ')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            _toggleGame(game.id);
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 