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
      name.hashCode ^ date.hashCode ^ venue.hashCode ^ isPrivate.hashCode;
}
