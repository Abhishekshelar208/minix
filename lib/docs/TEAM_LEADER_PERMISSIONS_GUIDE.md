# Team Leader Permissions Implementation Guide

## Overview
This guide explains how to implement team leader permissions in all project step pages. Only team leaders can make changes to project steps, while other team members have read-only access.

## Quick Summary
- **Team leader** = can edit all project steps (role: 'leader')
- **Team member** = read-only access, can view but not edit (role: 'member')
- Team leaders are designated when creating the project space using a star toggle button

## Implementation Steps for Each Page

### 1. Add Required Imports
```dart
import 'package:minix/services/invitation_service.dart';
import 'package:minix/widgets/read_only_banner.dart';
```

### 2. Add Permission State Variables
```dart
class _YourPageState extends State<YourPage> {
  final _invitationService = InvitationService();
  
  // Permissions
  bool _canEdit = true;  // Whether current user can edit (is leader)
  bool _isCheckingPermissions = true;
  
  // ... rest of your state variables
}
```

### 3. Check Permissions in initState
```dart
@override
void initState() {
  super.initState();
  _checkPermissions();
  // ... other initialization
}

Future<void> _checkPermissions() async {
  final canEdit = await _invitationService.canEditProject(widget.projectSpaceId);
  setState(() {
    _canEdit = canEdit;
    _isCheckingPermissions = false;
  });
}
```

### 4. Add Read-Only Banner in UI
Add this at the top of your main content area:
```dart
body: Column(
  children: [
    // Read-only banner for non-leaders
    if (!_canEdit) const ReadOnlyBanner(),
    
    // Rest of your UI
  ],
),
```

### 5. Disable Interactive Elements for Non-Leaders

#### Buttons
```dart
ElevatedButton(
  onPressed: _canEdit ? _yourFunction : null,  // Disable if not leader
  child: Text('Action'),
)
```

#### Text Fields
```dart
TextFormField(
  enabled: _canEdit,  // Disable if not leader
  decoration: InputDecoration(
    hintText: _canEdit ? 'Enter text...' : 'Read-only mode',
  ),
)
```

#### Icon Buttons
```dart
IconButton(
  onPressed: _canEdit ? _yourFunction : null,
  tooltip: _canEdit ? 'Action' : 'Only leaders can perform this action',
  icon: Icon(Icons.edit),
)
```

## Example: Complete Page Implementation

See `project_solution_page.dart` for a full example implementation. Key points:

1. **Permission checking** happens in `initState`
2. **Read-only banner** appears at the top when `!_canEdit`
3. **All action buttons** are disabled with `_canEdit ? function : null`
4. **Text fields** use `enabled: _canEdit`
5. **Tooltips** show helpful messages for disabled actions

## Pages That Need This Implementation

Apply these changes to all project step pages:
- ✅ `project_solution_page.dart` (DONE - reference implementation)
- `topic_selection_page.dart`
- `project_name_suggestions_page.dart`
- `project_roadmap_page.dart`
- `code_generation_page.dart`
- `ppt_generation_page.dart`
- `project_documentation_page.dart`
- `viva_preparation_page.dart`

## Testing Checklist

For each page, verify:
- [ ] Read-only banner appears for non-leaders
- [ ] All edit buttons are disabled for non-leaders
- [ ] Text fields are read-only for non-leaders
- [ ] Tooltips explain why actions are disabled
- [ ] Leaders can still perform all actions normally
- [ ] Page loads without errors when checking permissions

## Database Structure

### ProjectMembers Node
```json
{
  "ProjectMembers": {
    "projectSpaceId": {
      "userId": {
        "userId": "abc123",
        "name": "John Doe",
        "email": "john@example.com",
        "role": "leader",  // or "member"
        "joinedAt": 1234567890,
        "isActive": true
      }
    }
  }
}
```

### UserProjects Node
```json
{
  "UserProjects": {
    "userId": {
      "projectSpaceId": {
        "projectSpaceId": "project123",
        "role": "leader",  // or "member"
        "joinedAt": 1234567890
      }
    }
  }
}
```

## Permission Helper Methods

Available in `InvitationService`:

```dart
// Check if user can edit project
Future<bool> canEditProject(String projectSpaceId);

// Get user's role (returns 'leader' or 'member')
Future<String?> getUserRole(String projectSpaceId);

// Get full permission details
Future<Map<String, dynamic>> getProjectPermissions(String projectSpaceId);
```

## Visual Indicators

### Team Leader Badge
In project space creation and member lists, team leaders show a yellow "LEADER" badge:
```dart
if (member['isLeader'] == true) 
  Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Color(0xffeab308),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('LEADER'),
  )
```

### Star Toggle Button
When adding members during project creation, a star icon toggles leader status:
- Filled yellow star = team leader
- Gray outlined star = regular member

## Best Practices

1. **Always check permissions** in `initState` before loading data
2. **Show clear visual feedback** with read-only banner
3. **Disable, don't hide** - users should see options but understand why they're disabled
4. **Use helpful tooltips** to explain permission requirements
5. **Test with both roles** - verify behavior as leader and member
6. **Handle async properly** - permission checks are asynchronous

## Common Patterns

### Conditional Rendering
```dart
if (_canEdit) 
  // Show edit controls
else
  // Show read-only message or badge
```

### Button States
```dart
onPressed: (!_canEdit || _isProcessing) ? null : _handleAction,
```

### Form Validation
```dart
if (!_canEdit) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Only team leaders can make changes')),
  );
  return;
}
```

## Troubleshooting

**Q: Permission check returns false even for leader**
- Verify user's role in Firebase database
- Check that project space ID is correct
- Ensure user is in ProjectMembers node

**Q: Banner doesn't appear**
- Verify `_canEdit` is properly set in state
- Check that ReadOnlyBanner widget is imported
- Ensure column structure allows banner to display

**Q: Actions still work when disabled**
- Make sure `onPressed: null` is set when `!_canEdit`
- Check that form fields have `enabled: _canEdit`
- Verify save/submit functions check `_canEdit` at start

## Support

For implementation questions or issues, refer to:
- `project_solution_page.dart` - Reference implementation
- `invitation_service.dart` - Permission checking methods
- `read_only_banner.dart` - Read-only UI component
