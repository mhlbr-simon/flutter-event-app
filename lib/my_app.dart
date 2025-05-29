import 'package:flutter/material.dart';
import 'colors.dart';
import 'screens/splash_screen.dart';

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
