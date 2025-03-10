import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/game_model.dart';
import '../../models/game_status_model.dart';
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

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _isLoading = false;
  String? _selectedGameId;
  Map<String, GameStatusModel?> _memberStatuses = {};
  List<UserModel> _members = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.getGroup(widget.groupId);
      
      // Load members
      _members = await groupProvider.getGroupMembers(widget.groupId);
      
      // Load member statuses if a game is selected
      if (_selectedGameId != null) {
        await _loadMemberStatuses();
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

  Future<void> _loadMemberStatuses() async {
    if (_selectedGameId == null) return;

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
    final group = groupProvider.currentGroup;
    
    if (group == null) return;

    setState(() {
      _memberStatuses = {};
    });

    for (final memberId in group.members) {
      try {
        final status = await gameStatusProvider.getGameStatus(memberId, _selectedGameId!);
        if (mounted) {
          setState(() {
            _memberStatuses[memberId] = status;
          });
        }
      } catch (e) {
        debugPrint('Error loading status for member \\$memberId: \\${e.toString()}');
      }
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
        Navigator.of(context).pop();
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
            content: Text('Error: \\${e.toString()}'),
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
    final group = groupProvider.currentGroup;

    if (_isLoading || group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isAdmin = group.admins.contains(userProvider.user?.id);
    final List<GameModel> groupGames = gameStatusProvider.allGames
        .where((game) => group.enabledGames.contains(game.id))
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
      ),
      body: Column(
        children: [
          // Game filter dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String?>(
              value: _selectedGameId,
              decoration: const InputDecoration(
                labelText: 'Filter by Game',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Games'),
                ),
                ...groupGames.map((game) => DropdownMenuItem(
                  value: game.id,
                  child: Text(game.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGameId = value;
                });
                _loadMemberStatuses();
              },
            ),
          ),

          // Members grid
          Expanded(
            child: _members.isEmpty && !_isLoading
                ? const Center(
                    child: Text('No members found'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final bool isMemberAdmin = group.admins.contains(member.id);
                      final GameStatusModel? memberStatus = _memberStatuses[member.id];
                      final bool isDownToPlay = memberStatus?.isDown ?? false;
                      final bool isCurrentUser = userProvider.user?.id == member.id;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isDownToPlay 
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (isCurrentUser) {
                              _showCurrentUserStatusOptions(context, member);
                            } else if (isAdmin && !isCurrentUser) {
                              _showMemberActions(context, member, isMemberAdmin);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double avatarSize = constraints.maxWidth * 0.5;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // User avatar
                                        CircleAvatar(
                                          radius: avatarSize / 2,
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          child: member.photoUrl != null
                                              ? ClipOval(
                                                  child: Image.network(
                                                    member.photoUrl!,
                                                    width: avatarSize,
                                                    height: avatarSize,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Text(
                                                  member.username[0].toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: avatarSize * 0.4,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Username
                                        Text(
                                          member.username,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        if (isMemberAdmin)
                                          Text(
                                            'Admin',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),

                                        // Show edit hint for current user
                                        if (isCurrentUser)
                                          Text(
                                            'Tap to edit status',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              
                              // Status indicator
                              if (_selectedGameId != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDownToPlay
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMemberActions(BuildContext context, UserModel member, bool isMemberAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(member.username),
              subtitle: Text(member.email),
            ),
            const Divider(),
            if (!isMemberAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Make Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  await groupProvider.addAdmin(widget.groupId, member.id);
                  _loadGroupData();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.remove_moderator),
                title: const Text('Remove Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  await groupProvider.removeAdmin(widget.groupId, member.id);
                  _loadGroupData();
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('Remove from Group'),
              onTap: () async {
                Navigator.pop(context);
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                await groupProvider.removeMember(widget.groupId, member.id);
                _loadGroupData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrentUserStatusOptions(BuildContext context, UserModel user) {
    final group = Provider.of<GroupProvider>(context, listen: false).currentGroup;
    if (group == null) return;

    final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
    final enabledGames = gameStatusProvider.allGames
        .where((game) => group.enabledGames.contains(game.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Game Status',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // List of enabled games with status toggles
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: enabledGames.length,
                  itemBuilder: (context, index) {
                    final game = enabledGames[index];
                    return FutureBuilder<GameStatusModel?>(
                      future: gameStatusProvider.getGameStatus(user.id, game.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final status = snapshot.data;
                        final isDown = status?.isDown ?? false;
                        final downForGroups = status?.downForGroups ?? [];
                        final isDownForThisGroup = isDown && downForGroups.contains(group.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                List<String> newDownForGroups = List.from(downForGroups);
                                if (!isDownForThisGroup) {
                                  if (!newDownForGroups.contains(group.id)) {
                                    newDownForGroups.add(group.id);
                                  }
                                } else {
                                  newDownForGroups.remove(group.id);
                                }

                                final success = await gameStatusProvider.setGameStatus(
                                  userId: user.id,
                                  gameId: game.id,
                                  isDown: newDownForGroups.isNotEmpty,
                                  downForGroups: newDownForGroups,
                                );

                                if (success && mounted) {
                                  // Refresh the status in the modal
                                  setModalState(() {});
                                  // Refresh the member statuses in the main screen
                                  setState(() {
                                    _memberStatuses[user.id] = null; // Clear the cache to force refresh
                                  });
                                  if (_selectedGameId == game.id) {
                                    _loadMemberStatuses();
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Game icon/image
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: game.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                game.imageUrl!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.sports_esports,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Game name
                                    Expanded(
                                      child: Text(
                                        game.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    
                                    // Status indicator
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDownForThisGroup
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: isDownForThisGroup ? Colors.white : Colors.transparent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 