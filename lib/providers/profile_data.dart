import 'package:flutter/foundation.dart';
import '../models/profile.dart';

class ProfileData extends ChangeNotifier {
  Profile profile = Profile(name: 'New User', bio: 'Write something about yourself.');

  void updateProfile(Profile newProfile) {
    profile = newProfile;
    notifyListeners();
  }
}
