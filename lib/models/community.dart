import 'event.dart';  // importiere Event, weil Community Events hält

class Community {
  String name;
  String description;
  List<Event> events;

  Community({
    required this.name,
    required this.description,
    List<Event>? initialEvents,
  }) : events = initialEvents ?? [];
}
