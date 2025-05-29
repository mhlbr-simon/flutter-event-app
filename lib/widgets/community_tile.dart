import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community.dart';
import '../providers/community_data.dart';
import '../screens/community_details_page.dart';

class CommunityTile extends StatelessWidget {
  final Community community;

  const CommunityTile({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final communityData = Provider.of<CommunityData>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text(
          community.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Text(
            community.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent.withOpacity(0.8),
          ),
          tooltip: 'Delete Community',
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title:
                        Text('Confirm Delete', style: Theme.of(context).textTheme.headlineSmall),
                    content: Text(
                        'Are you sure you want to delete the community "${community.name}" and all its events? This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel')),
                      TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () {
                            communityData.deleteCommunity(community);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Community "${community.name}" deleted.')),
                            );
                          },
                          child: const Text('Delete')),
                    ],
                  );
                });
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailsPage(community: community),
            ),
          );
        },
      ),
    );
  }
}
