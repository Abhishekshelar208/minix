import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/services/splash_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final SplashServices _splashServices = SplashServices();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Start animation and check login status
    _animationController.forward();
    _splashServices.checkLoginStatus(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive breakpoints
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;
    
    // Responsive dimensions
    final double logoSize = isMobile
        ? 120
        : isTablet
            ? 150
            : 180;
    
    final double iconSize = isMobile
        ? 60
        : isTablet
            ? 75
            : 90;
    
    final double titleFontSize = isMobile
        ? screenWidth * 0.08
        : isTablet
            ? 48
            : 64;
    
    final double taglineFontSize = isMobile
        ? screenWidth * 0.045
        : isTablet
            ? 20
            : 24;
    
    final double loadingTextFontSize = isMobile
        ? screenWidth * 0.035
        : isTablet
            ? 16
            : 18;
    
    final double verticalSpacing1 = isMobile
        ? screenHeight * 0.04
        : isTablet
            ? 40
            : 50;
    
    final double verticalSpacing2 = isMobile
        ? screenHeight * 0.02
        : isTablet
            ? 24
            : 30;
    
    final double verticalSpacing3 = isMobile
        ? screenHeight * 0.08
        : isTablet
            ? 60
            : 80;
    
    final double verticalSpacing4 = isMobile
        ? screenHeight * 0.03
        : isTablet
            ? 30
            : 40;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff2563eb), // Primary blue
              Color(0xff3b82f6), // Lighter blue
              Color(0xff1d4ed8), // Darker blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24.0 : 48.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App Icon/Logo Placeholder
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 30 : isTablet ? 35 : 40,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: isMobile ? 2 : 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            ),
                            
                            SizedBox(height: verticalSpacing1),
                            
                            // App Name
                            Text(
                              'Minix',
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: verticalSpacing2),
                            
                            // Tagline
                            Text(
                              "Your Complete Project Companion",
                              style: GoogleFonts.poppins(
                                fontSize: taglineFontSize,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: verticalSpacing3),
                            
                            // Loading indicator
                            SizedBox(
                              width: isMobile ? 40 : isTablet ? 50 : 60,
                              height: isMobile ? 40 : isTablet ? 50 : 60,
                              child: CircularProgressIndicator(
                                strokeWidth: isMobile ? 3 : 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: verticalSpacing4),
                            
                            // Loading text
                            Text(
                              "Setting up your workspace...",
                              style: GoogleFonts.poppins(
                                fontSize: loadingTextFontSize,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}