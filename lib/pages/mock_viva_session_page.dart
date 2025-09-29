import 'dart:async';
import 'package:flutter/material.dart';
import '../models/viva_question.dart';
import '../models/mock_viva_session.dart';
import '../services/viva_service.dart';

class MockVivaSessionPage extends StatefulWidget {
  final MockVivaSession session;
  final VivaService vivaService;

  const MockVivaSessionPage({
    super.key,
    required this.session,
    required this.vivaService,
  });

  @override
  State<MockVivaSessionPage> createState() => _MockVivaSessionPageState();
}

class _MockVivaSessionPageState extends State<MockVivaSessionPage> {
  late MockVivaSession _currentSession;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _timeLeft = 0;
  final TextEditingController _answerController = TextEditingController();
  bool _isAnswerSubmitted = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    
    // Start the session if it's not started
    if (_currentSession.status == VivaSessionStatus.notStarted) {
      _currentSession = widget.vivaService.startMockViva(_currentSession.id);
    }
    
    _initializeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _initializeTimer() {
    _timeLeft = _currentSession.settings.timePerQuestionMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (!_isAnswerSubmitted) {
      _submitCurrentAnswer(timeUp: true);
    }
  }

  void _submitCurrentAnswer({bool timeUp = false, bool skipped = false}) {
    final currentAttempt = _currentSession.questionAttempts[_currentQuestionIndex];
    
    _currentSession = widget.vivaService.updateQuestionAttempt(
      sessionId: _currentSession.id,
      questionId: currentAttempt.questionId,
      userAnswer: skipped ? null : _answerController.text,
      skipped: skipped,
    );

    setState(() {
      _isAnswerSubmitted = true;
    });

    if (timeUp || skipped) {
      Future.delayed(const Duration(seconds: 2), () {
        _moveToNextQuestion();
      });
    }
  }

  void _moveToNextQuestion() {
    if (_currentQuestionIndex < _currentSession.questionAttempts.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.clear();
        _isAnswerSubmitted = false;
        _showHint = false;
      });
      _initializeTimer();
    } else {
      _completeSession();
    }
  }

  void _completeSession() {
    _timer?.cancel();
    _currentSession = widget.vivaService.completeMockViva(_currentSession.id);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MockVivaResultsPage(session: _currentSession),
      ),
    );
  }

  void _skipQuestion() {
    if (_currentSession.settings.allowSkipping) {
      _submitCurrentAnswer(skipped: true);
    }
  }

  void _showHintDialog() {
    if (_currentSession.settings.showHints) {
      final currentQuestion = _currentSession.questionAttempts[_currentQuestionIndex].question;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.keywords.isNotEmpty) ...[
                const Text('Keywords to consider:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4.0,
                  children: currentQuestion.keywords.take(3).map((keyword) {
                    return Chip(
                      label: Text(keyword),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    );
                  }).toList(),
                ),
              ] else ...[
                Text('Focus on: ${currentQuestion.category.displayName}'),
                const SizedBox(height: 8),
                Text('Estimated time: ${currentQuestion.estimatedTimeMinutes} minutes'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showHint = true;
                });
              },
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final totalTime = _currentSession.settings.timePerQuestionMinutes * 60;
    final timeRatio = _timeLeft / totalTime;
    
    if (timeRatio > 0.5) {
      return Colors.green;
    } else if (timeRatio > 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSession.questionAttempts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_currentSession.sessionName)),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentAttempt = _currentSession.questionAttempts[_currentQuestionIndex];
    final currentQuestion = currentAttempt.question;
    final progress = (_currentQuestionIndex + 1) / _currentSession.questionAttempts.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Mock Viva?'),
            content: const Text('Your progress will be saved, but you won\'t get a final score until you complete all questions.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        
        if (result == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentSession.sessionName),
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: Column(
          children: [
            // Timer and progress header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_currentSession.questionAttempts.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: _getTimerColor(),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_timeLeft),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text(currentQuestion.category.displayName),
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(currentQuestion.difficulty.displayName),
                                  backgroundColor: _getDifficultyColor(currentQuestion.difficulty),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentQuestion.question,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (currentQuestion.context != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Context:',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(currentQuestion.context!),
                                  ],
                                ),
                              ),
                            ],
                            if (_showHint && currentQuestion.keywords.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb, color: Colors.amber[700], size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Hint: Consider these keywords',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4.0,
                                      children: currentQuestion.keywords.take(3).map((keyword) {
                                        return Chip(
                                          label: Text(keyword),
                                          backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Answer section
                    if (!_isAnswerSubmitted) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Answer:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _answerController,
                                decoration: const InputDecoration(
                                  hintText: 'Type your answer here...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(12),
                                ),
                                maxLines: 6,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (_currentSession.settings.showHints && !_showHint)
                                    TextButton.icon(
                                      onPressed: _showHintDialog,
                                      icon: const Icon(Icons.lightbulb_outline),
                                      label: const Text('Show Hint'),
                                    ),
                                  if (_currentSession.settings.allowSkipping) ...[
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: _skipQuestion,
                                      icon: const Icon(Icons.skip_next),
                                      label: const Text('Skip'),
                                    ),
                                  ],
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: _answerController.text.isNotEmpty
                                        ? () => _submitCurrentAnswer()
                                        : null,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Submit Answer'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Answer submitted - show feedback
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Answer Submitted',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (currentAttempt.userAnswer != null) ...[
                                Text(
                                  'Your answer:',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(currentAttempt.userAnswer!),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Question was skipped'),
                                ),
                              ],
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _moveToNextQuestion,
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(_currentQuestionIndex < _currentSession.questionAttempts.length - 1
                                    ? 'Next Question'
                                    : 'Complete Session'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
}

class MockVivaResultsPage extends StatelessWidget {
  final MockVivaSession session;

  const MockVivaResultsPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final answeredCount = session.questionAttempts.where((a) => a.isAnswered).length;
    final skippedCount = session.questionAttempts.where((a) => a.skipped).length;
    final totalQuestions = session.questionAttempts.length;
    final completionRate = (answeredCount / totalQuestions * 100).round();
    final averageScore = session.averageScore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Viva Results'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall results card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: _getScoreColor(averageScore),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session Completed!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.sessionName,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          '${averageScore.toStringAsFixed(1)}%',
                          'Overall Score',
                          Icons.star,
                          _getScoreColor(averageScore),
                        ),
                        _buildStatItem(
                          context,
                          '$completionRate%',
                          'Completion',
                          Icons.task_alt,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          context,
                          '${session.duration.inMinutes}m',
                          'Duration',
                          Icons.timer,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detailed breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Breakdown',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildBreakdownRow(context, 'Questions Answered', '$answeredCount/$totalQuestions', Icons.quiz),
                    _buildBreakdownRow(context, 'Questions Skipped', '$skippedCount', Icons.skip_next),
                    _buildBreakdownRow(context, 'Average Time per Question', 
                        '${(session.duration.inSeconds / totalQuestions / 60).toStringAsFixed(1)} min', Icons.schedule),
                    _buildBreakdownRow(context, 'Session Duration', 
                        '${session.duration.inMinutes}:${(session.duration.inSeconds % 60).toString().padLeft(2, '0')}', Icons.access_time),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Performance feedback
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Feedback',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.feedback ?? 'No feedback available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Question-wise results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question-wise Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...session.questionAttempts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final attempt = entry.value;
                      return _buildQuestionResultCard(context, index + 1, attempt);
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => MockVivaSessionPage(
                          session: MockVivaSession(
                            id: 'retry_${DateTime.now().millisecondsSinceEpoch}',
                            projectId: session.projectId,
                            sessionName: 'Retry - ${session.sessionName}',
                            startTime: DateTime.now(),
                            questionAttempts: [],
                            settings: session.settings,
                            status: VivaSessionStatus.notStarted,
                          ),
                          vivaService: VivaService(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil(
                      ModalRoute.withName('/viva_preparation'),
                    ),
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Viva Prep'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResultCard(BuildContext context, int questionNumber, VivaQuestionAttempt attempt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text('Question $questionNumber'),
        subtitle: Text(attempt.question.question),
        leading: CircleAvatar(
          backgroundColor: attempt.skipped 
              ? Colors.orange.withValues(alpha: 0.2)
              : attempt.isAnswered
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
          child: Icon(
            attempt.skipped
                ? Icons.skip_next
                : attempt.isAnswered
                    ? Icons.check
                    : Icons.help_outline,
            color: attempt.skipped
                ? Colors.orange
                : attempt.isAnswered
                    ? Colors.green
                    : Colors.grey,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attempt.userAnswer != null) ...[
                  Text(
                    'Your Answer:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(attempt.userAnswer!),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Suggested Answer:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(attempt.question.suggestedAnswer),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time Spent: ${attempt.timeSpent.inSeconds > 0 ? '${(attempt.timeSpent.inSeconds / 60).toStringAsFixed(1)} minutes' : 'N/A'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) {
      return Colors.green;
    } else if (score >= 70) {
      return Colors.blue;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}