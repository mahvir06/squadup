import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/group_provider.dart';

class SearchGroupsScreen extends StatefulWidget {
  const SearchGroupsScreen({super.key});

  @override
  State<SearchGroupsScreen> createState() => _SearchGroupsScreenState();
}

class _SearchGroupsScreenState extends State<SearchGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchGroups('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchGroups(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.searchGroups(query);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _joinGroup(GroupModel group) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (userProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to join a group'),
        ),
      );
      return;
    }

    final success = await groupProvider.joinGroup(group.id, userProvider.user!.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${group.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(groupProvider.error ?? 'Failed to join group'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final List<GroupModel> searchResults = groupProvider.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Groups'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for groups...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchGroups('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchGroups(value);
              },
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : searchResults.isEmpty
                    ? const Center(
                        child: Text('No groups found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final group = searchResults[index];
                          final bool isAlreadyMember = userProvider.user != null &&
                              group.members.contains(userProvider.user!.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Group name
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Group description
                                  Text(
                                    group.description,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),

                                  // Group info
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Members count
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${group.members.length} members',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Join button
                                      ElevatedButton(
                                        onPressed: isAlreadyMember
                                            ? null
                                            : () => _joinGroup(group),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          isAlreadyMember ? 'Joined' : 'Join',
                                        ),
                                      ),
                                    ],
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
} 