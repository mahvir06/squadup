import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/game_model.dart';
import '../../providers/group_provider.dart';
import '../../providers/game_status_provider.dart';

class EditGroupScreen extends StatefulWidget {
  final GroupModel group;

  const EditGroupScreen({
    super.key,
    required this.group,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  List<String> _selectedGames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description);
    _isPublic = widget.group.isPublic;
    _selectedGames = List.from(widget.group.supportedGames);
    
    // Load all games
    _loadGames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await gameStatusProvider.loadAllGames();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      final success = await groupProvider.updateGroup(
        groupId: widget.group.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        supportedGames: _selectedGames,
        isPublic: _isPublic,
      );
      
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupProvider.error ?? 'Failed to update group'),
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

  void _toggleGame(String gameId) {
    setState(() {
      if (_selectedGames.contains(gameId)) {
        _selectedGames.remove(gameId);
      } else {
        _selectedGames.add(gameId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameStatusProvider = Provider.of<GameStatusProvider>(context);
    final List<GameModel> allGames = gameStatusProvider.allGames;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading && allGames.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Group name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
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
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Public/Private toggle
                  SwitchListTile(
                    title: const Text('Public Group'),
                    subtitle: const Text(
                      'Public groups can be found by anyone',
                    ),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const Divider(),
                  
                  // Supported games
                  const Text(
                    'Supported Games',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the games that your group plays',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Games list
                  ...allGames.map((game) => CheckboxListTile(
                    title: Text(game.name),
                    subtitle: Text(
                      'Players: ${game.minPlayers}${game.maxPlayers != null ? ' - ${game.maxPlayers}' : '+'} | Platforms: ${game.platforms.join(", ")}',
                    ),
                    value: _selectedGames.contains(game.id),
                    onChanged: (_) => _toggleGame(game.id),
                  )),
                  
                  if (allGames.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No games available'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
} 