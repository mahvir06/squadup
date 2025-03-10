import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/game_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/game_status_provider.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.getGroup(widget.groupId);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditGroup(BuildContext context, GroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditGroupScreen(group: group),
      ),
    ).then((_) => _loadGroupData());
  }

  Future<void> _leaveGroup(BuildContext context, GroupModel group) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (userProvider.user == null) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await groupProvider.leaveGroup(group.id, userProvider.user!.id);

      if (success && mounted) {
        Navigator.of(context).pop(); // Go back to groups list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left ${group.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupProvider.error ?? 'Failed to leave group'),
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
    final groupProvider = Provider.of<GroupProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final gameStatusProvider = Provider.of<GameStatusProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final GroupModel? group = groupProvider.currentGroup;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Details'),
        ),
        body: const Center(
          child: Text('Group not found'),
        ),
      );
    }

    final bool isAdmin = group.admins.contains(userProvider.user?.id);
    final List<GameModel> groupGames = gameStatusProvider.allGames
        .where((game) => group.supportedGames.contains(game.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditGroup(context, group),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _leaveGroup(context, group),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Members'),
            Tab(text: 'Games'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Info tab
          _buildInfoTab(context, group),
          
          // Members tab
          FutureBuilder<List<UserModel>>(
            future: _fetchGroupMembers(group),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final List<UserModel> members = snapshot.data ?? [];
              return _buildMembersTab(context, group, members, isAdmin);
            }
          ),
          
          // Games tab
          _buildGamesTab(context, groupGames),
        ],
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(group.description),
          const SizedBox(height: 24),
          
          // Group details
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailItem(context, Icons.people, '${group.members.length} members'),
          const SizedBox(height: 8),
          _buildDetailItem(
            context, 
            Icons.sports_esports, 
            '${group.supportedGames.length} supported games'
          ),
          const SizedBox(height: 8),
          _buildDetailItem(
            context, 
            group.isPublic ? Icons.public : Icons.lock, 
            group.isPublic ? 'Public group' : 'Private group'
          ),
          const SizedBox(height: 8),
          _buildDetailItem(
            context, 
            Icons.calendar_today, 
            'Created on ${_formatDate(group.createdAt)}'
          ),
        ],
      ),
    );
  }

  Future<List<UserModel>> _fetchGroupMembers(GroupModel group) async {
    // This is a placeholder. In a real app, you would fetch the user data for each member ID
    // For now, we'll just create dummy user objects
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    return group.members.map((memberId) {
      // Check if this is the current user
      if (Provider.of<UserProvider>(context, listen: false).user?.id == memberId) {
        return Provider.of<UserProvider>(context, listen: false).user!;
      }
      
      // Otherwise create a placeholder user
      return UserModel(
        id: memberId,
        email: 'user_$memberId@example.com',
        username: 'User $memberId',
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  Widget _buildMembersTab(BuildContext context, GroupModel group, List<UserModel> members, bool isAdmin) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final bool isMemberAdmin = group.admins.contains(member.id);
        final bool isCurrentUser = Provider.of<UserProvider>(context).user?.id == member.id;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              member.username.isNotEmpty ? member.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          title: Text(
            member.username,
            style: TextStyle(
              fontWeight: isMemberAdmin ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            isMemberAdmin ? 'Admin' : 'Member',
            style: TextStyle(
              color: isMemberAdmin 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          trailing: isAdmin && !isCurrentUser
              ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    // These actions would need to be implemented in the GroupProvider
                    if (value == 'make_admin') {
                      // Implement make admin functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin functionality not implemented yet')),
                      );
                    } else if (value == 'remove_admin') {
                      // Implement remove admin functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin functionality not implemented yet')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isMemberAdmin)
                      const PopupMenuItem(
                        value: 'make_admin',
                        child: Text('Make Admin'),
                      ),
                    if (isMemberAdmin)
                      const PopupMenuItem(
                        value: 'remove_admin',
                        child: Text('Remove Admin'),
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildGamesTab(BuildContext context, List<GameModel> games) {
    if (games.isEmpty) {
      return const Center(
        child: Text('No games added to this group'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Players: ${game.minPlayers}${game.maxPlayers != null ? ' - ${game.maxPlayers}' : '+'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platforms: ${game.platforms.join(', ')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
} 