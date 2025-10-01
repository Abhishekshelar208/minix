class TeamActivity {
  final String id;
  final String projectSpaceId;
  final String userId;
  final String userName;
  final String activityType; // 'member_joined', 'member_left', 'task_completed', 'step_completed', 'document_generated', etc.
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? iconName;
  final String? color;

  TeamActivity({
    required this.id,
    required this.projectSpaceId,
    required this.userId,
    required this.userName,
    required this.activityType,
    required this.description,
    required this.timestamp,
    this.metadata,
    this.iconName,
    this.color,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectSpaceId': projectSpaceId,
      'userId': userId,
      'userName': userName,
      'activityType': activityType,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata,
      'iconName': iconName,
      'color': color,
    };
  }

  // Create from Firebase JSON
  factory TeamActivity.fromJson(Map<String, dynamic> json) {
    return TeamActivity(
      id: json['id'] as String,
      projectSpaceId: json['projectSpaceId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      activityType: json['activityType'] as String,
      description: json['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      metadata: json['metadata'] as Map<String, dynamic>?,
      iconName: json['iconName'] as String?,
      color: json['color'] as String?,
    );
  }

  // Helper to get relative time
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
