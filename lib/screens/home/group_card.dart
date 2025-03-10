import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import 'group_detail_screen.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final String userId;

  const GroupCard({
    super.key,
    required this.group,
    required this.userId,
  });

  void _navigateToGroupDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(groupId: group.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = group.admins.contains(userId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToGroupDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name and admin badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Group description
              Text(
                group.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // Group info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Members count
                  _buildInfoItem(
                    context,
                    Icons.people,
                    '${group.members.length} members',
                  ),
                  
                  // Games count
                  _buildInfoItem(
                    context,
                    Icons.sports_esports,
                    '${group.supportedGames.length} games',
                  ),
                  
                  // Public/Private status
                  _buildInfoItem(
                    context,
                    group.isPublic ? Icons.public : Icons.lock,
                    group.isPublic ? 'Public' : 'Private',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
} 