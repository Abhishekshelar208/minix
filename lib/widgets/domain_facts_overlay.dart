import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/data/domain_facts.dart';

/// Full-screen overlay that displays rotating domain-specific facts
/// while AI generates topic suggestions in the background
class DomainFactsOverlay extends StatefulWidget {
  final String domain;
  final VoidCallback? onComplete;

  const DomainFactsOverlay({
    super.key,
    required this.domain,
    this.onComplete,
  });

  @override
  State<DomainFactsOverlay> createState() => _DomainFactsOverlayState();

  /// Show the facts overlay as a dialog
  static Future<void> show(BuildContext context, String domain) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Cannot tap outside to close
      barrierColor: Colors.black87,
      builder: (context) => DomainFactsOverlay(domain: domain),
    );
  }

  /// Close the facts overlay
  static void close(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _DomainFactsOverlayState extends State<DomainFactsOverlay> {
  late List<FactItem> _facts;
  int _currentFactIndex = 0;
  Timer? _rotationTimer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _facts = DomainFacts.getFactsForDomain(widget.domain);
    _pageController = PageController();
    
    // Setup auto-rotation timer (4 seconds per fact)
    _startRotationTimer();
  }

  void _startRotationTimer() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _showNextFact();
      }
    });
  }

  void _showNextFact() async {
    if (!mounted) return;
    
    final nextIndex = (_currentFactIndex + 1) % _facts.length;
    
    // Animate to next page
    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff1e3a8a), // Deep blue
              Color(0xff2563eb), // Blue
              Color(0xff3b82f6), // Lighter blue
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI is Crafting Your Topics',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'This takes a moment—enjoy these insights meanwhile!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Animated progress indicator
              SizedBox(
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Swipe instruction
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Swipe left or right to explore more',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Facts container with PageView for swiping
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentFactIndex = index;
                    });
                  },
                  itemCount: _facts.length,
                  itemBuilder: (context, index) {
                    final fact = _facts[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header (context-aware)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '💡',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DomainFacts.facts.containsKey(widget.domain) 
                                    ? 'Did You Know?' 
                                    : 'Pro Tips',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff2563eb),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Fact icon (large)
                          Text(
                            fact.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Main fact text
                          Text(
                            fact.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1f2937),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Subtext
                          Text(
                            fact.subtext,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xff6b7280),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _facts.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentFactIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentFactIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Domain label
              Text(
                '${widget.domain} Domain',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
