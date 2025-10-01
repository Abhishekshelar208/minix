/// Tips to display while AI enhances problem details
class EnhancementTips {
  static const List<String> tips = [
    '🔍 Analyzing real-world use cases...',
    '💡 Generating detailed features list...',
    '🎯 Identifying implementation challenges...',
    '📚 Crafting learning outcomes...',
    '🚀 Suggesting technical approaches...',
    '✨ Adding industry best practices...',
    '🏗️ Structuring step-by-step guide...',
    '🎨 Recommending UI/UX patterns...',
  ];
  
  /// Get a random tip
  static String getRandomTip() {
    return tips[DateTime.now().millisecondsSinceEpoch % tips.length];
  }
}
