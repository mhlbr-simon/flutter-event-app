import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../models/event.dart';
import '../models/community.dart';
import '../colors.dart';
import '../providers/community_data.dart'; 



class EventCard extends StatefulWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with TickerProviderStateMixin {
  bool _isFlipped = false;
  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;

  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;
  double _dragOffsetX = 0.0;

  bool _isLocallyLiked = false;

  static const double _swipeThresholdFactor = 0.25;
  static const double _maxDragFactor = 0.35;

  @override
  void initState() {
    super.initState();
    _isLocallyLiked = widget.event.isLiked; // Initialize local like status from event

    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {
        _dragOffsetX = _slideAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event.isLiked != oldWidget.event.isLiked) {
      setState(() {
        _isLocallyLiked = widget.event.isLiked;
      });
    }
  }


  @override
  void dispose() {
    _flipAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_flipAnimationController.isAnimating || _slideAnimationController.isAnimating) return;
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _flipAnimationController.forward();
      } else {
        _flipAnimationController.reverse();
      }
    });
  }

  void _animateDragOffsetXTo(double target) {
    _slideAnimation = Tween<double>(begin: _dragOffsetX, end: target)
        .animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut));
    _slideAnimationController.forward(from: 0.0);
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty || Uri.tryParse(imageUrl)?.hasAbsolutePath != true) {
      return Container(
        color: Colors.grey[300],
        child: Center(child: Icon(Icons.event_seat_rounded, color: Colors.grey[600], size: 50)),
      );
    }
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey[600], size: 50)),
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final appData = Provider.of<AppData>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final swipeThreshold = cardWidth * _swipeThresholdFactor;
        final maxDrag = cardWidth * _maxDragFactor;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            _slideAnimationController.stop();
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffsetX += details.delta.dx;
              _dragOffsetX = _dragOffsetX.clamp(0.0, maxDrag);
            });
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;

            if (_dragOffsetX > swipeThreshold && velocity >= 0) {
              _showAddEventToCommunityDialog(context, widget.event);
              _animateDragOffsetXTo(0.0);
            } else {
              _animateDragOffsetXTo(0.0);
            }
          },
          onTap: () {
            if (_dragOffsetX.abs() < 5.0 && !_slideAnimationController.isAnimating) {
              _flipCard();
            } else if (!_slideAnimationController.isAnimating) {
              _animateDragOffsetXTo(0.0);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (_dragOffsetX / swipeThreshold).clamp(0.0, 1.0),
                  child: Container(
                    margin: Theme.of(context).cardTheme.margin,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
                      borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.playlist_add_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Text(
                              "Add",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter'
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(_dragOffsetX, 0),
                child: AspectRatio(
                  aspectRatio: 1.2, 
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, animatedChild) {
                      final isFront = _flipAnimation.value < 0.5;
                      final angle = _flipAnimation.value * 3.1415927;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: isFront
                            ? _buildFront(textTheme)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(3.1415927),
                                child: _buildBack(textTheme),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFront(TextTheme textTheme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildImage(widget.event.imageUrl),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.center,
                 children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           widget.event.name,
                           style: textTheme.titleMedium,
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                         ),
                          const SizedBox(height: 2),
                         Text(
                           '${widget.event.date} - ${widget.event.venue}',
                           style: textTheme.bodySmall,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     ),
                   ),
                   // Local like button (not tied to community likes)
                   Padding(
                     padding: const EdgeInsets.only(left: 8.0),
                     child: IconButton(
                       icon: Icon(
                         _isLocallyLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                         color: _isLocallyLiked ? Colors.redAccent : textOnSurface.withOpacity(0.7),
                         size: 28,
                       ),
                       onPressed: () {
                         setState(() {
                           _isLocallyLiked = !_isLocallyLiked;
                           // This is a local like, not tied to community.
                           // If you want to persist this, you'd need to save it somewhere.
                         });
                       },
                       tooltip: _isLocallyLiked ? 'Remove from local favorites' : 'Add to local favorites',
                     ),
                   ),
                 ],
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(TextTheme textTheme) {
    bool hasDescription = widget.event.description.isNotEmpty && widget.event.description != 'No description available.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.name,
              style: textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            if (widget.event.artist.isNotEmpty && widget.event.artist != 'Unknown Artist' && widget.event.artist != 'N/A')
              _buildDetailRow(Icons.mic_external_on_rounded, 'Artist:', widget.event.artist, textTheme),
            _buildDetailRow(Icons.calendar_today_rounded, 'Date:', widget.event.date, textTheme),
            if (widget.event.startTime != 'No start time available')
              _buildDetailRow(Icons.access_time_rounded, 'Time:', widget.event.startTime, textTheme),
            _buildDetailRow(Icons.location_on_rounded, 'Venue:', widget.event.venue, textTheme),
            if (widget.event.venueAddress != 'No address available')
              _buildDetailRow(Icons.pin_drop_rounded, 'Address:', widget.event.venueAddress, textTheme),
            _buildDetailRow(Icons.public_rounded, 'City:', widget.event.location, textTheme),
            if (widget.event.genre != 'No genre')
              _buildDetailRow(Icons.category_rounded, 'Genre:', widget.event.genre, textTheme),
            _buildDetailRow(Icons.label_rounded, 'Category:', widget.event.category, textTheme),
            
            const SizedBox(height: 4),

            if (hasDescription)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                       style: textTheme.labelLarge?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: (textTheme.labelLarge?.fontSize ?? 14) * 0.9,
                      )
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          widget.event.description,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * 0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(), // Takes up space if no description

            const SizedBox(height: 4),
            _buildDetailRow(
              widget.event.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
              'Type:',
              widget.event.isPrivate ? 'Private Community Event' : 'Public Event', textTheme,
            ),
          ],
        ),
      ),
    );
}

  Widget _buildDetailRow(IconData icon, String label, String value, TextTheme textTheme) {
    if (value.isEmpty || value == 'N/A') return const SizedBox.shrink();
    if (label == 'Artist:' && value == 'Unknown Artist') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label ',
             style: textTheme.labelMedium?.copyWith(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: (textTheme.labelMedium?.fontSize ?? 13) * 0.9,
            )
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'Inter',
                fontSize: (textTheme.bodySmall?.fontSize ?? 12) * 0.95,
              ),
              softWrap: true,
              maxLines: (label == 'Address:' || label == 'Venue:' || label == 'Name:') ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            )
          ),
        ],
      ),
    );
  }

  void _showAddEventToCommunityDialog(BuildContext context, Event event) {
    final communityData = Provider.of<CommunityData>(context, listen: false);;
    if (communityData.communities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No communities available. Create one first!')),
      );
      return;
    }

    Set<Community> selectedCommunities = {};

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Add Event to Community', style: Theme.of(context).textTheme.headlineSmall),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: communityData.communities.isEmpty
                  ? const Text("No communities created yet.")
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('Select communities for "${event.name}":', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'Inter')),
                        ),
                        ...communityData.communities.map((community) => CheckboxListTile(
                              title: Text(community.name),
                              value: selectedCommunities.contains(community),
                              onChanged: (bool? value) {
                                setStateDialog(() {
                                  if (value == true) {
                                    selectedCommunities.add(community);
                                  } else {
                                    selectedCommunities.remove(community);
                                  }
                                });
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                            )),
                      ],
                    ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCommunities.isNotEmpty) {
                  for (var community in selectedCommunities) {
                    communityData.addEventToCommunity(community, event);
                  }
                  Navigator.of(dialogContext).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Event added to ${selectedCommunities.length} community(ies).')),
                  );
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one community.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
