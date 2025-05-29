import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/community.dart';
import '../providers/community_data.dart';

class EventInCommunityCard extends StatelessWidget {
  final Event event;
  final Community community; 

  const EventInCommunityCard({super.key, required this.event, required this.community});

  @override
  Widget build(BuildContext context) {

    final communityData = Provider.of<CommunityData>(context, listen: false);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card( 
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), 
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.name, style: textTheme.titleMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${event.date} - ${event.venue}', style: textTheme.bodySmall),
                      if (event.artist.isNotEmpty && event.artist != 'N/A' && event.artist != 'Unknown Artist') 
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Text('Artist: ${event.artist}', style: textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          'Type: ${event.isPrivate ? 'Private' : 'Public (from Discover)'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: event.isPrivate ? colorScheme.secondary.withOpacity(0.8) : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Selector<CommunityData, Event>(
                  selector: (_, communityDataProvider) {
                    final communityFromProvider = communityDataProvider.communities.firstWhere(
                        (c) => c.name == community.name, 
                        orElse: () {
                            debugPrint("EventInCommunityCard Selector: Community '${community.name}' not found in AppData.");
                            return community;
                        });
                    return communityFromProvider.events.firstWhere(
                        (e) =>
                            e.name == event.name &&
                            e.date == event.date &&
                            e.venue == event.venue &&
                            e.isPrivate == event.isPrivate, 
                        orElse: () {
                            debugPrint("EventInCommunityCard Selector: Event '${event.name}' not found.");
                            return event;
                        });
                  },
                  shouldRebuild: (previous, next) {
                      return previous.isLiked != next.isLiked || previous.likes != next.likes;
                  },
                  builder: (context, currentEventState, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        IconButton(
                          icon: Icon(
                            currentEventState.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: currentEventState.isLiked ? Colors.redAccent : Colors.grey[600],
                            size: 28, 
                          ),
                          tooltip: currentEventState.isLiked ? 'Unlike this event' : 'Like this event',
                          onPressed: () {
                            final comunityDataForAction = Provider.of<CommunityData>(context, listen: false);
                            bool newLikedStatus = !currentEventState.isLiked;
                            comunityDataForAction.updateEventInCommunity(
                              community,
                              currentEventState,
                              newLikedStatus: newLikedStatus,
                            );
                          },
                        ),
                        Text(
                          '${currentEventState.likes}', 
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: currentEventState.isLiked ? Colors.redAccent : Colors.grey[700],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade400, size: 20),
                label: Text(
                  'Remove', 
                  style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontFamily: 'Inter'),
                ),
                onPressed: () => _confirmRemoveEvent(context, communityData, community, event),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _confirmRemoveEvent(BuildContext context, CommunityData communityData, Community community, Event event) {
     showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Confirm Removal', style: Theme.of(context).textTheme.headlineSmall),
            content: Text('Are you sure you want to remove the event "${event.name}" from the community "${community.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: (){
                  communityData.removeEventFromCommunity(community, event);
                  Navigator.of(dialogContext).pop(); 
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Event "${event.name}" removed from ${community.name}.'))
                  );
                },
                child: const Text('Remove')
              ),
            ],
          );
        }
    );
  }
}
