import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/pages/splash_screen.dart';
import 'package:minix/pages/project_space_creation_page.dart';
import 'package:minix/pages/topic_selection_page.dart';
import 'package:minix/pages/project_name_suggestions_page.dart';
import 'package:minix/pages/project_roadmap_page.dart';
import 'package:minix/pages/project_steps_page.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/models/project_roadmap.dart';
import 'package:minix/models/task.dart';
import 'package:minix/models/problem.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProjectService _projectService = ProjectService();
  
  List<ProjectSpaceSummary> _projectSpaces = [];
  ProjectRoadmap? _currentRoadmap;
  Map<String, int> _projectStats = {};
  bool _isLoadingData = true;
  bool _isUpdatingTask = false;
  Timer? _refreshTimer;
  
  // Bottom navigation
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHomeData();
    
    // Also schedule a refresh after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAfterDelay();
    });
    
    // Auto-refresh disabled to prevent unwanted page reloads
    // Users can manually refresh using pull-to-refresh or refresh buttons
  }
  
  Widget _buildProfileHeaderCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2563eb), Color(0xff3b82f6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture and Basic Info
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: user?.photoURL != null
                      ? Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(user.displayName);
                          },
                        )
                      : _buildDefaultAvatar(user?.displayName),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Student',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'No email',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Account',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
          const SizedBox(height: 20),
          // Join Date Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Joined ${_formatJoinDate(user?.metadata.creationTime)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff059669),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultAvatar(String? name) {
    final initial = (name?.isNotEmpty == true) ? name!.substring(0, 1).toUpperCase() : 'S';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xff2563eb),
          ),
        ),
      ),
    );
  }
  
  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Recently';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  Widget _buildAcademicInfoCard() {
    // TODO: Fetch user's academic info from profile data stored during signup
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff7c3aed).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  size: 24,
                  color: Color(0xff7c3aed),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    Text(
                      'Your educational details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.business, 'Branch', 'Computer Engineering', const Color(0xff7c3aed)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_view_day, 'Academic Year', 'Second Year (SE)', const Color(0xff059669)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.trending_up, 'Skill Level', 'Intermediate', const Color(0xfff59e0b)),
        ],
      ),
    );
  }
  
  Widget _buildProfileStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  size: 24,
                  color: Color(0xff059669),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Statistics',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    Text(
                      'Your project achievements',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Projects',
                  '${_projectStats['totalProjects'] ?? 0}',
                  Icons.folder,
                  const Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  '${_projectStats['completedProjects'] ?? 0}',
                  Icons.check_circle,
                  const Color(0xff059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'In Progress',
                  '${_projectStats['inProgress'] ?? 0}',
                  Icons.schedule,
                  const Color(0xfff59e0b),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff6b7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  size: 24,
                  color: Color(0xff6b7280),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    Text(
                      'Manage your account preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsItem(
            Icons.notifications_outlined,
            'Notifications',
            'Manage notification preferences',
            () => _showComingSoon('Notifications'),
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            Icons.security_outlined,
            'Privacy & Security',
            'Account security settings',
            () => _showComingSoon('Privacy & Security'),
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            Icons.logout,
            'Sign Out',
            'Logout from your account',
            _handleSignOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff2563eb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 24,
                  color: Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Minix',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    Text(
                      'App information and support',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.apps, 'App Version', '1.0.0', const Color(0xff2563eb)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.developer_mode, 'Build', 'Debug Build', const Color(0xff6b7280)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.support, 'Support', 'help@minix.app', const Color(0xff059669)),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xff6b7280),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1f2937),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xff6b7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff8f9fa),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? const Color(0xffef4444) : const Color(0xff6b7280),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xffef4444) : const Color(0xff1f2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xff6b7280),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xff2563eb),
      ),
    );
  }
  
  void _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Sign Out",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1f2937),
          ),
        ),
        content: Text(
          "Are you sure you want to sign out of your account?",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xff6b7280),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xff6b7280),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffef4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Sign Out",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      _loadHomeData();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadHomeData();
      }
    });
  }

  // Add a method to force refresh after a delay (for Firebase consistency)
  Future<void> _refreshAfterDelay() async {
    print('⏳ Scheduling data refresh after delay...');
    await Future.delayed(const Duration(milliseconds: 1000)); // Give Firebase time to sync
    if (mounted) {
      print('🔄 Starting delayed data refresh...');
      await _loadHomeData();
    }
  }

  // Public method to manually refresh data (can be called from other screens)
  Future<void> forceRefresh() async {
    print('💪 Force refresh requested');
    await _loadHomeData();
  }
  
  // Refresh data while staying on current tab (for Projects tab refresh button)
  Future<void> _refreshProjectsData() async {
    print('📁 Refreshing projects data without navigation');
    await _loadHomeData();
    // Ensure we stay on the current tab after refresh
    if (_currentIndex != 1) {
      setState(() {
        _currentIndex = 1;
      });
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Bottom navigation handler
  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  // Build different pages for bottom nav
  Widget _buildHomePage() {
    User? user = _auth.currentUser;
    final userName = user?.displayName?.split(' ')[0] ?? 'Student';
    
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(userName),
            
            const SizedBox(height: 24),
            
            // Quick Stats Dashboard
            _buildQuickStatsCards(),
            
            const SizedBox(height: 24),
            
            // Recent Activity (if any projects exist)
            if (_projectSpaces.isNotEmpty) ...[
              _buildRecentActivitySection(),
              const SizedBox(height: 24),
            ],
            
            // How to Use App Guide
            _buildHowToUseSection(),
            
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }
  
  Widget _buildProjectsPage() {
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff2563eb).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    size: 24,
                    color: Color(0xff2563eb),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Projects',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      Text(
                        'Manage your project workspaces',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Create New Project Section (always visible)
            _buildCreateNewProjectCard(),
            
            const SizedBox(height: 24),
            
            // Project Spaces Section
            if (_projectSpaces.isEmpty)
              _buildNoProjectsYet()
            else
              _buildAllProjectSpaces(),
            
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }
  
  Widget _buildCreateNewProjectCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2563eb), Color(0xff3b82f6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_box_outlined,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start New Project',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a workspace and get AI-powered guidance',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectSpaceCreationPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff2563eb),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Project Workspace',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoProjectsYet() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xfff8f9fa),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Projects Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project workspace above and start your journey with AI-powered project development!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAllProjectSpaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Projects (${_projectSpaces.length})',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            TextButton.icon(
              onPressed: _refreshProjectsData,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _projectSpaces.length,
          itemBuilder: (context, index) {
            final space = _projectSpaces[index];
            return _buildProjectSpaceCard(space);
          },
        ),
      ],
    );
  }
  
  Widget _buildTeamsPage() {
    return const Center(
      child: Text(
        'Teams Page\nComing Soon',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildProfilePage() {
    User? user = _auth.currentUser;
    
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            _buildProfileHeaderCard(user),
            
            const SizedBox(height: 24),
            
            // Academic Info Card
            _buildAcademicInfoCard(),
            
            const SizedBox(height: 24),
            
            // Project Statistics Card
            _buildProfileStatsCard(),
            
            const SizedBox(height: 24),
            
            // Account Settings Card
            _buildAccountSettingsCard(),
            
            const SizedBox(height: 24),
            
            // App Info Card
            _buildAppInfoCard(),
            
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff2563eb),
            Color(0xff3b82f6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to build something amazing today?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            '${_projectStats['totalProjects'] ?? 0}',
            Icons.folder_outlined,
            const Color(0xff059669),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '${_projectStats['completedProjects'] ?? 0}',
            Icons.check_circle_outline,
            const Color(0xff2563eb),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            '${_projectStats['inProgress'] ?? 0}',
            Icons.schedule_outlined,
            const Color(0xfff59e0b),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xff6b7280),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentActivitySection() {
    final recentSpaces = _projectSpaces.take(2).toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  size: 24,
                  color: Color(0xff059669),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Projects',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your latest project activities',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Switch to Projects tab
                  setState(() {
                    _currentIndex = 1;
                  });
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentSpaces.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xfff8f9fa),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No projects yet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff6b7280),
                          ),
                        ),
                        Text(
                          'Go to Projects tab to get started',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xff9ca3af),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentSpaces.map((space) => _buildRecentProjectItem(space)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildRecentProjectItem(ProjectSpaceSummary space) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStepColor(space.currentStep).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStepIcon(space.currentStep),
              size: 20,
              color: _getStepColor(space.currentStep),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.teamName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStepName(space.currentStep),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStepColor(space.currentStep).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Step ${space.currentStep}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStepColor(space.currentStep),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHowToUseSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 24,
                  color: Color(0xff059669),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'How Minix Works',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHowToStep(1, 'Create Workspace', 'Set up your team and project basics'),
          _buildHowToStep(2, 'Choose Topic', 'AI suggests real-world problems for your year'),
          _buildHowToStep(3, 'Get Roadmap', 'Automated timeline with tasks and deadlines'),
          _buildHowToStep(4, 'Build Together', 'Code generation and team collaboration'),
          _buildHowToStep(5, 'Present & Excel', 'Auto-generated docs and viva preparation'),
        ],
      ),
    );
  }
  
  Widget _buildHowToStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xff2563eb),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$step',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _projectSpaces = [];
          _currentRoadmap = null;
          _projectStats = {'totalProjects': 0, 'completedProjects': 0, 'inProgress': 0};
          _isLoadingData = false;
        });
        return;
      }

      // Load all data in parallel with graceful error handling
      List<ProjectSpaceSummary> projectSpaces = [];
      ProjectRoadmap? currentRoadmap;
      Map<String, int> projectStats = {'totalProjects': 0, 'completedProjects': 0, 'inProgress': 0};
      
      try {
        print('🔄 Loading project spaces...');
        projectSpaces = await _projectService.getUserProjectSpaces();
        print('✅ Loaded ${projectSpaces.length} project spaces');
      } catch (e) {
        // Firebase index error or no data - this is normal for new users
        print('Info: No project spaces found (likely new user): $e');
        projectSpaces = [];
      }
      
      try {
        print('🔄 Loading current roadmap...');
        currentRoadmap = await _projectService.getCurrentRoadmap();
        if (currentRoadmap != null) {
          print('✅ Loaded roadmap with ${currentRoadmap.tasks.length} tasks');
        } else {
          print('ℹ️ No current roadmap found');
        }
      } catch (e) {
        // No roadmap yet - normal for new users
        print('Info: No current roadmap found: $e');
        currentRoadmap = null;
      }
      
      try {
        print('🔄 Loading project stats...');
        projectStats = await _projectService.getProjectStats();
        print('✅ Loaded stats: $projectStats');
      } catch (e) {
        // No stats yet - normal for new users
        print('Info: No project stats found: $e');
        projectStats = {'totalProjects': 0, 'completedProjects': 0, 'inProgress': 0};
      }

      setState(() {
        _projectSpaces = projectSpaces;
        _currentRoadmap = currentRoadmap;
        _projectStats = projectStats;
        _isLoadingData = false;
      });
    } catch (e) {
      // Only show errors for unexpected issues, not missing data
      print('❌ Unexpected error loading home data: $e');
      setState(() {
        _projectSpaces = [];
        _currentRoadmap = null;
        _projectStats = {'totalProjects': 0, 'completedProjects': 0, 'inProgress': 0};
        _isLoadingData = false;
      });
      
      // Only show error to user if it's a real connectivity/auth issue
      if (mounted && !e.toString().contains('index-not-defined') && !e.toString().contains('permission-denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Connection issue. Please check your internet.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadHomeData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (_currentRoadmap == null) return;
    
    setState(() => _isUpdatingTask = true);
    
    try {
      final spacesWithRoadmap = _projectSpaces.where((space) => space.roadmapId != null).toList();
      if (spacesWithRoadmap.isEmpty) return;
      final activeSpace = spacesWithRoadmap.first;
      
      await _projectService.updateTaskCompletion(
        roadmapId: activeSpace.roadmapId!,
        taskId: task.id,
        isCompleted: !task.isCompleted,
        completedBy: _auth.currentUser?.displayName ?? 'User',
      );
      
      // Update local state
      final updatedTasks = _currentRoadmap!.tasks.map((t) {
        if (t.id == task.id) {
          return t.copyWith(
            isCompleted: !t.isCompleted,
            completedAt: !t.isCompleted ? DateTime.now() : null,
            completedBy: !t.isCompleted ? (_auth.currentUser?.displayName ?? 'User') : null,
          );
        }
        return t;
      }).toList();
      
      setState(() {
        _currentRoadmap = _currentRoadmap!.copyWith(tasks: updatedTasks);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(task.isCompleted 
              ? '✅ Task "${task.title}" marked as incomplete' 
              : '✅ Task "${task.title}" completed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to update task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdatingTask = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        backgroundColor: const Color(0xfff8f9fa),
        appBar: AppBar(
          backgroundColor: const Color(0xfff8f9fa),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Minix",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff2563eb),
                ),
              ),
              if (user != null)
                Text(
                  "Welcome back, ${user.displayName?.split(' ')[0] ?? 'Student'}!",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff6b7280),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xff6b7280)),
              onPressed: () {
                // TODO: Show notifications
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle, color: Color(0xff2563eb), size: 28),
              onSelected: (value) async {
                if (value == 'logout') {
                  bool? confirmLogout = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        "Confirm Logout",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      content: Text(
                        "Are you sure you want to logout?",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff6b7280),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffef4444),
                          ),
                          child: Text(
                            "Logout",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (confirmLogout == true) {
                    await _auth.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: Color(0xff6b7280)),
                      const SizedBox(width: 8),
                      Text(
                        'Profile',
                        style: GoogleFonts.poppins(color: const Color(0xff1f2937)),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outlined, color: Color(0xff6b7280)),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: GoogleFonts.poppins(color: const Color(0xff1f2937)),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Color(0xffef4444)),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: GoogleFonts.poppins(color: const Color(0xffef4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _buildHomePage(),
                  _buildProjectsPage(),
                  _buildTeamsPage(),
                  _buildProfilePage(),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onBottomNavTapped,
          selectedItemColor: const Color(0xff2563eb),
          unselectedItemColor: const Color(0xff6b7280),
          backgroundColor: Colors.white,
          elevation: 8,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Teams',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff2563eb),
            Color(0xff3b82f6),
            Color(0xff1d4ed8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Your Project Journey! 🚀',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'From idea to execution - let AI guide you through every step of your engineering project. Start with creating your project space and unlock:\n\n✨ AI-powered topic discovery\n🎯 Smart project naming\n📋 Automated roadmap generation\n🎯 Task tracking & team collaboration',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectSpaceCreationPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff2563eb),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: Text(
              'Start Your First Project',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }




  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }



  Widget _buildCurrentRoadmapSection() {
    if (_currentRoadmap == null) return const SizedBox.shrink();
    
    final completedTasks = _currentRoadmap!.tasks.where((task) => task.isCompleted).length;
    final totalTasks = _currentRoadmap!.tasks.length;
    final pendingTasks = _currentRoadmap!.tasks.where((task) => !task.isCompleted).take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Current Roadmap",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full roadmap view
              },
              child: Text(
                "View All",
                style: GoogleFonts.poppins(
                  color: const Color(0xff2563eb),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1f2937),
                    ),
                  ),
                  Text(
                    "$completedTasks/$totalTasks Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalTasks > 0 ? completedTasks / totalTasks : 0,
                backgroundColor: const Color(0xffe5e7eb),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff059669)),
              ),
              const SizedBox(height: 16),
              
              // Upcoming Tasks
              if (pendingTasks.isNotEmpty) ...[
                Text(
                  "Upcoming Tasks",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff6b7280),
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingTasks.map((task) => _buildQuickTaskItem(task)),
              ] else ...[
                Row(
                  children: [
                    const Icon(
                      Icons.celebration,
                      color: Color(0xff059669),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "All tasks completed! 🎉",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff059669),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          InkWell(
            onTap: _isUpdatingTask ? null : () => _toggleTaskCompletion(task),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff2563eb), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _isUpdatingTask
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Color(0xff059669))
                      : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: task.isCompleted ? const Color(0xff6b7280) : const Color(0xff1f2937),
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (task.priority.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.priority,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getPriorityColor(task.priority),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xffef4444);
      case 'medium':
        return const Color(0xfff59e0b);
      case 'low':
        return const Color(0xff059669);
      default:
        return const Color(0xff6b7280);
    }
  }

  Widget _buildProjectSpacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Project Spaces",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            TextButton(
              onPressed: _loadHomeData,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Refresh",
                    style: GoogleFonts.poppins(
                      color: const Color(0xff2563eb),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_projectSpaces.isEmpty)
          _buildNoProjectSpaces()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _projectSpaces.length,
            itemBuilder: (context, index) {
              final space = _projectSpaces[index];
              return _buildProjectSpaceCard(space);
            },
          ),
      ],
    );
  }

  Widget _buildNoProjectSpaces() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Minix! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to start your project journey? Create your first project space and let\'s build something amazing together!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectSpaceCreationPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Project Space'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSpaceCard(ProjectSpaceSummary space) {
    final DateTime created = space.createdAt;
    final String timeAgo = _getTimeAgo(created);
    final double progressPercentage = (space.currentStep / 4.0) * 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with team name and status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStepColor(space.currentStep).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        space.teamName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStepColor(space.currentStep).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStepIcon(space.currentStep),
                            size: 16,
                            color: _getStepColor(space.currentStep),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStepName(space.currentStep),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStepColor(space.currentStep),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (space.projectName != null) ...[
                  Text(
                    'Project: ${space.projectName}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff2563eb),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (space.selectedProblemTitle != null) ...[
                  Text(
                    'Problem: ${space.selectedProblemTitle}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff6b7280),
                          ),
                        ),
                        Text(
                          '${progressPercentage.toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStepColor(space.currentStep),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: space.currentStep / 4.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_getStepColor(space.currentStep)),
                      minHeight: 6,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Details and actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInfoChip(Icons.school, 'Year ${space.yearOfStudy}', const Color(0xff7c3aed)),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      space.targetPlatform == 'App' ? Icons.phone_android : 
                      space.targetPlatform == 'Web' ? Icons.web : Icons.language,
                      space.targetPlatform,
                      const Color(0xff059669),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.trending_up, space.difficulty, const Color(0xfff59e0b)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 16,
                      color: const Color(0xff6b7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${space.teamMembers.length} member${space.teamMembers.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: const Color(0xff6b7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created $timeAgo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                    const Spacer(),
                    _buildActionButton(space),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(ProjectSpaceSummary space) {
    if (space.currentStep >= 4) {
      // Completed project
      return IconButton(
        onPressed: () => _continueProjectSpace(space),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xff059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.open_in_new, size: 16),
      );
    } else {
      // In-progress project
      return IconButton(
        onPressed: () => _continueProjectSpace(space),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xff2563eb),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.arrow_forward, size: 16),
      );
    }
  }

  Color _getStepColor(int step) {
    switch (step) {
      case 1:
        return const Color(0xfff59e0b); // Amber - Space Created
      case 2:
        return const Color(0xff8b5cf6); // Purple - Problem Selected
      case 3:
        return const Color(0xff06b6d4); // Cyan - Name Selected
      case 4:
        return const Color(0xff059669); // Green - Roadmap Created
      default:
        return const Color(0xff6b7280); // Gray - Unknown
    }
  }

  String _getStepName(int step) {
    switch (step) {
      case 1:
        return 'Space Created';
      case 2:
        return 'Problem Selected';
      case 3:
        return 'Name Selected';
      case 4:
        return 'Roadmap Created';
      default:
        return 'Unknown';
    }
  }
  
  IconData _getStepIcon(int step) {
    switch (step) {
      case 1:
        return Icons.create;
      case 2:
        return Icons.search;
      case 3:
        return Icons.edit;
      case 4:
        return Icons.route;
      default:
        return Icons.help;
    }
  }
  
  String _getContinueButtonText(int step) {
    switch (step) {
      case 1:
        return 'Select Topic';
      case 2:
        return 'Choose Name';
      case 3:
        return 'Create Roadmap';
      default:
        return 'Continue';
    }
  }

  Future<void> _continueProjectSpace(ProjectSpaceSummary space) async {
    // Navigate to Project Steps Page to show sequential workflow
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectStepsPage(
          projectSpaceId: space.id,
          teamName: space.teamName,
          currentStep: space.currentStep,
          yearOfStudy: space.yearOfStudy,
          targetPlatform: space.targetPlatform,
          teamSize: space.teamMembers.length,
        ),
      ),
    );
  }
}
