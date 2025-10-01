/// Solution design tips to display while AI generates solutions
class SolutionTips {
  static const List<TipItem> tips = [
    TipItem(
      icon: '🎯',
      title: 'Think User-First',
      tip: 'Great solutions start with understanding user pain points',
      detail: 'Always prioritize solving real problems over adding features',
    ),
    TipItem(
      icon: '🏗️',
      title: 'Start Simple',
      tip: 'Build an MVP first, then iterate based on feedback',
      detail: 'Complex solutions often fail - simplicity wins',
    ),
    TipItem(
      icon: '⚡',
      title: 'Performance Matters',
      tip: 'Fast solutions feel more professional and reliable',
      detail: 'Users abandon slow apps within 3 seconds',
    ),
    TipItem(
      icon: '🔒',
      title: 'Security First',
      tip: 'Design with security in mind from day one',
      detail: 'It\'s harder and costlier to add security later',
    ),
    TipItem(
      icon: '📱',
      title: 'Mobile-First Design',
      tip: '80% of users will access your solution on mobile',
      detail: 'Design for small screens, scale up for desktop',
    ),
    TipItem(
      icon: '🎨',
      title: 'Consistency is Key',
      tip: 'Use consistent UI patterns throughout your solution',
      detail: 'Familiar patterns reduce cognitive load for users',
    ),
    TipItem(
      icon: '🔄',
      title: 'Plan for Scale',
      tip: 'Design solutions that can grow with your users',
      detail: 'Modular architecture makes scaling easier',
    ),
    TipItem(
      icon: '💡',
      title: 'Learn from Others',
      tip: 'Study successful apps in similar domains',
      detail: 'Don\'t reinvent the wheel - adapt proven solutions',
    ),
    TipItem(
      icon: '🧪',
      title: 'Test Early, Test Often',
      tip: 'Get user feedback on prototypes before building',
      detail: 'Early testing saves development time and cost',
    ),
    TipItem(
      icon: '📊',
      title: 'Data-Driven Decisions',
      tip: 'Plan how you\'ll measure solution success',
      detail: 'What gets measured gets improved',
    ),
    TipItem(
      icon: '🤝',
      title: 'Collaboration Wins',
      tip: 'Best solutions come from diverse perspectives',
      detail: 'Include team members in design discussions',
    ),
    TipItem(
      icon: '🌐',
      title: 'Think Offline-First',
      tip: 'Solutions should work even without internet',
      detail: 'Offline capability improves reliability and UX',
    ),
  ];

  /// Get a specific tip by index (with wrapping)
  static TipItem getTip(int index) {
    return tips[index % tips.length];
  }
  
  /// Get total number of tips
  static int get count => tips.length;
}

/// Represents a single solution design tip
class TipItem {
  final String icon;
  final String title;
  final String tip;
  final String detail;

  const TipItem({
    required this.icon,
    required this.title,
    required this.tip,
    required this.detail,
  });
}
