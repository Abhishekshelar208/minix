/// Domain-specific facts to display during AI topic generation
class DomainFacts {
  static const Map<String, List<FactItem>> facts = {
    'College': [
      FactItem(
        icon: '🎓',
        text: '73% of colleges worldwide still use manual attendance systems',
        subtext: 'Digital solutions can save 5+ hours per week for students',
      ),
      FactItem(
        icon: '📚',
        text: 'Students spend an average of 15 hours per week on administrative tasks',
        subtext: 'Smart campus apps can reduce this by up to 60%',
      ),
      FactItem(
        icon: '🏫',
        text: 'Over 50% of college apps fail due to poor user experience',
        subtext: 'Students prefer simple, intuitive interfaces',
      ),
      FactItem(
        icon: '💡',
        text: 'Campus notification systems increase event attendance by 40%',
        subtext: 'Real-time alerts keep students engaged',
      ),
      FactItem(
        icon: '📱',
        text: '89% of students check their phones within 15 minutes of waking up',
        subtext: 'Mobile-first design is essential for campus apps',
      ),
      FactItem(
        icon: '🔔',
        text: 'Digital grade tracking reduces student anxiety by 35%',
        subtext: 'Transparency builds trust in academic systems',
      ),
    ],
    'Hospital': [
      FactItem(
        icon: '🏥',
        text: 'Digital patient portals reduce hospital wait times by 25%',
        subtext: 'Online check-ins streamline healthcare delivery',
      ),
      FactItem(
        icon: '⚕️',
        text: 'Healthcare apps can prevent 40% of missed appointments',
        subtext: 'Automated reminders save time and money',
      ),
      FactItem(
        icon: '📊',
        text: 'Electronic health records reduce medical errors by 30%',
        subtext: 'Digital systems improve patient safety',
      ),
      FactItem(
        icon: '💉',
        text: '75% of patients prefer scheduling appointments online',
        subtext: 'Convenience drives healthcare engagement',
      ),
      FactItem(
        icon: '🚑',
        text: 'Emergency response apps can save 3-5 minutes per incident',
        subtext: 'Every second counts in critical care',
      ),
      FactItem(
        icon: '💊',
        text: 'Medication reminder apps improve compliance by 60%',
        subtext: 'Technology helps patients stay on track',
      ),
    ],
    'Parking': [
      FactItem(
        icon: '🚗',
        text: 'Drivers spend an average of 17 hours per year searching for parking',
        subtext: 'Smart parking apps can reduce this by 80%',
      ),
      FactItem(
        icon: '🅿️',
        text: '30% of urban traffic is caused by people looking for parking',
        subtext: 'Digital solutions ease congestion',
      ),
      FactItem(
        icon: '💰',
        text: 'Smart parking systems increase revenue by 25%',
        subtext: 'Efficiency benefits both users and operators',
      ),
      FactItem(
        icon: '🌍',
        text: 'Reducing parking search time cuts CO2 emissions by 40%',
        subtext: 'Smart parking is eco-friendly',
      ),
      FactItem(
        icon: '📍',
        text: 'Real-time parking availability reduces driver frustration by 70%',
        subtext: 'Information empowers better decisions',
      ),
      FactItem(
        icon: '⚡',
        text: 'EV charging station finders increase electric vehicle adoption',
        subtext: 'Infrastructure visibility drives sustainability',
      ),
    ],
    'Library': [
      FactItem(
        icon: '📖',
        text: 'Digital library catalogs increase book discovery by 50%',
        subtext: 'Easy search means more readers',
      ),
      FactItem(
        icon: '📚',
        text: '67% of library users prefer mobile apps for book reservations',
        subtext: 'Convenience drives engagement',
      ),
      FactItem(
        icon: '⏰',
        text: 'Automated due date reminders reduce overdue books by 45%',
        subtext: 'Gentle nudges help everyone',
      ),
      FactItem(
        icon: '🎯',
        text: 'Personalized reading recommendations boost circulation by 35%',
        subtext: 'AI helps match readers with perfect books',
      ),
      FactItem(
        icon: '📱',
        text: 'E-book lending grew by 300% in the last 5 years',
        subtext: 'Digital and physical libraries complement each other',
      ),
      FactItem(
        icon: '🌐',
        text: 'Virtual library tours increase new member sign-ups by 40%',
        subtext: 'Digital doors welcome more visitors',
      ),
    ],
    'Hotels': [
      FactItem(
        icon: '🏨',
        text: '73% of travelers book hotels through mobile devices',
        subtext: 'Mobile-first design is crucial for hospitality',
      ),
      FactItem(
        icon: '⭐',
        text: 'Hotels with digital check-in see 40% higher guest satisfaction',
        subtext: 'Skip the front desk, boost happiness',
      ),
      FactItem(
        icon: '🔑',
        text: 'Mobile room keys reduce check-in time by 75%',
        subtext: 'Your phone is the new key card',
      ),
      FactItem(
        icon: '💬',
        text: 'In-app guest services increase revenue by 25%',
        subtext: 'Easy ordering means more orders',
      ),
      FactItem(
        icon: '🌟',
        text: 'Personalized guest experiences boost repeat bookings by 50%',
        subtext: 'Remember preferences, earn loyalty',
      ),
      FactItem(
        icon: '🛎️',
        text: 'Smart hotel apps reduce staff response time by 60%',
        subtext: 'Efficiency improves service quality',
      ),
    ],
    'Cafés': [
      FactItem(
        icon: '☕',
        text: '65% of café customers prefer ordering ahead via app',
        subtext: 'Skip the line, save time',
      ),
      FactItem(
        icon: '📱',
        text: 'Digital menus increase order values by 30%',
        subtext: 'Visual appeal drives purchases',
      ),
      FactItem(
        icon: '🎁',
        text: 'Loyalty programs through apps boost customer retention by 55%',
        subtext: 'Rewards keep customers coming back',
      ),
      FactItem(
        icon: '⏱️',
        text: 'Mobile ordering reduces wait times by 40%',
        subtext: 'Speed improves customer experience',
      ),
      FactItem(
        icon: '💳',
        text: 'Contactless payments are preferred by 80% of customers',
        subtext: 'Quick, secure, and hygienic',
      ),
      FactItem(
        icon: '🍰',
        text: 'Push notifications increase daily visits by 20%',
        subtext: 'Timely alerts drive foot traffic',
      ),
    ],
    'E-commerce': [
      FactItem(
        icon: '🛒',
        text: 'Mobile commerce accounts for 73% of all e-commerce sales',
        subtext: 'Mobile-first is no longer optional',
      ),
      FactItem(
        icon: '💎',
        text: 'Product recommendations drive 35% of Amazon\'s revenue',
        subtext: 'Smart algorithms increase sales',
      ),
      FactItem(
        icon: '📦',
        text: 'Real-time order tracking reduces support tickets by 40%',
        subtext: 'Transparency builds customer trust',
      ),
      FactItem(
        icon: '⚡',
        text: 'One-click checkout increases conversion rates by 28%',
        subtext: 'Fewer steps mean more sales',
      ),
      FactItem(
        icon: '🔔',
        text: 'Abandoned cart reminders recover 15% of lost sales',
        subtext: 'Gentle nudges bring customers back',
      ),
      FactItem(
        icon: '🌟',
        text: '90% of shoppers read reviews before purchasing',
        subtext: 'Social proof drives buying decisions',
      ),
    ],
    'Govt Services': [
      FactItem(
        icon: '🏛️',
        text: 'Digital government services reduce processing time by 60%',
        subtext: 'Technology speeds up bureaucracy',
      ),
      FactItem(
        icon: '📋',
        text: 'Online portals cut government costs by 40%',
        subtext: 'Digital efficiency saves taxpayer money',
      ),
      FactItem(
        icon: '✅',
        text: '85% of citizens prefer online government services',
        subtext: 'Convenience increases engagement',
      ),
      FactItem(
        icon: '🔒',
        text: 'Digital identity systems reduce fraud by 50%',
        subtext: 'Security improves with technology',
      ),
      FactItem(
        icon: '📱',
        text: 'Mobile government apps increase service accessibility by 70%',
        subtext: 'Reach more citizens, anytime, anywhere',
      ),
      FactItem(
        icon: '🌐',
        text: 'E-governance improves transparency and accountability',
        subtext: 'Digital trails build public trust',
      ),
    ],
  };

  /// Get facts for a specific domain
  static List<FactItem> getFactsForDomain(String domain) {
    // Handle custom domains by returning general tech facts
    if (!facts.containsKey(domain)) {
      return _customDomainFacts;
    }
    
    return facts[domain]!;
  }
  
  /// General project development tips for custom domains
  static const List<FactItem> _customDomainFacts = [
    FactItem(
      icon: '💡',
      text: 'Start with the problem, not the solution',
      subtext: 'Understanding user pain points leads to better features',
    ),
    FactItem(
      icon: '🎯',
      text: 'Break complex problems into smaller, manageable tasks',
      subtext: 'Divide and conquer makes coding less overwhelming',
    ),
    FactItem(
      icon: '📝',
      text: 'Write pseudocode before actual code',
      subtext: 'Planning logic on paper saves debugging time later',
    ),
    FactItem(
      icon: '🔄',
      text: 'Use the CRUD pattern: Create, Read, Update, Delete',
      subtext: 'Most apps are just smart ways to manage data',
    ),
    FactItem(
      icon: '🧪',
      text: 'Test early, test often—don\'t wait until the end',
      subtext: 'Small bugs caught early prevent big disasters later',
    ),
    FactItem(
      icon: '🎨',
      text: 'UI/UX matters more than you think',
      subtext: 'A beautiful app with basic features beats an ugly app with many',
    ),
    FactItem(
      icon: '📚',
      text: 'Don\'t reinvent the wheel—use libraries and packages',
      subtext: 'Standing on giants\' shoulders accelerates development',
    ),
    FactItem(
      icon: '🐛',
      text: 'Debugging is twice as hard as writing code',
      subtext: 'Write simple, readable code your future self will thank you for',
    ),
    FactItem(
      icon: '⚡',
      text: 'MVP (Minimum Viable Product) is your best friend',
      subtext: 'Launch with core features, add extras based on feedback',
    ),
    FactItem(
      icon: '🔐',
      text: 'Always validate user input—never trust it blindly',
      subtext: 'Security starts with basic input validation',
    ),
    FactItem(
      icon: '💾',
      text: 'Save user data locally before syncing to cloud',
      subtext: 'Offline-first apps provide better user experience',
    ),
    FactItem(
      icon: '🚀',
      text: 'Performance matters: optimize images and lazy-load data',
      subtext: 'Fast apps feel more professional and reliable',
    ),
    FactItem(
      icon: '🤝',
      text: 'Code reviews and pair programming catch 60% more bugs',
      subtext: 'Two pairs of eyes are better than one',
    ),
    FactItem(
      icon: '📱',
      text: 'Mobile-first design works everywhere',
      subtext: 'It\'s easier to scale up than scale down',
    ),
    FactItem(
      icon: '🎓',
      text: 'Every expert was once a beginner—embrace the learning',
      subtext: 'Stack Overflow is your friend, but understand the code',
    ),
  ];
}

/// Represents a single fact with icon and text
class FactItem {
  final String icon;
  final String text;
  final String subtext;

  const FactItem({
    required this.icon,
    required this.text,
    required this.subtext,
  });
}
