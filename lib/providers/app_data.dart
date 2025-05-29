import 'package:flutter/foundation.dart';
import 'event_data.dart';
import 'community_data.dart';
import 'profile_data.dart';

class AppData extends ChangeNotifier {
  final EventData eventData = EventData();
  final CommunityData communityData = CommunityData();
  final ProfileData profileData = ProfileData();

  AppData() {
    eventData.addListener(notifyListeners);
    communityData.addListener(notifyListeners);
    profileData.addListener(notifyListeners);
  }

  @override
  void dispose() {
    eventData.removeListener(notifyListeners);
    communityData.removeListener(notifyListeners);
    profileData.removeListener(notifyListeners);
    super.dispose();
  }
}
