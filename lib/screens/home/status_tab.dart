import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/game_model.dart';
import '../../models/game_status_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/game_status_provider.dart';
import 'game_status_card.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  bool _isLoading = false;
  String? _searchQuery;
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGames();
    });
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
  
  List<GameModel> _filterGames(List<GameModel> games, String? query) {
    if (query == null || query.isEmpty) {
      return games;
    }
    
    final lowerQuery = query.toLowerCase();
    return games.where((game) => 
      game.name.toLowerCase().contains(lowerQuery) ||
      game.platforms.any((platform) => platform.toLowerCase().contains(lowerQuery))
    ).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final gameStatusProvider = Provider.of<GameStatusProvider>(context);
    
    if (userProvider.user == null) {
      return const Center(
        child: Text('Please log in to view your game status'),
      );
    }
    
    final List<GameModel> filteredGames = _filterGames(
      gameStatusProvider.allGames,
      _searchQuery,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Status'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search games...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Game list
                Expanded(
                  child: filteredGames.isEmpty
                      ? const Center(
                          child: Text('No games found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = filteredGames[index];
                            return GameStatusCard(
                              game: game,
                              userId: userProvider.user!.id,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 