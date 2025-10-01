import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return null;

    try {
      final snapshot = await _database
          .child('MiniProjectHelperUsers')
          .orderByChild('EmailID')
          .equalTo(user.email!)
          .once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        
        // Get the first (and should be only) matching entry
        final userEntry = data.values.first as Map<dynamic, dynamic>;
        
        return {
          'Name': userEntry['Name'] as String?,
          'EmailID': userEntry['EmailID'] as String?,
          'PhotoURL': userEntry['PhotoURL'] as String?,
          'Provider': userEntry['Provider'] as String?,
          'Branch': userEntry['Branch'] as String?,
          'Year': userEntry['Year'] as String?,
          'JoinDate': userEntry['JoinDate'] as int?,
        };
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
    }
    return null;
  }

  /// Get full branch name from code
  String getBranchName(String? branchCode) {
    const branchNames = {
      'CO': 'Computer Engineering',
      'IT': 'Information Technology',
      'AIDS': 'AI & Data Science',
      'CE': 'Civil Engineering',
    };
    return branchNames[branchCode] ?? branchCode ?? 'Not set';
  }

  /// Get full year name from code
  String getYearName(String? yearCode) {
    const yearNames = {
      'FE': 'First Year',
      'SE': 'Second Year',
      'TE': 'Third Year',
      'BE': 'Final Year',
    };
    return yearNames[yearCode] ?? yearCode ?? 'Not set';
  }

  /// Get skill level based on year
  String getSkillLevel(String? yearCode) {
    const skillLevels = {
      'FE': 'Beginner',
      'SE': 'Intermediate',
      'TE': 'Advanced',
      'BE': 'Expert',
    };
    return skillLevels[yearCode] ?? 'Intermediate';
  }
}
