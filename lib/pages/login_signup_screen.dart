import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/pages/home_screen.dart';
import 'package:minix/pages/intro_screen.dart';
import 'package:minix/utils/theme_helper.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _showIntro = true;
  
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


  void _completeIntro() {
    setState(() {
      _showIntro = false;
    });
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
    debugPrint('🔄 Profile submit started');
    debugPrint('📝 Name: ${_nameController.text.trim()}');
    debugPrint('🏫 Branch: $_selectedBranch');
    debugPrint('📅 Year: $_selectedYear');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }
    
    if (_selectedBranch == null || _selectedYear == null) {
      debugPrint('❌ Missing branch or year');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both branch and year')),
      );
      return;
    }
    
    debugPrint('✅ Profile form valid, proceeding with Google sign-in');
    // Now proceed with Google sign-in
    await _handleGoogleSignIn();
  }
  
  Future<void> _handleGoogleSignIn() async {
    try {
      debugPrint('🚀 Starting Google sign-in');
      setState(() => _isLoading = true);

      UserCredential userCredential;

      if (kIsWeb) {
        debugPrint('🌍 Using web Google sign-in');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        debugPrint('📱 Using mobile Google sign-in');
        // Use FirebaseAuth's native provider flow to avoid google_sign_in Pigeon issues
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithProvider(googleProvider);
      }

      User? user = userCredential.user;
      debugPrint('👤 Google user: ${user?.email}');
      
      if (user != null) {
        debugPrint('💾 Saving user profile to database...');
        await _saveUserWithProfile(user);
        
        if (!mounted) return;
        
        // Hide the profile form before navigation
        setState(() {
          _showProfileForm = false;
          _isLoading = false;
        });
        
        debugPrint('🏠 Navigating to home screen');
        // Use pushAndRemoveUntil to ensure user can't go back to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        debugPrint('❌ Google sign-in returned null user');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign-in failed: No user information received'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');
      if (!mounted) return;
      
      // Hide profile form on error
      setState(() {
        _showProfileForm = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserWithProfile(User user) async {
    try {
      debugPrint('💾 Starting database save process');
      debugPrint('📧 User email: ${user.email}');
      debugPrint('📝 Form data - Name: ${_nameController.text.trim()}, Branch: $_selectedBranch, Year: $_selectedYear');
      
      final dbRef = FirebaseDatabase.instance.ref().child("MiniProjectHelperUsers");
      final email = user.email ?? "";
      
      if (email.isEmpty) {
        debugPrint('❌ Email is empty, cannot save user');
        throw Exception('Email is required for profile creation');
      }

      debugPrint('🔍 Checking if user already exists...');
      final snapshot = await dbRef.orderByChild("EmailID").equalTo(email).once();
      debugPrint('📊 Database query result: ${snapshot.snapshot.value}');

      if (snapshot.snapshot.value == null) {
        debugPrint('🆕 User is new, creating database entry...');
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
        
        debugPrint('📦 Saving user data: $userData');
        await newEntryRef.set(userData);
        debugPrint('✅ User successfully saved to database!');
        
        // Also update Firebase Auth displayName
        try {
          await user.updateDisplayName(_nameController.text.trim());
          await user.reload();
          debugPrint('✅ Display name updated in Firebase Auth');
        } catch (e) {
          debugPrint('⚠️ Could not update display name: $e');
        }
        
        debugPrint('✅ Profile setup complete, ready to navigate');
      } else {
        debugPrint('ℹ️ User already exists in database - Welcome back!');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving to database: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Re-throw the error so it can be handled by the caller
      rethrow;
    }
  }


  Widget _buildProfileForm() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
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
    // Show modern intro screen first
    if (_showIntro) {
      return IntroScreen(
        onComplete: _completeIntro,
      );
    }

    // Then show login/profile form
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xfff8f9fa),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xff2563eb).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        size: 80,
                        color: Color(0xff2563eb),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Welcome text
                    Text(
                      'Welcome to Minix',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to start your academic project journey',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xff6b7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _showProfileFormDialog,
                        icon: const Icon(Icons.login),
                        label: Text(
                          'Get Started',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563eb),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Profile Form Overlay
        if (_showProfileForm)
          _buildProfileForm(),

        // Loading Overlay
        if (_isLoading && !_showProfileForm)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
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