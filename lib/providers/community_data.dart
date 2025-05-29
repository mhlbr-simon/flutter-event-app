import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../models/community.dart';

class CommunityData extends ChangeNotifier {
  List<Community> communities = [];
  Community? selectedCommunity;

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

  void setSelectedCommunity(Community? community) {
    selectedCommunity = community;
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

  void updateEventInCommunity(Community community, Event eventToUpdate, {required bool newLikedStatus}) {
    final communityInList = communities.firstWhere((c) => c.name == community.name, orElse: () => community);
    final index = communityInList.events.indexWhere((e) =>
        e.name == eventToUpdate.name &&
        e.date == eventToUpdate.date &&
        e.venue == eventToUpdate.venue &&
        e.isPrivate == eventToUpdate.isPrivate);

    if (index != -1) {
      final oldEvent = communityInList.events[index];
      final newLikes = newLikedStatus
          ? oldEvent.likes + 1
          : (oldEvent.likes > 0 ? oldEvent.likes - 1 : 0);

      communityInList.events[index] = oldEvent.copyWith(
        isLiked: newLikedStatus,
        likes: newLikes,
      );
      notifyListeners();
    }
  }

  void removeEventFromCommunity(Community community, Event event) {
    final c = communities.firstWhere((c) => c.name == community.name, orElse: () => community);
    int initial = c.events.length;
    c.events.removeWhere((e) =>
        e.name == event.name &&
        e.date == event.date &&
        e.venue == event.venue &&
        e.isPrivate == event.isPrivate);
    if (c.events.length < initial) notifyListeners();
  }
}
