import 'package:eventapp/providers/community_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community.dart'; 
import '../widgets/community_tile.dart';
import '../colors.dart';  

class CommunitiesTab extends StatefulWidget {
  const CommunitiesTab({super.key});

  @override
  State<CommunitiesTab> createState() => _CommunitiesTabState();
}

class _CommunitiesTabState extends State<CommunitiesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TextEditingController _communitySearchController;
  String _communitySearchText = '';

  @override
  void initState() {
    super.initState();
    _communitySearchController = TextEditingController();
  }

  @override
  void dispose() {
    _communitySearchController.dispose();
    super.dispose();
  }

  void _setCommunitySearchText(String text) {
    setState(() {
      _communitySearchText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final communityData = Provider.of<CommunityData>(context);

    List<Community> communitiesToDisplay = communityData.communities;
    if (_communitySearchText.isNotEmpty) {
      final searchTextLower = _communitySearchText.toLowerCase();
      communitiesToDisplay = communitiesToDisplay.where((community) {
        return community.name.toLowerCase().contains(searchTextLower) ||
            community.description.toLowerCase().contains(searchTextLower);
      }).toList();
    }

    communitiesToDisplay.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 8, right: 0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(
                'assets/images/looped_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: const Text('Communities'),
        centerTitle: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightBackgroundColor,
              scaffoldBodyGradientBottom,
            ],
            stops: [0.4, 1.0],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: TextField(
                controller: _communitySearchController,
                decoration: InputDecoration(
                  hintText: 'Searching for a community',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _communitySearchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _communitySearchController.clear();
                            _setCommunitySearchText('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                ),
                onChanged: _setCommunitySearchText,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Expanded(
              child: communitiesToDisplay.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _communitySearchText.isNotEmpty
                              ? 'No communities found for "$_communitySearchText".'
                              : 'No communities yet.\nTap the "+" button to create your first one!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontFamily: 'Inter',
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
                      itemCount: communitiesToDisplay.length,
                      itemBuilder: (context, index) {
                        return CommunityTile(community: communitiesToDisplay[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateCommunityDialog(context);
        },
        tooltip: 'Create Community',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
    );
  }

  void _showCreateCommunityDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Create New Community', style: Theme.of(context).textTheme.headlineSmall),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: 'e.g., Leipzig Tech Meetup', labelText: 'Community Name*'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    if (Provider.of<CommunityData>(context, listen: false)
                        .communities
                        .any((c) => c.name.toLowerCase() == value.toLowerCase())) {
                      return 'A community with this name already exists.';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    name = value.trim();
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: 'What is this community about?', labelText: 'Description*'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    description = value.trim();
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newCommunity = Community(name: name, description: description);
                  Provider.of<CommunityData>(context, listen: false).addCommunity(newCommunity);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Community "${newCommunity.name}" created!')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
