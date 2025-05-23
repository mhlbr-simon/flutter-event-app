// splash_screen.dart (or add to main.dart)
import 'dart:async';
import 'main.dart';
import 'package:flutter/material.dart';
// Import your main page and primary color if they are in different files
// Assuming HomePage is in main.dart and primaryColor is also defined there.
// If not, adjust imports accordingly.

// ---- COLORS (Copied from your main.dart for context, ensure consistency) ----
const Color primaryColor = Color(0xFF182139);
// ---- END COLORS ----

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Wait for a specified duration
    await Future.delayed(const Duration(milliseconds: 2500), () {}); // 2.5 seconds
    
    // Navigate to HomePage and replace the splash screen in the navigation stack
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const HomePage()), // Assuming HomePage is your main app screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Using your app's primary dark blue color
      body: Center(
        child: Column( // Using Column to easily center
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/looped_logo.png',
              // You might want to constrain the width or height if the image is too large
              // Example:
              // width: MediaQuery.of(context).size.width * 0.7, // 70% of screen width
              // Or a fixed width:
              // width: 250,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if the image fails to load
                return const Text(
                  'LOOPED', 
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}