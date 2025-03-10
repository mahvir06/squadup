import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import 'group_card.dart';
import 'create_group_screen.dart';
import 'search_groups_screen.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }
  
  Future<void> _loadGroups() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.loadUserGroups(userProvider.user!.id);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _navigateToCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    ).then((_) => _loadGroups());
  }
  
  void _navigateToSearchGroups() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchGroupsScreen()),
    ).then((_) => _loadGroups());
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    
    if (userProvider.user == null) {
      return const Center(
        child: Text('Please log in to view your groups'),
      );
    }
    
    final List<GroupModel> userGroups = groupProvider.userGroups;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearchGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : userGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'You haven\'t joined any groups yet',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _navigateToSearchGroups,
                        child: const Text('Find Groups'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: userGroups.length,
                  itemBuilder: (context, index) {
                    final group = userGroups[index];
                    return GroupCard(
                      group: group,
                      userId: userProvider.user!.id,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGroup,
        child: const Icon(Icons.add),
      ),
    );
  }
} 