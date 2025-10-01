import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const IntroScreen({super.key, required this.onComplete});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotationController);
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Reset and replay animations
    _fadeController.reset();
    _scaleController.reset();
    _slideController.reset();
    
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipToEnd() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(_currentPage),
              ),
            ),
          ),
          
          // Floating background shapes
          ...List.generate(
            5,
            (index) => _buildFloatingShape(index, size),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with skip button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Text(
                        'Minix',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      
                      // Skip button
                      if (_currentPage < 2)
                        TextButton(
                          onPressed: _skipToEnd,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.9),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Page view with slides
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildSlide1(),
                      _buildSlide2(),
                      _buildSlide3(),
                    ],
                  ),
                ),
                
                // Bottom navigation
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 32 : 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: _currentPage == index
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Next/Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _getButtonTextColor(_currentPage),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == 2 ? 'Get Started' : 'Continue',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == 2 ? Icons.rocket_launch : Icons.arrow_forward,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide1() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        size: 60,
                        color: Color(0xfff59e0b),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Text(
                  'Welcome to Minix',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Your AI-powered companion for academic projects',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Feature pills
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeaturePill('AI-Powered', Icons.auto_awesome),
                    _buildFeaturePill('Step-by-Step', Icons.timeline),
                    _buildFeaturePill('Team Collaboration', Icons.group),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide2() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated process flow
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timeline_rounded,
                          size: 50,
                          color: Color(0xff059669),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    '9-Step Process',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'From topic selection to viva preparation,\nwe guide you every step of the way',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Step cards
                  Column(
                    children: [
                      _buildStepCard('Topic Selection', 'AI finds perfect problems', Icons.search),
                      const SizedBox(height: 12),
                      _buildStepCard('Smart Roadmap', 'Automated task breakdown', Icons.route),
                      const SizedBox(height: 12),
                      _buildStepCard('Documentation', 'Professional reports', Icons.description),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide3() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated collaboration icon - Fixed stacking
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating background
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Center icon
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.rocket_launch_rounded,
                                size: 50,
                                color: Color(0xff7c3aed),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Ready to Excel?',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Join thousands of students already succeeding\nwith Minix',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Benefits list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBenefitItem('Save 20+ hours per project'),
                      const SizedBox(height: 12),
                      _buildBenefitItem('Professional documentation'),
                      const SizedBox(height: 12),
                      _buildBenefitItem('Ace your viva with confidence'),
                      const SizedBox(height: 12),
                      _buildBenefitItem('Collaborate with your team'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xff059669), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xff7c3aed),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingShape(int index, Size size) {
    final random = math.Random(index);
    final top = random.nextDouble() * size.height;
    final left = random.nextDouble() * size.width;
    final shapeSize = 50.0 + random.nextDouble() * 100;
    
    return Positioned(
      top: top,
      left: left,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              math.sin(_rotationAnimation.value + index) * 20,
              math.cos(_rotationAnimation.value + index) * 20,
            ),
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: shapeSize,
                height: shapeSize,
                decoration: BoxDecoration(
                  shape: index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: index % 2 != 0 ? BorderRadius.circular(20) : null,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Color> _getGradientColors(int page) {
    switch (page) {
      case 0:
        return [const Color(0xff2563eb), const Color(0xff3b82f6), const Color(0xff60a5fa)];
      case 1:
        return [const Color(0xff059669), const Color(0xff10b981), const Color(0xff34d399)];
      case 2:
        return [const Color(0xff7c3aed), const Color(0xff8b5cf6), const Color(0xffa78bfa)];
      default:
        return [const Color(0xff2563eb), const Color(0xff3b82f6), const Color(0xff60a5fa)];
    }
  }

  Color _getButtonTextColor(int page) {
    switch (page) {
      case 0:
        return const Color(0xff2563eb);
      case 1:
        return const Color(0xff059669);
      case 2:
        return const Color(0xff7c3aed);
      default:
        return const Color(0xff2563eb);
    }
  }
}
