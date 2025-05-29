import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventData extends ChangeNotifier {
  List<Event> events = [];
  List<String> eventCategories = [];
  String location = 'Leipzig';
  List<String> locations = [
    'Leipzig',
    'Berlin',
    'Dresden',
    'Hamburg',
    'München',
    'Köln',
    'Frankfurt am Main',
    'Stuttgart',
    'Düsseldorf',
    'Hannover',
  ];
  int eventsPerPage = 50;
  int currentPage = 0;
  bool isLoadingMore = false;
  bool hasMoreEvents = true;
  String searchText = '';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  final String _apiKey = 'FjmzhCsYGAorO6yhHcsllQ58elJiMB63'; // Dein API-Key

  Future<void> fetchEvents() async {
    if (isLoadingMore) return;

    isLoadingMore = true;
    notifyListeners();

    String apiUrl =
        'https://app.ticketmaster.com/discovery/v2/events.json?apikey=$_apiKey&city=$location&size=$eventsPerPage&page=$currentPage&sort=date,asc';

    if (selectedStartDate != null) {
      String start = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(selectedStartDate!.toUtc());
      apiUrl += '&startDateTime=$start';
    }

    if (selectedEndDate != null) {
      DateTime endOfDayUTC = DateTime.utc(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day, 23, 59, 59);
      String end = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(endOfDayUTC);
      apiUrl += '&endDateTime=$end';
    }

    final url = Uri.parse(apiUrl);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<Event> fetchedEvents = [];
        final List<String> fetchedCategories = [];

        if (data['_embedded'] != null && data['_embedded']['events'] != null) {
          for (var eventJson in data['_embedded']['events']) {
            final category = (eventJson['classifications'] as List?)?.first?['segment']?['name'] ?? 'Other';
            final venue = eventJson['_embedded']?['venues']?[0]?['name'] ?? 'Unknown venue';
            final address = eventJson['_embedded']?['venues']?[0]?['address']?['line1'] ?? 'No address';
            final startTime = eventJson['dates']?['start']?['localTime'] ?? 'No time';
            final artist = eventJson['name'] ?? 'Unknown Artist';
            String imageUrl = 'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';

            if (eventJson['images'] != null) {
              var suitable = (eventJson['images'] as List).firstWhere(
                (img) => img['ratio'] == '16_9' && (img['width'] ?? 0) > 500,
                orElse: () => (eventJson['images'] as List).first,
              );
              imageUrl = suitable['url'] ?? imageUrl;
            }

            fetchedEvents.add(Event(
              name: eventJson['name'] ?? 'Unknown',
              date: eventJson['dates']?['start']?['localDate'] ?? '',
              location: location,
              venue: venue,
              venueAddress: address,
              startTime: startTime,
              imageUrl: imageUrl,
              description: eventJson['info'] ?? eventJson['pleaseNote'] ?? 'No description available.',
              category: category,
              genre: (eventJson['classifications'] as List?)?.first?['genre']?['name'] ?? 'No genre',
              isPrivate: false,
              artist: artist,
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

          eventCategories = <String>{...eventCategories, ...fetchedCategories}.toList()..sort();
          hasMoreEvents = fetchedEvents.length == eventsPerPage;
        } else {
          if (currentPage == 0) events = [];
          hasMoreEvents = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (currentPage == 0) events = [];
      hasMoreEvents = false;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void loadMoreEvents() {
    if (!isLoadingMore && hasMoreEvents) {
      currentPage++;
      fetchEvents();
    }
  }

  void setLocation(String newLocation) {
    if (location != newLocation) {
      location = newLocation;
      currentPage = 0;
      events.clear();
      fetchEvents();
    }
  }

  void setDateFilter(DateTimeRange? range) {
    selectedStartDate = range?.start;
    selectedEndDate = range?.end;
    currentPage = 0;
    events.clear();
    fetchEvents();
  }

  void clearDateFilter() {
    setDateFilter(null);
  }

  void setSearchText(String text) {
    searchText = text;
    notifyListeners();
  }

  void addEvent(Event event) {
    events.add(event);
    notifyListeners();
  }
}
