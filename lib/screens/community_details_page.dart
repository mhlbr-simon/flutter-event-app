import 'package:eventapp/providers/community_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';  
import '../models/community.dart';
import '../models/event.dart';
import '../providers/event_data.dart';
import '../widgets/event_in_communities_card.dart'; 
import '../colors.dart'; 

class CommunityDetailsPage extends StatefulWidget {
  final Community community;

  const CommunityDetailsPage({super.key, required this.community});

  @override
  State<CommunityDetailsPage> createState() => _CommunityDetailsPageState();
}

class _CommunityDetailsPageState extends State<CommunityDetailsPage> {
  final _privateEventFormKey = GlobalKey<FormState>();
  String _eventName = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late String _eventLocation; 
  String _eventVenue = '';
  String _eventVenueAddress = '';
  String _eventImageUrl = 'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'; 
  String _eventDescription = '';
  String _eventCategory = 'Other'; 
  String _eventGenre = 'No genre'; 
  String _eventArtist = '';

  @override
  void initState() {
    super.initState();
    _eventLocation = Provider.of<EventData>(context, listen: false).location;
  }

  Future<void> _selectDate(BuildContext context, StateSetter setStateDialog) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), 
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), 
       builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary, 
                onPrimary: Theme.of(context).colorScheme.onPrimary
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setStateDialog(() { 
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, StateSetter setStateDialog) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
             colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary, 
                onPrimary: Theme.of(context).colorScheme.onPrimary
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setStateDialog(() { 
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityData>(
        builder: (context, communityData, child) {
          // Find the most up-to-date community instance from AppData
          final Community currentCommunity;
          try {
            currentCommunity = communityData.communities.firstWhere(
                (c) => c.name == widget.community.name && c.description == widget.community.description,
            );
          } catch (e) {
            // Community was likely deleted, pop back
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Community no longer exists.')),
                );
              }
            });
            // Return a dummy community to avoid build errors before pop
            return Scaffold(appBar: AppBar(title: Text(widget.community.name)), body: const Center(child: Text("Community not found.")));
          }


          List<Event> sortedEvents = List.from(currentCommunity.events);
          sortedEvents.sort((a, b) {
            if (a.isPrivate && !b.isPrivate) return -1; 
            if (!a.isPrivate && b.isPrivate) return 1;
            
            // Date comparison (newest first, then fallback to name)
            try {
                DateTime dateA = DateFormat('yyyy-MM-dd').parse(a.date);
                DateTime dateB = DateFormat('yyyy-MM-dd').parse(b.date);
                int dateComparison = dateB.compareTo(dateA); // Sorts newest first
                if (dateComparison != 0) return dateComparison;
            } catch (e) {
                // Handle cases where date might not be parsable, though unlikely with Ticketmaster data
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return Scaffold(
            appBar: AppBar(
              title: Text(currentCommunity.name), 
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentCommunity.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Events in this Community:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Inter', fontSize: 18), 
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: currentCommunity.events.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No events in this community yet. Tap "Create Event" to create one or add one of the public events to this community.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])
                                ),
                              )
                            )
                          : ListView.builder(
                        itemCount: sortedEvents.length,
                        itemBuilder: (context, index) {
                          final event = sortedEvents[index];
                          return EventInCommunityCard(event: event, community: currentCommunity);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                _showAddPrivateEventDialog(context, currentCommunity);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
              tooltip: 'Add a private event to this community',
            ),
          );
        }
    );
  }

  void _resetFormFields() {
    _eventName = '';
    _selectedDate = null;
    _selectedTime = null;
    _eventLocation = Provider.of<EventData>(context, listen: false).location; 
    _eventVenue = '';
    _eventVenueAddress = '';
    _eventImageUrl = 'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';
    _eventDescription = '';
    _eventCategory = 'Other';
    _eventGenre = 'No genre';
    _eventArtist = '';
  }

  void _showAddPrivateEventDialog(BuildContext context, Community community) {
    _resetFormFields(); 

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              final eventData = Provider.of<EventData>(context, listen: false); 
              return AlertDialog(
                title: Text('Add Event to ${community.name}', style: Theme.of(context).textTheme.headlineSmall),
                content: Form(
                  key: _privateEventFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Event Name*'),
                          validator: (value) => (value == null || value.isEmpty) ? 'Event name is required' : null,
                          onChanged: (value) => _eventName = value.trim(),
                           textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16), 
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, setStateDialog),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date*',
                                    errorText: _selectedDate == null && (_privateEventFormKey.currentState?.mounted == true && _privateEventFormKey.currentState?.validate() == false) ? "Required" : null,
                                    ),
                                  child: Text(_selectedDate != null ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!) : 'Select Date'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, setStateDialog),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Time*',
                                     errorText: _selectedTime == null && (_privateEventFormKey.currentState?.mounted == true && _privateEventFormKey.currentState?.validate() == false) ? "Required" : null,
                                    ),
                                  child: Text(_selectedTime != null ? _selectedTime!.format(context) : 'Select Time'),
                                ),
                              ),
                            ),
                          ],
                        ),
                         const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _eventLocation, 
                          items: eventData.locations.map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                                setStateDialog(() { _eventLocation = newValue; });
                            }
                          },
                          decoration: const InputDecoration(labelText: 'Location*'),
                          validator: (value) => (value == null || value.isEmpty) ? 'Location is required' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Venue*'),
                          validator: (value) => (value == null || value.isEmpty) ? 'Venue is required' : null,
                          onChanged: (value) => _eventVenue = value.trim(),
                          textCapitalization: TextCapitalization.words,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Venue Address (Optional)'),
                          onChanged: (value) => _eventVenueAddress = value.trim(),
                           textCapitalization: TextCapitalization.words,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Description*'),
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty) ? 'Description is required' : null,
                          onChanged: (value) => _eventDescription = value.trim(),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                         const SizedBox(height: 16),
                         TextFormField(
                           initialValue: _eventCategory,
                           decoration: const InputDecoration(labelText: 'Category (e.g., Music, Sports)*'),
                           validator: (value) => (value == null || value.isEmpty) ? 'Category is required' : null,
                           onChanged: (value) => _eventCategory = value.trim().isEmpty ? 'Other' : value.trim(),
                           textCapitalization: TextCapitalization.words,
                         ),
                        const SizedBox(height: 20),
                        Text("This event will be private to this community.", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      bool isDateTimeValid = true;
                      if (_selectedDate == null || _selectedTime == null) {
                        isDateTimeValid = false;
                        // Trigger validation display if form key is available and mounted
                        if (_privateEventFormKey.currentState?.mounted ?? false) {
                            _privateEventFormKey.currentState?.validate(); 
                        }
                        setStateDialog((){}); // Rebuild to show error messages
                      }

                      if ((_privateEventFormKey.currentState?.validate() ?? false) && isDateTimeValid) {
                        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                        final formattedTime = _selectedTime!.format(context); 

                        final newEvent = Event(
                          name: _eventName,
                          date: formattedDate,
                          location: _eventLocation,
                          venue: _eventVenue,
                          venueAddress: _eventVenueAddress.isEmpty ? 'Not specified' : _eventVenueAddress,
                          startTime: formattedTime,
                          imageUrl: _eventImageUrl, 
                          description: _eventDescription,
                          category: _eventCategory,
                          genre: _eventGenre, 
                          isPrivate: true, 
                          artist: _eventArtist.isEmpty ? 'N/A' : _eventArtist, 
                          likes: 0, 
                          isLiked: false,
                        );
                        Provider.of<CommunityData>(context, listen: false).addPrivateEventToCommunity(community, newEvent);
                        Navigator.of(dialogContext).pop(); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Private event "${newEvent.name}" added to ${community.name}.')),
                        );
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Please fill all required fields (*).')),
                         );
                      }
                    },
                    child: const Text('Create Event'),
                  ),
                ],
              );
            }
        );
      },
    );
  }
}