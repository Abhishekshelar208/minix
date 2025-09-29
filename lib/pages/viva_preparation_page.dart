import 'package:flutter/material.dart';
import '../models/viva_question.dart';
import '../models/mock_viva_session.dart';
import '../models/presentation_tip.dart';
import '../models/solution.dart';
import '../models/project_roadmap.dart';
import '../services/viva_service.dart';
import 'mock_viva_session_page.dart';

class VivaPreparationPage extends StatefulWidget {
  final String projectId;
  final ProjectSolution solution;
  final ProjectRoadmap roadmap;

  const VivaPreparationPage({
    super.key,
    required this.projectId,
    required this.solution,
    required this.roadmap,
  });

  @override
  State<VivaPreparationPage> createState() => _VivaPreparationPageState();
}

class _VivaPreparationPageState extends State<VivaPreparationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final VivaService _vivaService = VivaService();

  List<VivaQuestion> _generatedQuestions = [];
  List<MockVivaSession> _mockSessions = [];
  bool _isGeneratingQuestions = false;
  bool _isLoadingTips = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _vivaService.initialize();
    _loadExistingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    setState(() {
      _mockSessions = _vivaService.getSessionsForProject(widget.projectId);
    });
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isGeneratingQuestions = true;
    });

    try {
      final questions = await _vivaService.generateProjectSpecificQuestions(
        solution: widget.solution,
        roadmap: widget.roadmap,
        count: 20,
      );

      setState(() {
        _generatedQuestions = questions;
        _isGeneratingQuestions = false;
      });

      _vivaService.addQuestionsToBank(questions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${questions.length} viva questions successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingQuestions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate questions. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viva Preparation'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Questions'),
            Tab(icon: Icon(Icons.library_books), text: 'Practice'),
            Tab(icon: Icon(Icons.play_circle), text: 'Mock Viva'),
            Tab(icon: Icon(Icons.tips_and_updates), text: 'Tips'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionGenerationTab(),
          _buildPracticeTab(),
          _buildMockVivaTab(),
          _buildTipsTab(),
        ],
      ),
    );
  }

  Widget _buildQuestionGenerationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Question Generation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate personalized viva questions based on your project details, technologies used, and implementation approach.',
                  ),
                  const SizedBox(height: 16),
                  if (_isGeneratingQuestions)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Generating questions...'),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generateQuestions,
                        icon: const Icon(Icons.refresh),
                        label: Text(_generatedQuestions.isEmpty
                            ? 'Generate Questions'
                            : 'Regenerate Questions'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_generatedQuestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Generated Questions (${_generatedQuestions.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildCategoryDistribution(),
            const SizedBox(height: 16),
            ...(_generatedQuestions.map((question) => _buildQuestionCard(question))),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final distribution = <VivaQuestionCategory, int>{};
    for (final question in _generatedQuestions) {
      distribution[question.category] = (distribution[question.category] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question Distribution',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: distribution.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key.displayName}: ${entry.value}'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(VivaQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(
          question.question,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(question.category.displayName),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(question.difficulty.displayName),
                  backgroundColor: _getDifficultyColor(question.difficulty),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  '⏱️ ${question.estimatedTimeMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.context != null) ...[
                  Text(
                    'Context:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(question.context!),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Suggested Answer:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(question.suggestedAnswer),
                if (question.keywords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Keywords:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4.0,
                    children: question.keywords.map((keyword) {
                      return Chip(
                        label: Text(keyword),
                        backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
                if (question.followUpQuestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Follow-up Questions:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...question.followUpQuestions.map((followUp) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Text('• $followUp'),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green.withValues(alpha: 0.3);
      case DifficultyLevel.medium:
        return Colors.orange.withValues(alpha: 0.3);
      case DifficultyLevel.hard:
        return Colors.red.withValues(alpha: 0.3);
      case DifficultyLevel.expert:
        return Colors.purple.withValues(alpha: 0.3);
    }
  }

  Widget _buildPracticeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Practice Question Bank',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse and practice with categorized questions. Review suggested answers and improve your understanding.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryFilter(),
          const SizedBox(height: 16),
          if (_generatedQuestions.isNotEmpty)
            _buildPracticeQuestions()
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Questions Yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Generate questions first to start practicing',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(0),
                        child: const Text('Generate Questions'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: VivaQuestionCategory.values.map((category) {
                final count = _generatedQuestions.where((q) => q.category == category).length;
                return FilterChip(
                  label: Text('${category.displayName} ($count)'),
                  selected: false, // TODO: Implement filter state
                  onSelected: (selected) {
                    // TODO: Implement filtering
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeQuestions() {
    return Column(
      children: _generatedQuestions.map((question) => _buildPracticeQuestionCard(question)).toList(),
    );
  }

  Widget _buildPracticeQuestionCard(VivaQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question.question,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(question.difficulty.displayName),
                  backgroundColor: _getDifficultyColor(question.difficulty),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Type your answer here...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 3,
              onChanged: (value) {
                // TODO: Save answer for later review
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showSuggestedAnswer(question),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Show Answer'),
                ),
                const SizedBox(width: 8),
                if (question.keywords.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showKeywords(question),
                    icon: const Icon(Icons.key),
                    label: const Text('Show Keywords'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuggestedAnswer(VivaQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested Answer'),
        content: SingleChildScrollView(
          child: Text(question.suggestedAnswer),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showKeywords(VivaQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keywords'),
        content: Wrap(
          spacing: 4.0,
          children: question.keywords.map((keyword) {
            return Chip(label: Text(keyword));
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMockVivaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mock Viva Simulation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Practice with timed mock viva sessions. Get feedback on your performance and track your progress.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generatedQuestions.isNotEmpty ? _startNewMockViva : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Start New Mock Viva'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_mockSessions.isNotEmpty) ...[
            Text(
              'Previous Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._mockSessions.map((session) => _buildMockSessionCard(session)),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Mock Sessions Yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start your first mock viva to practice',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMockSessionCard(MockVivaSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(session.sessionName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${session.status.displayName}'),
            if (session.isCompleted) ...[
              Text('Score: ${session.overallScore?.toStringAsFixed(1) ?? 'N/A'}%'),
              Text('Duration: ${session.duration.inMinutes} minutes'),
            ],
          ],
        ),
        trailing: Icon(
          session.isCompleted ? Icons.check_circle : Icons.play_circle_outline,
          color: session.isCompleted ? Colors.green : null,
        ),
        onTap: () {
          if (session.isCompleted) {
            _viewSessionResults(session);
          } else {
            _resumeMockViva(session);
          }
        },
      ),
    );
  }

  void _startNewMockViva() {
    showDialog(
      context: context,
      builder: (context) => _MockVivaSettingsDialog(
        onStart: (settings) {
          final session = _vivaService.createMockVivaSession(
            projectId: widget.projectId,
            sessionName: 'Mock Viva ${DateTime.now().day}/${DateTime.now().month}',
            settings: settings,
          );
          Navigator.of(context).pop();
          _navigateToMockViva(session);
        },
      ),
    );
  }

  void _navigateToMockViva(MockVivaSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MockVivaSessionPage(
          session: session,
          vivaService: _vivaService,
        ),
      ),
    ).then((_) => _loadExistingData());
  }

  void _resumeMockViva(MockVivaSession session) {
    _navigateToMockViva(session);
  }

  void _viewSessionResults(MockVivaSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MockVivaResultsPage(session: session),
      ),
    );
  }

  Widget _buildTipsTab() {
    final guide = _vivaService.getVivaPreparationGuide();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        guide.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(guide.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickTips(guide.quickTips),
          const SizedBox(height: 16),
          _buildCommonMistakes(guide.commonMistakes),
          const SizedBox(height: 16),
          _buildPreparationChecklist(guide.preparationChecklist),
          const SizedBox(height: 16),
          _buildPresentationTips(),
        ],
      ),
    );
  }

  Widget _buildQuickTips(Map<String, String> quickTips) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Quick Tips',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...quickTips.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonMistakes(List<String> mistakes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Common Mistakes to Avoid',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...mistakes.map((mistake) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(mistake)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparationChecklist(List<String> checklist) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Preparation Checklist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...checklist.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: false, // TODO: Implement checklist state
                        onChanged: (value) {
                          // TODO: Save checklist state
                        },
                      ),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentationTips() {
    final tips = _vivaService.getPresentationTips();
    final categories = PresentationTipCategory.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Presentation Tips',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...categories.map((category) {
          final categoryTips = tips.where((tip) => tip.category == category).toList();
          if (categoryTips.isEmpty) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ExpansionTile(
              title: Row(
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(category.displayName),
                ],
              ),
              subtitle: Text(category.description),
              children: categoryTips
                  .map((tip) => _buildTipCard(tip))
                  .toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTipCard(PresentationTip tip) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(tip.description),
          if (tip.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Key Points:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            ...tip.keyPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
                  child: Text('• $point'),
                )),
          ],
          if (tip.dosList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Do:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 4),
            ...tip.dosList.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
          ],
          if (tip.dontsList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Don\'t:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 4),
            ...tip.dontsList.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _MockVivaSettingsDialog extends StatefulWidget {
  final Function(MockVivaSettings) onStart;

  const _MockVivaSettingsDialog({required this.onStart});

  @override
  State<_MockVivaSettingsDialog> createState() => _MockVivaSettingsDialogState();
}

class _MockVivaSettingsDialogState extends State<_MockVivaSettingsDialog> {
  int _totalQuestions = 10;
  int _timePerQuestion = 3;
  final Set<VivaQuestionCategory> _selectedCategories = {};
  final Set<DifficultyLevel> _selectedDifficulties = {};
  bool _allowSkipping = true;
  bool _showHints = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mock Viva Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number of Questions: $_totalQuestions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _totalQuestions.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              onChanged: (value) => setState(() => _totalQuestions = value.round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Time per Question: $_timePerQuestion minutes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _timePerQuestion.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (value) => setState(() => _timePerQuestion = value.round()),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow Skipping'),
              value: _allowSkipping,
              onChanged: (value) => setState(() => _allowSkipping = value),
            ),
            SwitchListTile(
              title: const Text('Show Hints'),
              value: _showHints,
              onChanged: (value) => setState(() => _showHints = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final settings = MockVivaSettings(
              totalQuestions: _totalQuestions,
              timePerQuestionMinutes: _timePerQuestion,
              categories: _selectedCategories.toList(),
              difficulties: _selectedDifficulties.toList(),
              allowSkipping: _allowSkipping,
              showHints: _showHints,
            );
            widget.onStart(settings);
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}

// MockVivaResultsPage is implemented in mock_viva_session_page.dart
