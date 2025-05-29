import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/event_data.dart'; 
import '../providers/community_data.dart';
import '../models/event.dart';   
import '../models/community.dart'; 
import '../widgets/event_card.dart'; 
import '../colors.dart'; 

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> _selectedCategories = [];
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final eventData = Provider.of<EventData>(context, listen: false);
    _searchController = TextEditingController(text: eventData.searchText);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !eventData.isLoadingMore && eventData.hasMoreEvents) {
        eventData.loadMoreEvents();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCommunityFilterDialog(BuildContext context) {
    final communityData = Provider.of<CommunityData>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Filter by Community', style: Theme.of(context).textTheme.headlineSmall),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                RadioListTile<Community?>(
                  title: const Text('All Public Events'),
                  value: null,
                  groupValue: communityData.selectedCommunity,
                  onChanged: (Community? value) {
                    communityData.setSelectedCommunity(value);
                    setState(() {
                      _selectedCategories = [];
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                ...communityData.communities.map((Community community) {
                  return RadioListTile<Community?>(
                    title: Text(community.name),
                    value: community,
                    groupValue: communityData.selectedCommunity,
                    onChanged: (Community? value) {
                      communityData.setSelectedCommunity(value);
                      setState(() {
                         _selectedCategories = [];
                      });
                      Navigator.of(dialogContext).pop();
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDateFilterPicker(BuildContext context) async {
    final eventData = Provider.of<EventData>(context, listen: false);
    final DateTime now = DateTime.now();
    final DateTime initialStart = eventData.selectedStartDate ?? now;
    final DateTime initialEnd = eventData.selectedEndDate ?? initialStart;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, now.month, now.day),
      lastDate: DateTime(now.year + 5, now.month, now.day),
      initialDateRange: eventData.selectedStartDate != null && eventData.selectedEndDate != null
          ? DateTimeRange(start: initialStart, end: initialEnd)
          : null,
      helpText: 'Select Date Range',
      cancelText: 'CANCEL',
      confirmText: 'APPLY',
      saveText: 'APPLY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      eventData.setDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final communityData = Provider.of<CommunityData>(context);
    final eventData = Provider.of<EventData>(context);
    final appBarTextStyle = Theme.of(context).appBarTheme.titleTextStyle;

    final ChipThemeData chipTheme = Theme.of(context).chipTheme;
    final TextStyle? selectedChipTextStyle = chipTheme.secondaryLabelStyle;
    final TextStyle? unselectedChipTextStyle = chipTheme.labelStyle;

    List<Event> eventsToDisplay;

    if (communityData.selectedCommunity != null) {
      eventsToDisplay = communityData.selectedCommunity!.events
          .where((event) => event.location == eventData.location)
          .toList();
      if (_selectedCategories.isNotEmpty) {
        eventsToDisplay = eventsToDisplay.where((event) => _selectedCategories.contains(event.category)).toList();
      }
    } else {
      eventsToDisplay = eventData.events
          .where((event) => !event.isPrivate)
          .toList();
      if (_selectedCategories.isNotEmpty) {
        eventsToDisplay = eventsToDisplay.where((event) => _selectedCategories.contains(event.category)).toList();
      }
    }

    if (eventData.searchText.isNotEmpty) {
      final searchTextLower = eventData.searchText.toLowerCase();
      eventsToDisplay = eventsToDisplay.where((event) =>
          event.venue.toLowerCase().contains(searchTextLower) ||
          event.name.toLowerCase().contains(searchTextLower) ||
          event.artist.toLowerCase().contains(searchTextLower)).toList();
    }

    if (communityData.selectedCommunity != null && eventData.selectedStartDate != null && eventData.selectedEndDate != null) {
      eventsToDisplay = eventsToDisplay.where((event) {
        if (event.date.isEmpty) return false;
        try {
          DateTime eventDate = DateFormat('yyyy-MM-dd').parse(event.date);
          DateTime startDateNormalized = DateTime(eventData.selectedStartDate!.year, eventData.selectedStartDate!.month, eventData.selectedStartDate!.day);
          DateTime endDateBoundary = DateTime(eventData.selectedEndDate!.year, eventData.selectedEndDate!.month, eventData.selectedEndDate!.day, 23, 59, 59);
          
          return !eventDate.isBefore(startDateNormalized) && !eventDate.isAfter(endDateBoundary);
        } catch (e) {
          debugPrint("Error parsing event date for local filtering: ${event.date} - $e");
          return false;
        }
      }).toList();
    }

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
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('Upcoming Events in ', style: appBarTextStyle),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: eventData.location,
                items: eventData.locations.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != eventData.location) {
                    setState(() {
                      _selectedCategories = [];
                    });
                    Provider.of<EventData>(context, listen: false).setLocation(newValue);
                  }
                },
                style: appBarTextStyle?.copyWith(fontWeight: FontWeight.bold),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                focusColor: Colors.transparent,
                dropdownColor: cardAndInputColor,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.people_outline_rounded),
              tooltip: 'Filter by Community',
              onPressed: () {
                _showCommunityFilterDialog(context);
              },
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by location, event and artist',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: eventData.searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    eventData.setSearchText('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        ),
                        onChanged: eventData.setSearchText,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardAndInputColor,
                        borderRadius: BorderRadius.circular(25.0),
                        border: Border.all(color: Colors.grey[350]!, width: 1.0),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          color: (eventData.selectedStartDate != null || eventData.selectedEndDate != null)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[700],
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(10.0),
                        constraints: const BoxConstraints(),
                        tooltip: 'Filter by date',
                        onPressed: () => _showDateFilterPicker(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (eventData.selectedStartDate != null && eventData.selectedEndDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
                  child: Chip(
                    label: Text(
                      () {
                        final DateFormat formatter = DateFormat('MMM d, yyyy');
                        bool isSameDay = eventData.selectedStartDate!.year == eventData.selectedEndDate!.year &&
                            eventData.selectedStartDate!.month == eventData.selectedEndDate!.month &&
                            eventData.selectedStartDate!.day == eventData.selectedEndDate!.day;
                        if (isSameDay) {
                          return 'Date: ${formatter.format(eventData.selectedStartDate!)}';
                        } else {
                          return 'Range: ${formatter.format(eventData.selectedStartDate!)} - ${formatter.format(eventData.selectedEndDate!)}';
                        }
                      }(),
                    ),
                    onDeleted: () {
                      eventData.clearDateFilter();
                    },
                    deleteIcon: const Icon(Icons.cancel_rounded, size: 18),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                    deleteIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (eventData.eventCategories.isNotEmpty || (communityData.selectedCommunity != null && communityData.selectedCommunity!.events.any((e) => e.category.isNotEmpty)))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: const Text("All"),
                            selected: _selectedCategories.isEmpty,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.clear();
                                }
                              });
                            },
                            selectedColor: chipTheme.selectedColor,
                            checkmarkColor: textOnPrimary,
                            labelStyle: _selectedCategories.isEmpty ? selectedChipTextStyle : unselectedChipTextStyle,
                          ),
                        ),
                      ...(() {
                        if (communityData.selectedCommunity != null) {
                          final categories = communityData.selectedCommunity!.events
                              .map((e) => e.category)
                              .where((c) => c.isNotEmpty)
                              .toSet()
                              .toList();
                          categories.sort();
                          return categories;
                        } else {
                          return eventData.eventCategories;
                        }
                      })().map((category) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategories.contains(category),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(category);
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                });
                              },
                              selectedColor: chipTheme.selectedColor,
                              checkmarkColor: textOnPrimary,
                              labelStyle: _selectedCategories.contains(category) ? selectedChipTextStyle : unselectedChipTextStyle,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: (eventData.isLoadingMore && eventsToDisplay.isEmpty && eventData.currentPage == 0)
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : eventsToDisplay.isEmpty
                        ? Center(
                            child: Text(
                            eventData.isLoadingMore ? 'Loading...' : 'No events found for your criteria.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 4.0),
                            itemCount: eventsToDisplay.length + (eventData.hasMoreEvents && communityData.selectedCommunity == null && !eventData.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < eventsToDisplay.length) {
                                return EventCard(event: eventsToDisplay[index]);
                              } else if (eventData.hasMoreEvents && communityData.selectedCommunity == null && !eventData.isLoadingMore) {
                                return _buildLoadMoreIndicator(context);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
              ),
              if (eventData.isLoadingMore && (eventsToDisplay.isNotEmpty || eventData.currentPage > 0))
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    final eventData = Provider.of<EventData>(context, listen: false);
    final communityData = Provider.of<CommunityData>(context, listen: false);
    if (eventData.isLoadingMore || !eventData.hasMoreEvents || communityData.selectedCommunity != null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(child: Text("Scroll to load more...", style: Theme.of(context).textTheme.bodySmall)),
    );
  }
}