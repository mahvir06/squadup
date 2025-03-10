import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/game_model.dart';
import '../../models/game_status_model.dart';
import '../../providers/game_status_provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';

class GameStatusCard extends StatefulWidget {
  final GameModel game;
  final String userId;

  const GameStatusCard({
    super.key,
    required this.game,
    required this.userId,
  });

  @override
  State<GameStatusCard> createState() => _GameStatusCardState();
}

class _GameStatusCardState extends State<GameStatusCard> {
  bool _isLoading = false;
  GameStatusModel? _status;
  List<String> _downForGroups = [];
  
  @override
  void initState() {
    super.initState();
    _loadStatus();
  }
  
  Future<void> _loadStatus() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
      _status = await gameStatusProvider.getGameStatus(widget.userId, widget.game.id);
      
      if (_status != null && mounted) {
        setState(() {
          _downForGroups = List.from(_status!.downForGroups);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showGroupOptions() {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Play ${widget.game.name} with...',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              FutureBuilder(
                future: Provider.of<GroupProvider>(context, listen: false).getUserGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('You haven\'t joined any groups yet'),
                      ),
                    );
                  }
                  
                  print('Game ID: ${widget.game.id}');
                  print('All groups: ${(snapshot.data as List<GroupModel>).map((g) => '${g.name}: ${g.enabledGames}').join(', ')}');
                  
                  final groups = (snapshot.data as List<GroupModel>)
                    .where((group) => group.enabledGames.contains(widget.game.id))
                    .toList();
                    
                  print('Filtered groups: ${groups.map((g) => g.name).join(', ')}');
                    
                  if (groups.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('None of your groups play this game'),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isDown = _downForGroups.contains(group.id);
                      
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
                              List<String> newDownForGroups = List.from(_downForGroups);
                              if (isDown) {
                                newDownForGroups.remove(group.id);
                              } else {
                                newDownForGroups.add(group.id);
                              }
                              
                              final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
                              final success = await gameStatusProvider.setGameStatus(
                                userId: widget.userId,
                                gameId: widget.game.id,
                                isDown: newDownForGroups.isNotEmpty,
                                downForGroups: newDownForGroups,
                              );
                              
                              if (success && mounted) {
                                setState(() {
                                  _downForGroups = newDownForGroups;
                                });
                                
                                // Only update modal state if the bottom sheet is still showing
                                if (Navigator.of(context).canPop()) {
                                  setModalState(() {});
                                }
                                
                                // Notify listeners to update other screens
                                gameStatusProvider.notifyListeners();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (group.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            group.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDown
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: isDown ? Colors.white : Colors.transparent,
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
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isDown = _downForGroups.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showGroupOptions,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Game image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.game.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.game.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.sports_esports,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Players: ${widget.game.minPlayers}${widget.game.maxPlayers != null ? ' - ${widget.game.maxPlayers}' : '+'} | ${widget.game.platforms.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (_downForGroups.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      FutureBuilder(
                        future: Provider.of<GroupProvider>(context, listen: false).getUserGroups(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          
                          final groups = (snapshot.data as List<GroupModel>)
                            .where((group) => _downForGroups.contains(group.id))
                            .map((group) => group.name)
                            .join(', ');
                            
                          return Text(
                            'Down to play with: $groups',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status indicator
              _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDown
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withOpacity(0.3),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: isDown ? Colors.white : Colors.transparent,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 