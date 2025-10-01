class TeamMember {
  final String userId;
  final String name;
  final String email;
  final String role; // 'leader', 'co-leader', 'member'
  final DateTime joinedAt;
  final bool isActive;
  final String? photoUrl;
  final Map<String, dynamic>? permissions;
  final DateTime? lastActive;
  final int tasksCompleted;
  final String status; // 'active', 'inactive', 'invited'

  TeamMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    this.photoUrl,
    this.permissions,
    this.lastActive,
    this.tasksCompleted = 0,
    this.status = 'active',
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'photoUrl': photoUrl,
      'permissions': permissions,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'tasksCompleted': tasksCompleted,
      'status': status,
    };
  }

  // Create from Firebase JSON
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] as int),
      isActive: json['isActive'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
      permissions: json['permissions'] as Map<String, dynamic>?,
      lastActive: json['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActive'] as int)
          : null,
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }

  // Create a copy with updated fields
  TeamMember copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    DateTime? joinedAt,
    bool? isActive,
    String? photoUrl,
    Map<String, dynamic>? permissions,
    DateTime? lastActive,
    int? tasksCompleted,
    String? status,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      permissions: permissions ?? this.permissions,
      lastActive: lastActive ?? this.lastActive,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      status: status ?? this.status,
    );
  }

  bool get isLeader => role == 'leader';
  bool get isCoLeader => role == 'co-leader';
  bool get canManageTeam => isLeader || isCoLeader;
  bool get isInvited => status == 'invited';
}
