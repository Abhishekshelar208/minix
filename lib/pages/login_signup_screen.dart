import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:minix/pages/home_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();
  int currentPage = 0;
  bool _isLoading = false;
  
  // Profile form state
  bool _showProfileForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedBranch;
  String? _selectedYear;
  
  // Dropdown options
  final List<String> _branches = ['CO', 'IT', 'AIDS', 'CE'];
  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  void _showProfileFormDialog() {
    setState(() {
      _showProfileForm = true;
    });
  }
  
  void _hideProfileForm() {
    setState(() {
      _showProfileForm = false;
    });
  }
  
  Future<void> _handleProfileSubmit() async {
    print('🔄 Profile submit started');
    print('📝 Name: ${_nameController.text.trim()}');
    print('🏫 Branch: $_selectedBranch');
    print('📅 Year: $_selectedYear');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    
    if (_selectedBranch == null || _selectedYear == null) {
      print('❌ Missing branch or year');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both branch and year')),
      );
      return;
    }
    
    print('✅ Profile form valid, proceeding with Google sign-in');
    // Now proceed with Google sign-in
    await _handleGoogleSignIn();
  }
  
  Future<void> _handleGoogleSignIn() async {
    try {
      print('🚀 Starting Google sign-in');
      setState(() => _isLoading = true);

      UserCredential userCredential;

      if (kIsWeb) {
        print('🌍 Using web Google sign-in');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        print('📱 Using mobile Google sign-in');
        // Use FirebaseAuth's native provider flow to avoid google_sign_in Pigeon issues
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithProvider(googleProvider);
      }

      User? user = userCredential.user;
      print('👤 Google user: ${user?.email}');
      
      if (user != null) {
        print('💾 Saving user profile to database...');
        await _saveUserWithProfile(user);
        
        if (!mounted) return;
        print('🏠 Navigating to home screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        print('❌ Google sign-in returned null user');
      }
    } catch (e) {
      print('❌ Google sign-in error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserWithProfile(User user) async {
    try {
      print('💾 Starting database save process');
      print('📧 User email: ${user.email}');
      print('📝 Form data - Name: ${_nameController.text.trim()}, Branch: $_selectedBranch, Year: $_selectedYear');
      
      final dbRef = FirebaseDatabase.instance.ref().child("MiniProjectHelperUsers");
      final email = user.email ?? "";
      
      if (email.isEmpty) {
        print('❌ Email is empty, cannot save user');
        return;
      }

      print('🔍 Checking if user already exists...');
      final snapshot = await dbRef.orderByChild("EmailID").equalTo(email).once();
      print('📊 Database query result: ${snapshot.snapshot.value}');

      if (snapshot.snapshot.value == null) {
        print('🆕 User is new, creating database entry...');
        final newEntryRef = dbRef.push();
        
        final userData = {
          "Name": _nameController.text.trim(),
          "EmailID": email,
          "PhotoURL": user.photoURL ?? "",
          "Provider": "google",
          "Branch": _selectedBranch!,
          "Year": _selectedYear!,
          "JoinDate": DateTime.now().millisecondsSinceEpoch,
        };
        
        print('📦 Saving user data: $userData');
        await newEntryRef.set(userData);
        print('✅ User successfully saved to database!');
        
        // Show success message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('ℹ️ User already exists in database');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('👤 Welcome back!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving to database: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Database error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextPage() {
    if (currentPage < 2) {
      setState(() => currentPage++);
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Widget> _buildSlides(double screenWidth, double screenHeight) {
    return [
      _introSlide(
        screenWidth,
        screenHeight,
        "Welcome to Minix",
        "Your complete companion from idea selection to viva preparation. Never struggle with academic projects again!",
        Icons.lightbulb_outline,
        const Color(0xfff59e0b),
      ),
      _introSlide(
        screenWidth,
        screenHeight,
        "Structured Project Workflow",
        "Follow our 9-step process: Topic Selection → Roadmap → Code Generation → Documentation → Viva Prep.",
        Icons.timeline_outlined,
        const Color(0xff059669),
      ),
      _introSlide(
        screenWidth,
        screenHeight,
        "Learn While Building",
        "Get step-by-step code guidance, real-world problem solutions, and team collaboration tools all in one place.",
        Icons.school_outlined,
        const Color(0xff7c3aed),
      ),
    ];
  }

  Widget _introSlide(double screenWidth, double screenHeight, String title, String subtitle, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 60,
              color: iconColor,
            ),
          ),
          
          SizedBox(height: screenHeight * 0.05),
          
          // Title
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.07,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: screenHeight * 0.03),
          
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              color: const Color(0xff6b7280),
              height: 1.5,
            ),
          ),
          
          SizedBox(height: screenHeight * 0.08),
          
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentPage == index 
                    ? const Color(0xff2563eb) 
                    : const Color(0xffe5e7eb),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          SizedBox(height: screenHeight * 0.05),
          
          // Button
          if (currentPage == 2)
            ElevatedButton(
              onPressed: _showProfileFormDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                "Get Started",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    IconButton(
                      onPressed: _hideProfileForm,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  'We need a few details to personalize your experience',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff6b7280),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Name field
                Text(
                  'Full Name *',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Branch dropdown
                Text(
                  'Branch *',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  hint: const Text('Select your branch'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch,
                      child: Text(branch),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBranch = value;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Year dropdown
                Text(
                  'Academic Year *',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  hint: const Text('Select your year'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleProfileSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue with Google',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xfff8f9fa),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildSlides(screenWidth, screenHeight),
            ),
          ),
        ),

        // Profile Form Overlay
        if (_showProfileForm)
          _buildProfileForm(),

        // Loading Overlay
        if (_isLoading && !_showProfileForm)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff2563eb)),
              ),
            ),
          ),
      ],
    );
  }
}