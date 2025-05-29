import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/event_data.dart';
import 'providers/community_data.dart';
import 'providers/profile_data.dart';
import 'my_app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventData()),
        ChangeNotifierProvider(create: (_) => CommunityData()),
        ChangeNotifierProvider(create: (_) => ProfileData()),
      ],
      child: const MyApp(),
    ),
  );
}
