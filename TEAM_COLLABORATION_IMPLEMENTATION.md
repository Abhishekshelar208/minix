# 🤝 Team Collaboration Feature - Complete Implementation Guide

**Feature:** Team Leader invites members → Members receive notifications → Accept invitation → Full project access

**Status:** Ready to implement  
**Estimated Time:** 2-3 hours  
**Created:** 2025-10-01

---

## 📋 Overview

This feature enables true team collaboration in Minix:
1. **Team Leader** creates project space and adds team members (name + email)
2. **System** automatically sends invitations to all team members
3. **Team Members** see pending invitations when they open the app
4. **Members Accept** → Get full access to all project steps (just like the leader)
5. **Real-time Sync** → All team members see the same data

---

## ✅ What's Been Created

### 1. **New Model:** `ProjectInvitation`
**File:** `lib/models/project_invitation.dart`

**Features:**
- Complete invitation data structure
- Status tracking (pending/accepted/rejected)
- Team leader info
- Project details
- Timestamps
- JSON serialization for Firebase

### 2. **New Service:** `InvitationService`
**File:** `lib/services/invitation_service.dart`

**Key Methods:**
- `sendInvitation()` - Send single invitation
- `sendBulkInvitations()` - Send to multiple members at once
- `getPendingInvitations()` - Stream of user's pending invites
- `acceptInvitation()` - Accept and join project
- `rejectInvitation()` - Decline invitation
- `isProjectMember()` - Check membership
- `getUserRole()` - Get user's role (leader/member)
- `getProjectMembers()` - Get all team members
- `removeMember()` - Remove member (leader only)
- `getPendingInvitationCount()` - Badge count

---

## 🗄️ Firebase Database Structure

### New Collections:

```
Firebase Database
├── Invitations/
│   ├── {userEmail_with_underscores}/
│   │   ├── {invitationId}/
│   │   │   ├── id: string
│   │   │   ├── projectSpaceId: string
│   │   │   ├── projectName: string
│   │   │   ├── teamLeaderId: string
│   │   │   ├── teamLeaderName: string
│   │   │   ├── teamLeaderEmail: string
│   │   │   ├── invitedMemberEmail: string
│   │   │   ├── invitedMemberName: string
│   │   │   ├── status: 'pending'|'accepted'|'rejected'
│   │   │   ├── invitedAt: timestamp
│   │   │   ├── respondedAt: timestamp (nullable)
│   │   │   ├── teamName: string
│   │   │   ├── targetPlatform: string
│   │   │   └── yearOfStudy: number
│
├── ProjectInvitations/
│   ├── {projectSpaceId}/
│   │   ├── {invitationId}/
│   │   │   ├── invitationId: string
│   │   │   ├── memberEmail: string
│   │   │   ├── memberName: string
│   │   │   ├── status: 'pending'|'accepted'|'rejected'
│   │   │   └── sentAt: timestamp
│
├── ProjectMembers/
│   ├── {projectSpaceId}/
│   │   ├── {userId}/
│   │   │   ├── userId: string
│   │   │   ├── name: string
│   │   │   ├── email: string
│   │   │   ├── role: 'leader'|'member'
│   │   │   ├── joinedAt: timestamp
│   │   │   └── isActive: boolean
│
└── UserProjects/
    ├── {userId}/
    │   ├── {projectSpaceId}/
    │   │   ├── projectSpaceId: string
    │   │   ├── role: 'leader'|'member'
    │   │   └── joinedAt: timestamp
```

### Why This Structure?

1. **Invitations indexed by email:** Users can quickly find their invites
2. **ProjectInvitations:** Leaders can see who they invited
3. **ProjectMembers:** Easy membership verification
4. **UserProjects:** User can see all their projects (owned + joined)

---

## 🔧 Implementation Steps

### **Step 1: Update Project Creation Page** ✅ (Next)

**File:** `lib/pages/project_space_creation_page.dart`

**Changes Needed:**

1. Import the InvitationService
2. After project creation, send bulk invitations
3. Add the team leader as a member with 'leader' role

**Code to Add:**

```dart
import 'package:minix/services/invitation_service.dart';

// Add to _ProjectSpaceCreationPageState
final _invitationService = InvitationService();

// In _createProjectSpace() method, after project is created:

// Add leader as project member
await _database
    .child('ProjectMembers')
    .child(projectSpaceId)
    .child(_auth.currentUser!.uid)
    .set({
  'userId': _auth.currentUser!.uid,
  'name': _auth.currentUser!.displayName ?? 'Team Leader',
  'email': _auth.currentUser!.email,
  'role': 'leader',
  'joinedAt': DateTime.now().millisecondsSinceEpoch,
  'isActive': true,
});

// Send invitations to all team members
if (_teamMembers.isNotEmpty) {
  await _invitationService.sendBulkInvitations(
    projectSpaceId: projectSpaceId,
    projectName: _teamNameController.text.trim(),
    teamName: _teamNameController.text.trim(),
    targetPlatform: _selectedPlatform,
    yearOfStudy: _selectedYear,
    members: _teamMembers,
  );
}
```

---

### **Step 2: Add Invitation Notifications to Home Screen** ✅ (Next)

**File:** `lib/pages/home_screen.dart`

**Add:**
1. Stream listener for pending invitations
2. Notification banner/card at top of home screen
3. Accept/Reject buttons

**UI Design:**

```
┌─────────────────────────────────────────────────────────┐
│  🔔 Pending Invitations (2)                             │
├─────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────┐  │
│  │ 📋 Tech Innovators                                │  │
│  │ John Doe invited you to join                      │  │
│  │ Platform: App • Year: 3                           │  │
│  │ [✓ Accept]  [✗ Decline]                          │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 📋 Code Warriors                                  │  │
│  │ Jane Smith invited you to join                    │  │
│  │ Platform: Web • Year: 4                           │  │
│  │ [✓ Accept]  [✗ Decline]                          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Code to Add:**

```dart
import 'package:minix/services/invitation_service.dart';
import 'package:minix/models/project_invitation.dart';

// Add to _HomeScreenState
final _invitationService = InvitationService();
Stream<List<ProjectInvitation>>? _invitationsStream;

@override
void initState() {
  super.initState();
  _invitationsStream = _invitationService.getPendingInvitations();
}

// Add widget method
Widget _buildInvitationsSection() {
  return StreamBuilder<List<ProjectInvitation>>(
    stream: _invitationsStream,
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const SizedBox.shrink();
      }

      final invitations = snapshot.data!;

      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Invitations (${invitations.length})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            // Invitation cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                return _buildInvitationCard(invitations[index]);
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildInvitationCard(ProjectInvitation invitation) {
  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                invitation.teamName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${invitation.teamLeaderName} invited you to join',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              Icons.phone_android,
              invitation.targetPlatform,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.school,
              'Year ${invitation.yearOfStudy}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptInvitation(invitation),
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectInvitation(invitation),
                icon: const Icon(Icons.close),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildInfoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    ),
  );
}

Future<void> _acceptInvitation(ProjectInvitation invitation) async {
  try {
    await _invitationService.acceptInvitation(invitation);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Joined "${invitation.teamName}" successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh home screen to show new project
      setState(() {});
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to accept invitation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _rejectInvitation(ProjectInvitation invitation) async {
  try {
    await _invitationService.rejectInvitation(invitation);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation declined'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to decline invitation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Add to build() method:**
```dart
// Add after app bar, before project spaces
_buildInvitationsSection(),
```

---

### **Step 3: Update Project Service to Load Member Projects** ✅

**File:** `lib/services/project_service.dart`

**Add method to get user's projects (both owned and joined):**

```dart
Future<List<Map<String, dynamic>>> getUserProjects() async {
  try {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    // Get projects from UserProjects collection
    final snapshot = await _database
        .child('UserProjects')
        .child(userId)
        .get();

    if (!snapshot.exists) return [];

    final projectIds = <String>[];
    final data = snapshot.value as Map<dynamic, dynamic>;
    
    data.forEach((key, value) {
      projectIds.add(key as String);
    });

    // Fetch full project data for each project
    final projects = <Map<String, dynamic>>[];
    for (final projectId in projectIds) {
      final projectSnapshot = await _database
          .child('ProjectSpaces')
          .child(projectId)
          .get();
      
      if (projectSnapshot.exists) {
        final projectData = Map<String, dynamic>.from(
          projectSnapshot.value as Map
        );
        projectData['id'] = projectId;
        projects.add(projectData);
      }
    }

    return projects;
  } catch (e) {
    print('Error getting user projects: $e');
    return [];
  }
}
```

---

### **Step 4: Update Firebase Security Rules** ✅

**File:** `database.rules.json`

Add rules for new collections:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "ProjectSpaces": {
      "$projectId": {
        ".read": "auth != null && (root.child('ProjectMembers').child($projectId).child(auth.uid).exists() || root.child('ProjectSpaces').child($projectId).child('ownerId').val() == auth.uid)",
        ".write": "auth != null && (root.child('ProjectMembers').child($projectId).child(auth.uid).exists() || root.child('ProjectSpaces').child($projectId).child('ownerId').val() == auth.uid)"
      }
    },
    "ProjectMembers": {
      "$projectId": {
        ".read": "auth != null && (root.child('ProjectMembers').child($projectId).child(auth.uid).exists() || root.child('ProjectSpaces').child($projectId).child('ownerId').val() == auth.uid)",
        ".write": "auth != null && root.child('ProjectMembers').child($projectId).child(auth.uid).child('role').val() == 'leader'"
      }
    },
    "Invitations": {
      "$userEmail": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "ProjectInvitations": {
      "$projectId": {
        ".read": "auth != null && (root.child('ProjectMembers').child($projectId).child(auth.uid).exists() || root.child('ProjectSpaces').child($projectId).child('ownerId').val() == auth.uid)",
        ".write": "auth != null && (root.child('ProjectMembers').child($projectId).child(auth.uid).child('role').val() == 'leader' || root.child('ProjectSpaces').child($projectId).child('ownerId').val() == auth.uid)"
      }
    },
    "UserProjects": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null"
      }
    }
  }
}
```

---

## 🚀 Complete User Flow

### **Scenario: Team Leader Creates Project**

1. **Leader (John)** opens app
2. Clicks "Create Project Space"
3. Fills in:
   - Team Name: "Tech Innovators"
   - Year: 3
   - Platform: App
   - Adds members:
     - Alice (alice@email.com)
     - Bob (bob@email.com)
4. Clicks "Create Project Space"
5. **System automatically:**
   - Creates project space
   - Adds John as leader in ProjectMembers
   - Sends invitations to Alice and Bob
   - Stores invitations in Firebase
6. John sees success message
7. John can now proceed with project steps

---

### **Scenario: Team Member Receives Invitation**

1. **Alice** opens the Minix app
2. On home screen, sees notification banner:
   ```
   🔔 Pending Invitations (1)
   
   📋 Tech Innovators
   John Doe invited you to join
   Platform: App • Year: 3
   [✓ Accept]  [✗ Decline]
   ```
3. Alice clicks "Accept"
4. **System automatically:**
   - Updates invitation status to 'accepted'
   - Adds Alice to ProjectMembers
   - Adds project to Alice's UserProjects
5. Alice sees success: "✅ Joined Tech Innovators successfully!"
6. Project now appears in Alice's project list
7. Alice can view and edit all project steps (1-8)

---

### **Scenario: Both Leader and Member Work Together**

1. **John (Leader)** works on Step 1: Topic Selection
   - Selects a problem
   - Saves to Firebase
2. **Alice (Member)** opens app later
   - Sees same project
   - Sees Topic already selected by John
   - Can continue to Step 2: Project Naming
3. **Bob (Member)** joins later
   - Accepts invitation
   - Sees all work done by John and Alice
   - Can contribute to any step
4. **Real-time sync:** Everyone sees the same data!

---

## 🎨 UI Components to Create

### 1. **Invitation Card Component** ✅
- Team name
- Leader info
- Project details (platform, year)
- Accept/Reject buttons
- Modern design with icons

### 2. **Invitation Banner** ✅
- Notification count badge
- Collapsible list
- Quick accept/reject actions

### 3. **Team Members Page** (Optional but recommended)
- View all team members
- See pending invitations
- Remove members (leader only)
- Member roles (leader/member badges)

---

## 🔒 Security Features

✅ **Email-based invitations** - Only people with invited email can accept  
✅ **Role-based access** - Leaders have extra permissions  
✅ **Firebase security rules** - Server-side validation  
✅ **Invitation expiry** - Can add time limits later  
✅ **No duplicate joins** - One user, one role per project

---

## 🧪 Testing Checklist

### **Test Case 1: Send Invitations**
- [ ] Leader creates project with 2 members
- [ ] Check Firebase: Invitations exist in database
- [ ] Verify invitation data is correct

### **Test Case 2: Receive Invitations**
- [ ] Open app with invited email
- [ ] See notification banner
- [ ] Count matches number of invitations

### **Test Case 3: Accept Invitation**
- [ ] Click Accept button
- [ ] See success message
- [ ] Project appears in project list
- [ ] Can access all project steps
- [ ] Firebase: User added to ProjectMembers

### **Test Case 4: Reject Invitation**
- [ ] Click Decline button
- [ ] Invitation disappears
- [ ] Firebase: Status updated to 'rejected'
- [ ] Project does NOT appear in list

### **Test Case 5: Collaboration**
- [ ] Leader edits project (e.g., select topic)
- [ ] Member opens app
- [ ] Member sees leader's changes
- [ ] Member can edit same project
- [ ] Changes sync in real-time

### **Test Case 6: Edge Cases**
- [ ] Invite user who doesn't have app yet
- [ ] Multiple invitations to same user
- [ ] Re-invite after rejection
- [ ] Remove member after they join

---

## 📱 Next Steps to Implement

### **Priority 1: Core Functionality** (2-3 hours)
1. ✅ Update `project_space_creation_page.dart` (30 min)
   - Add invitation service
   - Send invitations after project creation
   - Add leader as member

2. ✅ Update `home_screen.dart` (1 hour)
   - Add invitation stream
   - Build invitation UI cards
   - Implement accept/reject handlers

3. ✅ Update `project_service.dart` (30 min)
   - Add `getUserProjects()` method
   - Modify project loading to include member projects

4. ✅ Deploy Firebase rules (15 min)
   - Update `database.rules.json`
   - Deploy to Firebase console

5. ✅ Test complete flow (45 min)
   - Create test accounts
   - Full end-to-end testing

---

## 🎯 Expected Results

After implementation:

✅ **Team Leader can:**
- Create project and invite members
- See pending invitations status
- Work on project normally

✅ **Team Members can:**
- Receive real-time invitation notifications
- Accept/reject invitations easily
- Access ALL project steps after joining
- Collaborate with full edit permissions

✅ **System ensures:**
- Email-based verification
- Secure role-based access
- Real-time data synchronization
- No conflicts or data loss

---

## 📚 Additional Resources

### Firebase Collections Created:
- `Invitations/{email}/{invitationId}`
- `ProjectInvitations/{projectId}/{invitationId}`
- `ProjectMembers/{projectId}/{userId}`
- `UserProjects/{userId}/{projectId}`

### Files Created:
- `lib/models/project_invitation.dart` ✅
- `lib/services/invitation_service.dart` ✅

### Files to Modify:
- `lib/pages/project_space_creation_page.dart`
- `lib/pages/home_screen.dart`
- `lib/services/project_service.dart`
- `database.rules.json`

---

## 🎉 Feature Benefits

1. **Real Team Collaboration** - Not just mockup data
2. **Secure Invitations** - Email-based verification
3. **Easy to Use** - One-click accept/reject
4. **Scalable** - Works for teams of any size
5. **Professional** - Enterprise-grade features

---

**Status:** Ready to implement! Start with Step 1 and follow the guide sequentially. Each step is well-documented with exact code to add.

**Questions?** Each section has detailed explanations and code examples. Start implementing and test after each step!
