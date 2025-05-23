// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
// import 'splash_screen.dart'; // If you have a separate file, keep this. Otherwise, see SplashScreen class below.

// ---- COLORS ----
const Color primaryColor = Color(0xFF182139); // THE INTENDED DARK BLUE
const Color lightBackgroundColor = Color(0xFFECEFF1); // Very light Grey
const Color cardAndInputColor = Colors.white;
const Color textOnPrimary = Colors.white; // Text on the new dark blue
const Color textOnSurface = Color(0xFF212121); // Nearly black for good contrast
const Color unselectedChipTextColor = primaryColor; // Will use the new primaryColor
const Color unselectedChipBackground = Colors.white;
const Color scaffoldBodyGradientBottom = Color(0xFFD8E2F0); // Kept very light for soft gradient & legibility
// ---- END COLORS ----

void main() {
  runApp(
    ChangeNotifierProvider<AppData>(
      create: (context) => AppData(),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class AppData extends ChangeNotifier {
  String location = 'Leipzig';
  List<String> eventCategories = [];
  List<String> locations = ['Leipzig', 'Berlin', 'Dresden'];
  List<Event> events = [];
  List<Community> communities = [];
  Profile profile = Profile(name: 'New User', bio: 'Write something about yourself.');
  Community? selectedCommunity;
  int eventsPerPage = 50;
  int currentPage = 0;
  bool isLoadingMore = false;
  bool hasMoreEvents = true;
  String searchText = ''; // For EventsTab search

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  AppData() {
    fetchEventsFromTicketmaster();
  }

  Future<void> fetchEventsFromTicketmaster() async {
    if (isLoadingMore) return;

    isLoadingMore = true;
    notifyListeners();

    const apiKey = 'FjmzhCsYGAorO6yhHcsllQ58elJiMB63'; // Replace with your actual API key
    final String city = location;

    // Base URL
    String apiUrlString =
        'https://app.ticketmaster.com/discovery/v2/events.json?apikey=$apiKey&city=$city&size=$eventsPerPage&page=$currentPage&sort=date,asc';

    // Add date parameters if selected
    if (selectedStartDate != null) {
      // Format for API: YYYY-MM-DDTHH:mm:ssZ (UTC)
      String formattedStart = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(selectedStartDate!.toUtc());
      apiUrlString += '&startDateTime=$formattedStart';
    }
    if (selectedEndDate != null) {
      // To include the whole end day, set time to 23:59:59 UTC for the API query
      DateTime endOfDayUTC = DateTime.utc(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day, 23, 59, 59);
      String formattedEnd = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(endOfDayUTC);
      apiUrlString += '&endDateTime=$formattedEnd';
    }

    final url = Uri.parse(apiUrlString);
    debugPrint("Fetching events from URL: $url");


    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['_embedded'] != null && data['_embedded']['events'] != null) {
          final List<Event> fetchedEvents = [];
          List<String> fetchedCategories = [];

          for (var eventJson in data['_embedded']['events']) {
            final category = (eventJson['classifications'] as List?)?.first?['segment']?['name'] ?? 'Other';
            final venueName = eventJson['_embedded']?['venues']?[0]?['name'] ?? 'Unknown venue';
            final venueAddress = eventJson['_embedded']?['venues']?[0]?['address']?['line1'] ?? 'No address available';
            final startTime = eventJson['dates']?['start']?['localTime'] ?? 'No start time available';
            final artist = eventJson['name'] ?? 'Unknown Artist'; // Ticketmaster often puts artist in event name for concerts

            String imageUrl = 'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'; // Default image
            if (eventJson['images'] != null && (eventJson['images'] as List).isNotEmpty) {
                var suitableImage = (eventJson['images'] as List).firstWhere(
                    (img) => img['ratio'] == '16_9' && (img['width'] ?? 0) > 500,
                    orElse: () => (eventJson['images'] as List).firstWhere(
                          (img) => (img['width'] ?? 0) > 500,
                          orElse: () => (eventJson['images'] as List).firstOrNull,
                        ),
                );
                if (suitableImage != null && suitableImage['url'] != null) {
                  imageUrl = suitableImage['url'];
                }
            }

            fetchedEvents.add(Event(
              name: eventJson['name'] ?? 'Unknown',
              date: eventJson['dates']?['start']?['localDate'] ?? '',
              location: city, // The city we queried for
              venue: venueName,
              venueAddress: venueAddress,
              startTime: startTime,
              imageUrl: imageUrl,
              description: eventJson['info'] ?? eventJson['pleaseNote'] ?? 'No description available.',
              category: category,
              genre: (eventJson['classifications'] as List?)?.first?['genre']?['name'] ?? 'No genre',
              isPrivate: false,
              artist: artist, // Using event name as artist placeholder if specific field not available
            ));

            if (!fetchedCategories.contains(category)) {
              fetchedCategories.add(category);
            }
          }

          if (currentPage == 0) {
            events = fetchedEvents;
          } else {
            events.addAll(fetchedEvents);
          }
          
          hasMoreEvents = fetchedEvents.length == eventsPerPage;
          
          if (currentPage == 0 || fetchedCategories.any((cat) => !eventCategories.contains(cat))) {
             eventCategories = <String>{...eventCategories, ...fetchedCategories}.toList();
             eventCategories.sort(); // Sort categories alphabetically
          }
          
          notifyListeners();
        } else {
          hasMoreEvents = false; 
          if (currentPage == 0) {
            events = []; 
            eventCategories = []; // Reset categories if no events found on first page
          }
          notifyListeners();
        }
      } else {
        debugPrint('Failed to fetch events: ${response.statusCode}');
        hasMoreEvents = false;
        if (currentPage == 0) {
            events = [];
            eventCategories = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching Ticketmaster events: $e');
      hasMoreEvents = false;
      if (currentPage == 0) {
        events = [];
        eventCategories = [];
      }
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void setDateFilter(DateTimeRange? range) {
    bool changed = false;
    if (range == null) { 
      if (selectedStartDate != null || selectedEndDate != null) {
        selectedStartDate = null;
        selectedEndDate = null;
        changed = true;
      }
    } else { 
      if (selectedStartDate != range.start || selectedEndDate != range.end) {
        selectedStartDate = range.start;
        selectedEndDate = range.end;
        changed = true;
      }
    }

    if (changed) {
      currentPage = 0;
      events = [];
      eventCategories = []; 
      hasMoreEvents = true; 
      fetchEventsFromTicketmaster(); 
    }
  }

  void clearDateFilter() {
    setDateFilter(null);
  }


  void loadMoreEvents() async {
    if (!isLoadingMore && hasMoreEvents) {
      currentPage++;
      await fetchEventsFromTicketmaster();
    }
  }

  void addCommunity(Community community) {
    communities.add(community);
    notifyListeners();
  }

  void deleteCommunity(Community community) {
    communities.remove(community);
    if (selectedCommunity == community) {
      selectedCommunity = null;
    }
    notifyListeners();
  }

  void addEventToCommunity(Community community, Event event) {
    if (!community.events.any((e) => e.name == event.name && e.date == event.date && e.venue == event.venue)) {
      community.events.add(event.copyWith(likes: 0, isLiked: false));
      notifyListeners();
    }
  }

  void addPrivateEventToCommunity(Community community, Event event) {
    if (!community.events.any((e) => e.name == event.name && e.date == event.date && e.venue == event.venue)) {
      community.events.add(event.copyWith(isPrivate: true, likes: 0, isLiked: false));
      notifyListeners();
    }
  }

  void updateProfile(Profile newProfile) {
    profile = newProfile;
    notifyListeners();
  }

  void updateEventInCommunity(Community community, Event eventToUpdate, {required bool newLikedStatus}) {
    final communityInList = communities.firstWhere((c) => c.name == community.name, orElse: () {
      debugPrint("Warning: updateEventInCommunity called with a community not found in AppData's list by name. Operations might be on a detached instance.");
      return community;
    });

    final eventIndex = communityInList.events.indexWhere((event) =>
        event.name == eventToUpdate.name &&
        event.date == eventToUpdate.date &&
        event.venue == eventToUpdate.venue &&
        event.isPrivate == eventToUpdate.isPrivate
    );

    if (eventIndex != -1) {
      Event currentEventInCommunity = communityInList.events[eventIndex];
      int newLikesCount = currentEventInCommunity.likes;

      if (currentEventInCommunity.isLiked != newLikedStatus) {
        if (newLikedStatus == true) {
          newLikesCount++;
        } else {
          newLikesCount = (newLikesCount > 0) ? newLikesCount - 1 : 0;
        }
      }

      communityInList.events[eventIndex] = currentEventInCommunity.copyWith(
        isLiked: newLikedStatus,
        likes: newLikesCount,
      );
      notifyListeners();
    } else {
        debugPrint("Warning: Event to update not found in community '${community.name}'. Event: ${eventToUpdate.name}");
    }
  }

  void addEvent(Event event) {
    events.add(event);
    notifyListeners();
  }

  void setSelectedCommunity(Community? community) {
    selectedCommunity = community;
    notifyListeners();
  }

  void setLocation(String newLocation) {
    if (location == newLocation && events.isNotEmpty && !isLoadingMore && selectedStartDate == null) return; 
    location = newLocation;
    currentPage = 0;
    hasMoreEvents = true;
    events = [];
    eventCategories = []; 
    fetchEventsFromTicketmaster(); 
  }

  void setSearchText(String text) { 
    searchText = text;
    notifyListeners();
  }

  void removeEventFromCommunity(Community community, Event event) {
    final communityInList = communities.firstWhere((c) => c.name == community.name, orElse: () => community);
    int initialLength = communityInList.events.length;
    communityInList.events.removeWhere((e) =>
        e.name == event.name &&
        e.date == event.date &&
        e.venue == event.venue &&
        e.isPrivate == event.isPrivate
    );
    if (communityInList.events.length < initialLength) {
        notifyListeners();
    }
  }
}

class Event {
  final String name;
  final String date; 
  final String location;
  final String venue;
  final String venueAddress;
  final String startTime;
  final String imageUrl;
  final String description;
  final String category;
  final String genre;
  final bool isLiked;
  final bool isPrivate;
  final String artist;
  final int likes;

  Event({
    required this.name,
    required this.date,
    required this.location,
    required this.venue,
    required this.venueAddress,
    required this.startTime,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.genre,
    this.isLiked = false,
    this.isPrivate = false,
    required this.artist,
    this.likes = 0,
  });

  Event copyWith({
    String? name,
    String? date,
    String? location,
    String? venue,
    String? venueAddress,
    String? startTime,
    String? imageUrl,
    String? description,
    String? category,
    String? genre,
    bool? isLiked,
    bool? isPrivate,
    String? artist,
    int? likes,
  }) {
    return Event(
      name: name ?? this.name,
      date: date ?? this.date,
      location: location ?? this.location,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      startTime: startTime ?? this.startTime,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      genre: genre ?? this.genre,
      isLiked: isLiked ?? this.isLiked,
      isPrivate: isPrivate ?? this.isPrivate,
      artist: artist ?? this.artist,
      likes: likes ?? this.likes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          date == other.date &&
          venue == other.venue &&
          isPrivate == other.isPrivate;

  @override
  int get hashCode =>
      name.hashCode ^
      date.hashCode ^
      venue.hashCode ^
      isPrivate.hashCode;
}

class Community {
  String name;
  String description;
  List<Event> events = [];

  Community({
    required this.name,
    required this.description,
    List<Event>? initialEvents,
  }) : events = initialEvents ?? [];
}

class Profile {
  String name;
  String bio;

  Profile({
    required this.name,
    required this.bio,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Typography.material2021(platform: TargetPlatform.android).black;

    ColorScheme generatedScheme = ColorScheme.fromSeed(
      seedColor: primaryColor, 
      brightness: Brightness.light,
      background: lightBackgroundColor,
      surface: cardAndInputColor,    
      onSurface: textOnSurface,      
    );

    final finalColorScheme = generatedScheme.copyWith(
      primary: primaryColor,            
      onPrimary: textOnPrimary,         
      primaryContainer: primaryColor,   
      onPrimaryContainer: textOnPrimary,
    );
    
    return MaterialApp(
      title: 'Community Events',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: finalColorScheme, 
        scaffoldBackgroundColor: lightBackgroundColor,
        textTheme: baseTextTheme.copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface),
          displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface),
          displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface, fontSize: 20), 
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface, fontSize: 22), 
          titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface, fontSize: 20, fontWeight: FontWeight.bold), 
          titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: 'Inter', color: textOnSurface),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: 'Inter', color: textOnSurface),
          bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: 'Inter', color: Colors.grey[700], fontSize: 13), 
          labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: 'Inter', color: textOnSurface, fontWeight: FontWeight.w500), 
          labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: 'Inter', color: textOnSurface),
          labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: 'Inter', color: Colors.grey[600]),
        ).apply(
          bodyColor: textOnSurface,
          displayColor: textOnSurface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0, 
          iconTheme: IconThemeData(color: finalColorScheme.primary), 
          actionsIconTheme: IconThemeData(color: finalColorScheme.primary), 
          titleTextStyle: baseTextTheme.titleLarge?.copyWith(fontFamily: 'Jersey 10', color: textOnSurface, fontSize: 22),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardAndInputColor,
          hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Inter', fontSize: 14),
          prefixIconColor: Colors.grey[600],
          suffixIconColor: Colors.grey[600],
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: Colors.grey[350]!, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: Colors.grey[350]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: finalColorScheme.primary, width: 1.5), 
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: unselectedChipBackground,
          selectedColor: finalColorScheme.primary, 
          labelStyle: TextStyle(fontFamily: 'Inter', color: unselectedChipTextColor, fontSize: 13, fontWeight: FontWeight.w500), 
          secondaryLabelStyle: TextStyle(fontFamily: 'Inter', color: finalColorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w500), 
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          side: BorderSide(color: Colors.grey[400]!, width: 1.0), 
          elevation: 0,
          pressElevation: 2,
          checkmarkColor: finalColorScheme.onPrimary, 
        ),
        cardTheme: CardThemeData(
          elevation: 1.0, 
          color: cardAndInputColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        navigationBarTheme: NavigationBarThemeData( 
            backgroundColor: cardAndInputColor,
            indicatorColor: finalColorScheme.primary, 
            indicatorShape: const StadiumBorder(),
            elevation: 0, 
            height: 65, 
            iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>((states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(size: 28, color: finalColorScheme.onPrimary); 
              }
              return IconThemeData(size: 26, color: finalColorScheme.primary.withOpacity(0.8)); 
            }),
            labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>((states) {
              const style = TextStyle(fontFamily: 'Inter', fontSize: 10);
              if (states.contains(MaterialState.selected)) {
                return style.copyWith(color: finalColorScheme.onPrimary);
              }
              return style.copyWith(color: finalColorScheme.primary); 
            }),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: finalColorScheme.primary, 
            textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: finalColorScheme.primary, 
            foregroundColor: finalColorScheme.onPrimary, 
            textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: finalColorScheme.primary), 
        ),
        canvasColor: cardAndInputColor, 
      ),
      home: const SplashScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Placeholder SplashScreen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a delay for the splash screen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can use your logo here
            Image.asset('assets/images/looped_logo.png', width: 100, height: 100),
            const SizedBox(height: 20),
            Text(
              'Community Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textOnPrimary,
                fontFamily: 'Jersey 10'
              ),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(textOnPrimary.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
// --- End Placeholder SplashScreen ---


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    EventsTab(),
    CommunitiesTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: NavigationBar( 
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, 
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home), 
            label: 'Events', 
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Communities',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

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
    final appData = Provider.of<AppData>(context, listen: false);
    _searchController = TextEditingController(text: appData.searchText);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !appData.isLoadingMore && appData.hasMoreEvents) {
        appData.loadMoreEvents();
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
    final appData = Provider.of<AppData>(context, listen: false);

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
                  groupValue: appData.selectedCommunity,
                  onChanged: (Community? value) {
                    appData.setSelectedCommunity(value);
                    setState(() {
                      _selectedCategories = [];
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                ...appData.communities.map((Community community) {
                  return RadioListTile<Community?>(
                    title: Text(community.name),
                    value: community,
                    groupValue: appData.selectedCommunity,
                    onChanged: (Community? value) {
                      appData.setSelectedCommunity(value);
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
    final appData = Provider.of<AppData>(context, listen: false);
    final DateTime now = DateTime.now();
    final DateTime initialStart = appData.selectedStartDate ?? now;
    final DateTime initialEnd = appData.selectedEndDate ?? initialStart;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, now.month, now.day),
      lastDate: DateTime(now.year + 5, now.month, now.day),
      initialDateRange: appData.selectedStartDate != null && appData.selectedEndDate != null
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
      appData.setDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appData = Provider.of<AppData>(context);
    final appBarTextStyle = Theme.of(context).appBarTheme.titleTextStyle;

    final ChipThemeData chipTheme = Theme.of(context).chipTheme;
    final TextStyle? selectedChipTextStyle = chipTheme.secondaryLabelStyle;
    final TextStyle? unselectedChipTextStyle = chipTheme.labelStyle;

    List<Event> eventsToDisplay;

    if (appData.selectedCommunity != null) {
      eventsToDisplay = appData.selectedCommunity!.events
          .where((event) => event.location == appData.location)
          .toList();
      if (_selectedCategories.isNotEmpty) {
        eventsToDisplay = eventsToDisplay.where((event) => _selectedCategories.contains(event.category)).toList();
      }
    } else {
      eventsToDisplay = appData.events
          .where((event) => !event.isPrivate)
          .toList();
      if (_selectedCategories.isNotEmpty) {
        eventsToDisplay = eventsToDisplay.where((event) => _selectedCategories.contains(event.category)).toList();
      }
    }

    if (appData.searchText.isNotEmpty) {
      final searchTextLower = appData.searchText.toLowerCase();
      eventsToDisplay = eventsToDisplay.where((event) =>
          event.venue.toLowerCase().contains(searchTextLower) ||
          event.name.toLowerCase().contains(searchTextLower) ||
          event.artist.toLowerCase().contains(searchTextLower)).toList();
    }

    if (appData.selectedCommunity != null && appData.selectedStartDate != null && appData.selectedEndDate != null) {
      eventsToDisplay = eventsToDisplay.where((event) {
        if (event.date.isEmpty) return false;
        try {
          DateTime eventDate = DateFormat('yyyy-MM-dd').parse(event.date);
          DateTime startDateNormalized = DateTime(appData.selectedStartDate!.year, appData.selectedStartDate!.month, appData.selectedStartDate!.day);
          DateTime endDateBoundary = DateTime(appData.selectedEndDate!.year, appData.selectedEndDate!.month, appData.selectedEndDate!.day, 23, 59, 59);
          
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
                value: appData.location,
                items: appData.locations.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != appData.location) {
                    setState(() {
                      _selectedCategories = [];
                    });
                    Provider.of<AppData>(context, listen: false).setLocation(newValue);
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
                          suffixIcon: appData.searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    appData.setSearchText('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        ),
                        onChanged: appData.setSearchText,
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
                          color: (appData.selectedStartDate != null || appData.selectedEndDate != null)
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
              if (appData.selectedStartDate != null && appData.selectedEndDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
                  child: Chip(
                    label: Text(
                      () {
                        final DateFormat formatter = DateFormat('MMM d, yyyy');
                        bool isSameDay = appData.selectedStartDate!.year == appData.selectedEndDate!.year &&
                            appData.selectedStartDate!.month == appData.selectedEndDate!.month &&
                            appData.selectedStartDate!.day == appData.selectedEndDate!.day;
                        if (isSameDay) {
                          return 'Date: ${formatter.format(appData.selectedStartDate!)}';
                        } else {
                          return 'Range: ${formatter.format(appData.selectedStartDate!)} - ${formatter.format(appData.selectedEndDate!)}';
                        }
                      }(),
                    ),
                    onDeleted: () {
                      appData.clearDateFilter();
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
                      if (appData.eventCategories.isNotEmpty || (appData.selectedCommunity != null && appData.selectedCommunity!.events.any((e) => e.category.isNotEmpty)))
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
                        if (appData.selectedCommunity != null) {
                          final categories = appData.selectedCommunity!.events
                              .map((e) => e.category)
                              .where((c) => c.isNotEmpty)
                              .toSet()
                              .toList();
                          categories.sort();
                          return categories;
                        } else {
                          return appData.eventCategories;
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
                child: (appData.isLoadingMore && eventsToDisplay.isEmpty && appData.currentPage == 0)
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : eventsToDisplay.isEmpty
                        ? Center(
                            child: Text(
                            appData.isLoadingMore ? 'Loading...' : 'No events found for your criteria.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 4.0),
                            itemCount: eventsToDisplay.length + (appData.hasMoreEvents && appData.selectedCommunity == null && !appData.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < eventsToDisplay.length) {
                                return EventCard(event: eventsToDisplay[index]);
                              } else if (appData.hasMoreEvents && appData.selectedCommunity == null && !appData.isLoadingMore) {
                                return _buildLoadMoreIndicator(context);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
              ),
              if (appData.isLoadingMore && (eventsToDisplay.isNotEmpty || appData.currentPage > 0))
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
    final appData = Provider.of<AppData>(context, listen: false);
    if (appData.isLoadingMore || !appData.hasMoreEvents || appData.selectedCommunity != null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(child: Text("Scroll to load more...", style: Theme.of(context).textTheme.bodySmall)),
    );
  }
}

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
    final appData = Provider.of<AppData>(context, listen: false);
    if (appData.communities.isEmpty) {
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
                child: appData.communities.isEmpty
                  ? const Text("No communities created yet.")
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('Select communities for "${event.name}":', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'Inter')),
                        ),
                        ...appData.communities.map((community) => CheckboxListTile(
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
                    appData.addEventToCommunity(community, event);
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
    final appData = Provider.of<AppData>(context);

    List<Community> communitiesToDisplay = appData.communities;
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
                  suffixIcon: _communitySearchText.isNotEmpty ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _communitySearchController.clear();
                      _setCommunitySearchText('');
                    },
                  ) : null,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'Inter', color: Colors.grey[600]),
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
                  decoration: const InputDecoration(hintText: 'e.g., Leipzig Tech Meetup', labelText: 'Community Name*'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    if (Provider.of<AppData>(context, listen: false).communities.any((c) => c.name.toLowerCase() == value.toLowerCase())) {
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
                  decoration: const InputDecoration(hintText: 'What is this community about?', labelText: 'Description*'),
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
                  Provider.of<AppData>(context, listen: false).addCommunity(newCommunity);
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


class CommunityTile extends StatelessWidget {
  final Community community;

  const CommunityTile({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context, listen: false); 

    return Card( 
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text(
          community.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold), 
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
          icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.8)),
          tooltip: 'Delete Community',
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: Text('Confirm Delete', style: Theme.of(context).textTheme.headlineSmall),
                    content: Text('Are you sure you want to delete the community "${community.name}" and all its events? This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel')
                      ),
                      TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: (){
                            appData.deleteCommunity(community);
                            Navigator.of(ctx).pop(); 
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Community "${community.name}" deleted.')),
                            );
                          },
                          child: const Text('Delete')
                      ),
                    ],
                  );
                }
            );
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
    _eventLocation = Provider.of<AppData>(context, listen: false).location;
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
    return Consumer<AppData>(
        builder: (context, appData, child) {
          // Find the most up-to-date community instance from AppData
          final Community currentCommunity;
          try {
            currentCommunity = appData.communities.firstWhere(
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
    _eventLocation = Provider.of<AppData>(context, listen: false).location; 
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
              final appData = Provider.of<AppData>(context, listen: false); 
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
                          items: appData.locations.map((String value) {
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
                        Provider.of<AppData>(context, listen: false).addPrivateEventToCommunity(community, newEvent);
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

class EventInCommunityCard extends StatelessWidget {
  final Event event;
  final Community community; 

  const EventInCommunityCard({super.key, required this.event, required this.community});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context, listen: false); 
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
                            color: event.isPrivate ? colorScheme.secondary.withOpacity(0.8) : Colors.green.shade700, // Using secondary as it should be distinct.
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // This Selector listens to changes in the specific event within the community
                Selector<AppData, Event>(
                  selector: (_, appDataProvider) {
                    // Find the current community from the provider to ensure we have the latest version
                    final communityFromProvider = appDataProvider.communities.firstWhere(
                        (c) => c.name == community.name, 
                        orElse: () {
                            // This orElse should ideally not be hit if the CommunityDetailsPage handles missing communities.
                            // However, as a fallback, return the initial event.
                            debugPrint("EventInCommunityCard Selector: Community '${community.name}' not found in AppData. Using stale widget.event for like status.");
                            return community; // This is not ideal, but better than crashing.
                        });

                    // Then find the event within that community
                    return communityFromProvider.events.firstWhere(
                        (e) =>
                            e.name == event.name &&
                            e.date == event.date &&
                            e.venue == event.venue &&
                            e.isPrivate == event.isPrivate, 
                        orElse: () {
                            // Fallback: if event somehow not found (e.g., removed between builds)
                            debugPrint("EventInCommunityCard Selector: Event '${event.name}' not found in community '${communityFromProvider.name}'. Using widget.event for like status.");
                            return event; // Return original event state
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
                            final appDataForAction = Provider.of<AppData>(context, listen: false);
                            bool newLikedStatus = !currentEventState.isLiked;
                            appDataForAction.updateEventInCommunity(
                              community, // Pass the original community reference for AppData to find it
                              currentEventState, // Pass the event state that needs updating
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
                onPressed: () => _confirmRemoveEvent(context, appData, community, event),
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

  void _confirmRemoveEvent(BuildContext context, AppData appData, Community community, Event event) {
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
                  appData.removeEventFromCommunity(community, event);
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


class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with AutomaticKeepAliveClientMixin {
   @override
  bool get wantKeepAlive => true; 

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppData>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    final appData = Provider.of<AppData>(context); 

    // Update text controllers if profile in AppData changes from elsewhere
    // (though unlikely in this simple app structure for profile)
    if (_nameController.text != appData.profile.name) {
      _nameController.text = appData.profile.name;
       // Move cursor to end after programmatic text change
      _nameController.selection = TextSelection.fromPosition(TextPosition(offset: _nameController.text.length));
    }
    if (_bioController.text != appData.profile.bio) {
      _bioController.text = appData.profile.bio;
      _bioController.selection = TextSelection.fromPosition(TextPosition(offset: _bioController.text.length));
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
        title: const Text('Profile'), 
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView( 
              children: [
                const SizedBox(height: 20),
                Center( 
                  child: CircleAvatar(
                    radius: 60, 
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    child: Icon(Icons.person_rounded, size: 70, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your display name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                   textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us something about yourself',
                     prefixIcon: Icon(Icons.info_outline_rounded),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bio';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_rounded, size: 20),
                  label: const Text('Save Profile'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newProfile = Profile(
                        name: _nameController.text.trim(),
                        bio: _bioController.text.trim(),
                      );
                      if (newProfile.name != appData.profile.name || newProfile.bio != appData.profile.bio) {
                          appData.updateProfile(newProfile);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated!')),
                          );
                      } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No changes to save.')),
                          );
                      }
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
