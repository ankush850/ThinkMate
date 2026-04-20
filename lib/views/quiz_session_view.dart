import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';

import '../services/ai_tutor_service.dart';
import '../services/document_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_option_card.dart';
import 'quiz_result_view.dart';

class QuizSessionView extends StatefulWidget {
  final String subject;
  final DocumentData? documentContext;

  const QuizSessionView({super.key, required this.subject, this.documentContext});

  @override
  State<QuizSessionView> createState() => _QuizSessionViewState();
}

class _QuizSessionViewState extends State<QuizSessionView> {
  static const int _totalQuestions = 10;

  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  String _currentDifficulty = 'medium';
  int _consecutiveCorrect = 0;
  int _consecutiveWrong = 0;

  QuizQuestion? _currentQuestion;
  bool _isLoading = true;
  bool _isRevealed = false;
  String? _selectedAnswer;
  String _rawResponse = '';

  final List<QuizSessionRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  void _adaptDifficulty() {
    if (_consecutiveCorrect >= 2) {
      if (_currentDifficulty == 'easy') {
        _currentDifficulty = 'medium';
      } else if (_currentDifficulty == 'medium') {
        _currentDifficulty = 'hard';
      }
      _consecutiveCorrect = 0;
    } else if (_consecutiveWrong >= 2) {
      if (_currentDifficulty == 'hard') {
        _currentDifficulty = 'medium';
      } else if (_currentDifficulty == 'medium') {
        _currentDifficulty = 'easy';
      }
      _consecutiveWrong = 0;
    }
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _currentQuestion = null;
      _isRevealed = false;
      _selectedAnswer = null;
      _rawResponse = '';
    });

    try {
      final previousTopics = _records.map((r) => r.question.question).join(', ');
      late final LLMStreamingResult streamResult;

      if (widget.documentContext != null) {
        // Document-based quiz: retrieve a chunk and generate from it
        final docService = context.read<DocumentService>();
        final chunk = docService.getRandomChunk(document: widget.documentContext);
        streamResult = await AiTutorService.generateQuizFromDocument(
          documentChunk: chunk,
          difficulty: _currentDifficulty,
          previousContext: previousTopics.isNotEmpty ? previousTopics : null,
        );
      } else {
        streamResult = await AiTutorService.generateQuizQuestion(
          subject: widget.subject,
          difficulty: _currentDifficulty,
          previousContext: previousTopics.isNotEmpty ? previousTopics : null,
        );
      }

      await for (final token in streamResult.stream) {
        _rawResponse += token;
      }

      // Debug: print raw LLM output to help diagnose parsing issues
      debugPrint('Quiz raw response: $_rawResponse');

      final parsed = AiTutorService.parseQuizQuestion(_rawResponse);

      if (mounted) {
        setState(() {
          if (parsed != null) {
            _currentQuestion = parsed;
          } else {
            // Show raw AI response as a question so user sees what was generated
            _currentQuestion = QuizQuestion(
              question: _rawResponse.isNotEmpty
                  ? _rawResponse
                  : 'AI could not generate a question. Please try again.',
              options: {'A': 'Try Again'},
              correctAnswer: 'A',
              explanation: 'The AI response could not be parsed into a proper quiz format. Tap "Next" to generate another question.',
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Quiz generation error: $e');
      if (mounted) {
        setState(() {
          _currentQuestion = QuizQuestion(
            question: 'Failed to generate question: $e',
            options: {'A': 'Retry'},
            correctAnswer: 'A',
            explanation: 'An error occurred. Tap "Next" to try again.',
          );
          _isLoading = false;
        });
      }
    }
  }



  void _selectAnswer(String answer) {
    if (_isRevealed || _currentQuestion == null) return;

    setState(() {
      _selectedAnswer = answer;
      _isRevealed = true;
    });

    final isCorrect = answer == _currentQuestion!.correctAnswer;
    if (isCorrect) {
      _correctCount++;
      _consecutiveCorrect++;
      _consecutiveWrong = 0;
    } else {
      _consecutiveWrong++;
      _consecutiveCorrect = 0;
    }

    _records.add(QuizSessionRecord(
      question: _currentQuestion!,
      selectedAnswer: answer,
      isCorrect: isCorrect,
    ));

    _adaptDifficulty();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex + 1 >= _totalQuestions) {
      _finishQuiz();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
    });
    _loadNextQuestion();
  }

  void _finishQuiz() {
    final progress = context.read<ProgressService>();
    progress.recordQuizResult(
      subject: widget.subject,
      correct: _correctCount,
      total: _totalQuestions,
      difficulty: _currentDifficulty,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizResultView(
          subject: widget.subject,
          records: _records,
          correct: _correctCount,
          total: _totalQuestions,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(widget.subject),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _difficultyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentDifficulty.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _difficultyColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _currentQuestion != null
                    ? _buildQuestionCard()
                    : _buildErrorState(),
          ),
          if (_isRevealed) _buildNextButton(),
        ],
      ),
    );
  }

  Color get _difficultyColor {
    switch (_currentDifficulty) {
      case 'easy':
        return AppColors.accentGreen;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.accentOrange;
    }
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/$_totalQuestions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentCyan,
                    ),
              ),
              Text(
                '$_correctCount correct',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentGreen,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
              backgroundColor: AppColors.surfaceCard,
              color: AppColors.accentCyan,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.accentCyan,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating question...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'AI is crafting a $_currentDifficulty question',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to generate question', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNextQuestion,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final q = _currentQuestion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.accentCyan.withOpacity(0.2),
              ),
            ),
            child: Text(
              q.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    height: 1.4,
                  ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
          const SizedBox(height: 20),
          ...['A', 'B', 'C', 'D'].map((label) {
            if (!q.options.containsKey(label)) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuizOptionCard(
                label: label,
                text: q.options[label]!,
                isSelected: _selectedAnswer == label,
                isCorrect: label == q.correctAnswer ? true : (_selectedAnswer == label ? false : null),
                isRevealed: _isRevealed,
                onTap: () => _selectAnswer(label),
              ),
            );
          }),
          if (_isRevealed) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentViolet.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.accentViolet, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.accentViolet,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentQuestionIndex + 1 >= _totalQuestions;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.8),
        border: Border(top: BorderSide(color: AppColors.textMuted.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: _nextQuestion,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLast
                    ? [AppColors.accentGreen, const Color(0xFF059669)]
                    : [AppColors.accentCyan, const Color(0xFF0EA5E9)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (isLast ? AppColors.accentGreen : AppColors.accentCyan).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isLast ? 'See Results' : 'Next Question',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class QuizSessionRecord {
  final QuizQuestion question;
  final String selectedAnswer;
  final bool isCorrect;

  const QuizSessionRecord({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
  });
}
