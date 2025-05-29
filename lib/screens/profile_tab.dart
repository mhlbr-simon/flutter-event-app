import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_data.dart'; 
import '../models/profile.dart';
import '../colors.dart'; 


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
    final profile = Provider.of<ProfileData>(context, listen: false).profile;
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
    final profileData = Provider.of<ProfileData>(context); 

    // Update text controllers if profile in AppData changes from elsewhere
    // (though unlikely in this simple app structure for profile)
    if (_nameController.text != profileData.profile.name) {
      _nameController.text = profileData.profile.name;
       // Move cursor to end after programmatic text change
      _nameController.selection = TextSelection.fromPosition(TextPosition(offset: _nameController.text.length));
    }
    if (_bioController.text != profileData.profile.bio) {
      _bioController.text = profileData.profile.bio;
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
                      if (newProfile.name != profileData.profile.name || newProfile.bio != profileData.profile.bio) {
                          profileData.updateProfile(newProfile);
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
