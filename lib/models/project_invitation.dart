class ProjectInvitation {
  final String id;
  final String projectSpaceId;
  final String projectName;
  final String teamLeaderId;
  final String teamLeaderName;
  final String teamLeaderEmail;
  final String invitedMemberEmail;
  final String invitedMemberName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime invitedAt;
  final DateTime? respondedAt;
  final String teamName;
  final String targetPlatform;
  final int yearOfStudy;
  final bool isLeader; // Whether the invited member will be a team leader

  ProjectInvitation({
    required this.id,
    required this.projectSpaceId,
    required this.projectName,
    required this.teamLeaderId,
    required this.teamLeaderName,
    required this.teamLeaderEmail,
    required this.invitedMemberEmail,
    required this.invitedMemberName,
    required this.status,
    required this.invitedAt,
    this.respondedAt,
    required this.teamName,
    required this.targetPlatform,
    required this.yearOfStudy,
    this.isLeader = false, // Default to false for regular members
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectSpaceId': projectSpaceId,
      'projectName': projectName,
      'teamLeaderId': teamLeaderId,
      'teamLeaderName': teamLeaderName,
      'teamLeaderEmail': teamLeaderEmail,
      'invitedMemberEmail': invitedMemberEmail,
      'invitedMemberName': invitedMemberName,
      'status': status,
      'invitedAt': invitedAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
      'teamName': teamName,
      'targetPlatform': targetPlatform,
      'yearOfStudy': yearOfStudy,
      'isLeader': isLeader,
    };
  }

  // Create from Firebase JSON
  factory ProjectInvitation.fromJson(Map<String, dynamic> json) {
    return ProjectInvitation(
      id: json['id'] as String,
      projectSpaceId: json['projectSpaceId'] as String,
      projectName: json['projectName'] as String? ?? '',
      teamLeaderId: json['teamLeaderId'] as String,
      teamLeaderName: json['teamLeaderName'] as String,
      teamLeaderEmail: json['teamLeaderEmail'] as String,
      invitedMemberEmail: json['invitedMemberEmail'] as String,
      invitedMemberName: json['invitedMemberName'] as String,
      status: json['status'] as String? ?? 'pending',
      invitedAt: DateTime.fromMillisecondsSinceEpoch(json['invitedAt'] as int),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['respondedAt'] as int)
          : null,
      teamName: json['teamName'] as String? ?? '',
      targetPlatform: json['targetPlatform'] as String? ?? 'App',
      yearOfStudy: json['yearOfStudy'] as int? ?? 2,
      isLeader: json['isLeader'] as bool? ?? false,
    );
  }

  // Create a copy with updated fields
  ProjectInvitation copyWith({
    String? id,
    String? projectSpaceId,
    String? projectName,
    String? teamLeaderId,
    String? teamLeaderName,
    String? teamLeaderEmail,
    String? invitedMemberEmail,
    String? invitedMemberName,
    String? status,
    DateTime? invitedAt,
    DateTime? respondedAt,
    String? teamName,
    String? targetPlatform,
    int? yearOfStudy,
    bool? isLeader,
  }) {
    return ProjectInvitation(
      id: id ?? this.id,
      projectSpaceId: projectSpaceId ?? this.projectSpaceId,
      projectName: projectName ?? this.projectName,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      teamLeaderName: teamLeaderName ?? this.teamLeaderName,
      teamLeaderEmail: teamLeaderEmail ?? this.teamLeaderEmail,
      invitedMemberEmail: invitedMemberEmail ?? this.invitedMemberEmail,
      invitedMemberName: invitedMemberName ?? this.invitedMemberName,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      teamName: teamName ?? this.teamName,
      targetPlatform: targetPlatform ?? this.targetPlatform,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      isLeader: isLeader ?? this.isLeader,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
