# Profile Page Data Source Analysis

## Overview
This document explains where the personal data displayed in the profile page comes from and the underlying database structure.

---

## 📊 Current Data Sources

### 1. **Firebase Authentication (Primary Source)**

The profile page (`home_screen.dart` - 4th tab) primarily uses **Firebase Authentication** data, accessed via:

```dart
User? user = _auth.currentUser;
```

#### Available Firebase Auth Fields:

| Field | Type | Example | Used In |
|-------|------|---------|---------|
| `user.displayName` | String? | "Abhishek Shelar" | Profile header, welcome message |
| `user.email` | String? | "abhishek@gmail.com" | Profile header, contact info |
| `user.photoURL` | String? | "https://..." | Profile picture/avatar |
| `user.uid` | String | "abc123xyz..." | User identification |
| `user.metadata.creationTime` | DateTime? | 2024-01-15 | Join date display |
| `user.emailVerified` | bool | true/false | Verification badge |

**Code Location**: `lib/pages/home_screen.dart` - Line 1169, 52-199

---

### 2. **Firebase Realtime Database (Secondary Source - Currently NOT Used in Profile)**

During signup, additional profile data is saved to Firebase Realtime Database but **NOT currently being fetched/displayed** in the profile page.

#### Database Path:
```
MiniProjectHelperUsers/
  {pushId}/
    - Name: "Abhishek Shelar"
    - EmailID: "abhishek@gmail.com"
    - PhotoURL: "https://..."
    - Provider: "google"
    - Branch: "CO" / "IT" / "AIDS" / "CE"
    - Year: "FE" / "SE" / "TE" / "BE"
    - JoinDate: 1705320000 (timestamp)
```

**Saved In**: `lib/pages/login_signup_screen.dart` - Lines 126-194

---

## 🗂️ Database Structure Details

### Firebase Realtime Database Schema

```json
{
  "MiniProjectHelperUsers": {
    "{auto-generated-push-id}": {
      "Name": "Abhishek Shelar",
      "EmailID": "abhishek@gmail.com",
      "PhotoURL": "https://lh3.googleusercontent.com/a/...",
      "Provider": "google",
      "Branch": "CO",
      "Year": "SE",
      "JoinDate": 1705320000
    },
    "{another-push-id}": {
      "Name": "Another User",
      "EmailID": "user@example.com",
      "PhotoURL": "",
      "Provider": "google",
      "Branch": "IT",
      "Year": "TE",
      "JoinDate": 1705406400
    }
  }
}
```

### Field Descriptions:

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `Name` | String | Yes | User's full name | From profile form |
| `EmailID` | String | Yes | User's email address | Unique identifier for queries |
| `PhotoURL` | String | No | Google profile picture URL | Empty string if not available |
| `Provider` | String | Yes | Authentication method | Currently only "google" |
| `Branch` | String | Yes | Engineering branch | CO, IT, AIDS, CE |
| `Year` | String | Yes | Academic year | FE, SE, TE, BE |
| `JoinDate` | Number | Yes | Account creation timestamp | Unix timestamp (milliseconds) |

---

## 🎨 Profile Page Current Display

### What's Currently Shown:

The profile page (`_buildProfilePage()` at line 1168) displays:

1. **Profile Header Card** (`_buildProfileHeaderCard` - Lines 52-200)
   - ✅ Profile Picture (from `user.photoURL`)
   - ✅ Display Name (from `user.displayName`)
   - ✅ Email (from `user.email`)
   - ✅ Verified Account Badge
   - ✅ Join Date (from `user.metadata.creationTime`)
   - ✅ Active Status

2. **Academic Info Card** (`_buildAcademicInfoCard` - Lines 265-305)
   - ❌ **HARDCODED** - "Computer Engineering"
   - ❌ **HARDCODED** - "Second Year (SE)"
   - ❌ **HARDCODED** - "Intermediate"
   - 📝 **TODO Comment**: "Fetch user's academic info from profile data stored during signup" (Line 266)

3. **Project Statistics Card** (`_buildProfileStatsCard` - Lines 307-397)
   - ✅ Total Projects (from `_projectStats`)
   - ✅ Completed Projects (from `_projectStats`)
   - ✅ In Progress Projects (from `_projectStats`)

4. **Account Settings Card** (`_buildAccountSettingsCard`)
   - Settings options

5. **App Info Card** (`_buildAppInfoCard`)
   - App version, support, etc.

---

## ⚠️ Current Issue

### Academic Info is Hardcoded!

**Location**: `lib/pages/home_screen.dart` - Lines 265-305

```dart
Widget _buildAcademicInfoCard() {
  // TODO: Fetch user's academic info from profile data stored during signup
  return Container(
    // ...
    children: [
      _buildInfoRow(Icons.business, 'Branch', 'Computer Engineering', ...),  // ❌ HARDCODED
      _buildInfoRow(Icons.calendar_view_day, 'Academic Year', 'Second Year (SE)', ...), // ❌ HARDCODED
      _buildInfoRow(Icons.trending_up, 'Skill Level', 'Intermediate', ...), // ❌ HARDCODED
    ],
  );
}
```

**Problem**: 
- Data is saved to database during signup (Branch: CO/IT/AIDS/CE, Year: FE/SE/TE/BE)
- But it's **NOT being fetched** and displayed
- Instead, hardcoded values are shown to ALL users

---

## 🔍 How Data Flow Works

### 1. **Sign Up / First Login Flow**

```
User clicks "Sign in with Google"
    ↓
Profile form shows (name, branch, year)
    ↓
User fills form and submits
    ↓
Google authentication happens
    ↓
User data saved to "MiniProjectHelperUsers" in Firebase Realtime Database
    ↓
User navigates to Home Screen
```

**Code Path**: 
- `login_signup_screen.dart` → `_showProfileFormDialog()` → `_handleProfileSubmit()` → `_handleGoogleSignIn()` → `_saveUserWithProfile()`

### 2. **Returning User Flow**

```
User signs in with Google
    ↓
Check if email exists in "MiniProjectHelperUsers"
    ↓
If exists: Show "Welcome back!" (no new data saved)
    ↓
User navigates to Home Screen
```

**Code Path**: 
- `login_signup_screen.dart` → Lines 140-181

### 3. **Profile Page Display Flow**

```
User clicks "Profile" tab (4th tab)
    ↓
_buildProfilePage() called
    ↓
Gets user from FirebaseAuth.currentUser
    ↓
Displays: Firebase Auth data ✅
    ↓
Academic Info: Uses HARDCODED values ❌
```

**Code Path**: 
- `home_screen.dart` → Line 1168 → `_buildProfilePage()`

---

## 🛠️ How to Fix: Fetch Real Academic Data

### Step 1: Create a Service to Fetch User Profile

Create `lib/services/user_profile_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        final userEntry = data.values.first as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(userEntry);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }
}
```

### Step 2: Update Home Screen State

In `home_screen.dart`, add:

```dart
class _HomeScreenState extends State<HomeScreen> {
  // ... existing variables
  Map<String, dynamic>? _userProfile;
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // ... existing code
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userProfileService.getUserProfile();
    setState(() {
      _userProfile = profile;
    });
  }
}
```

### Step 3: Update Academic Info Card

Replace hardcoded values:

```dart
Widget _buildAcademicInfoCard() {
  // Use real data from _userProfile
  final branch = _userProfile?['Branch'] ?? 'Not set';
  final year = _userProfile?['Year'] ?? 'Not set';
  
  // Map branch codes to full names
  final branchNames = {
    'CO': 'Computer Engineering',
    'IT': 'Information Technology',
    'AIDS': 'AI & Data Science',
    'CE': 'Civil Engineering',
  };
  
  // Map year codes to full names
  final yearNames = {
    'FE': 'First Year',
    'SE': 'Second Year',
    'TE': 'Third Year',
    'BE': 'Final Year',
  };
  
  return Container(
    // ...
    _buildInfoRow(
      Icons.business, 
      'Branch', 
      branchNames[branch] ?? branch, 
      const Color(0xff7c3aed)
    ),
    _buildInfoRow(
      Icons.calendar_view_day, 
      'Academic Year', 
      yearNames[year] ?? year, 
      const Color(0xff059669)
    ),
    // ...
  );
}
```

---

## 📋 Summary

### Data Sources:

1. **Firebase Authentication** (Currently Used ✅)
   - Display Name, Email, Photo URL, Join Date
   - Accessed via `FirebaseAuth.instance.currentUser`

2. **Firebase Realtime Database** (Currently NOT Used ❌)
   - Branch, Year, Provider info
   - Path: `MiniProjectHelperUsers/{pushId}`
   - Query by: `EmailID` field
   - **Needs to be fetched and displayed**

### Action Items:

1. ✅ Profile data IS being saved during signup
2. ❌ Profile data is NOT being fetched for display
3. ❌ Academic info shows hardcoded values
4. 🔧 Need to create service to fetch from `MiniProjectHelperUsers`
5. 🔧 Need to update profile page to show real data

---

## 🗄️ Other Database Nodes (For Context)

Your app also uses these Firebase Realtime Database paths:

```
Firebase Realtime Database Root
├── MiniProjectHelperUsers/        ← User profiles (signup data)
├── ProjectSpaces/                 ← Project workspaces
├── ProjectMembers/                ← Project team members with roles
├── UserProjects/                  ← User's project associations
├── ProjectInvitations/            ← Team invitations
├── Invitations/                   ← User-specific invitations
├── Projects/                      ← Draft projects
├── Roadmaps/                      ← Project roadmaps
├── RoadmapTasks/                  ← Roadmap tasks
└── Bookmarks/                     ← User's bookmarked topics
```

---

## 🔐 Security Considerations

### Current Security:

- Firebase Authentication handles user authentication ✅
- Database has rules (check `database.rules.json`) 📋
- Email is used as unique identifier for queries ✅

### Recommendations:

1. Add database rules to protect `MiniProjectHelperUsers` node
2. Only allow users to read their own profile data
3. Only allow users to write during initial signup

Example security rule:
```json
{
  "rules": {
    "MiniProjectHelperUsers": {
      "$userId": {
        ".read": "auth != null && data.child('EmailID').val() === auth.token.email",
        ".write": "auth != null && !data.exists()"
      }
    }
  }
}
```

---

## 📝 Conclusion

**Current State**:
- Profile picture, name, email, join date: ✅ **Working** (from Firebase Auth)
- Branch, year, academic info: ❌ **Hardcoded** (not fetched from database)

**Database State**:
- User profile data: ✅ **Being saved** during signup to `MiniProjectHelperUsers`
- User profile data: ❌ **NOT being fetched** for display

**Next Steps**:
- Implement `UserProfileService` to fetch data from `MiniProjectHelperUsers`
- Update profile page to display real academic information
- Remove hardcoded values

Would you like me to implement the fix to fetch and display the real academic data?
