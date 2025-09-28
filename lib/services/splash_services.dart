import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minix/pages/home_screen.dart';
import 'package:minix/pages/login_signup_screen.dart';

class SplashServices {
  /// This method checks the login status of the user and navigates accordingly.
  Future<void> checkLoginStatus(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      // Delay to show splash screen for 2.5 seconds
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!context.mounted) return;

      if (user != null) {
        // User is logged in, redirect to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // User is not logged in, redirect to LoginSignupScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
        );
      }
    } catch (e) {
      print('Error checking login status: $e');
      
      if (!context.mounted) return;
      
      // On error, navigate to login screen as fallback
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
    }
  }
}