import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:minix/pages/splash_screen.dart';
import 'package:minix/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minix',
      debugShowCheckedModeBanner: false,
      // Light Theme Only
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xfff8f9fa),
        primaryColor: const Color(0xff2563eb), // Modern blue
        colorScheme: const ColorScheme.light(
          primary: Color(0xff2563eb),
          secondary: Color(0xff059669), // Green for success
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xff1f2937),
          error: Color(0xffef4444),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff8f9fa),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xff1f2937)),
          titleTextStyle: TextStyle(
            color: Color(0xff2563eb),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2563eb),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffe5e7eb)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffe5e7eb)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
          ),
        ),
      ),
      // Force light theme only
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
