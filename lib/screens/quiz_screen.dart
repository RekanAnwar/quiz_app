import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/app_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedOption;
  bool _isAnswered = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              final quiz = appProvider.currentQuiz;
              if (quiz == null) return const Text('Quiz');

              return Text(
                '${quiz.category} Quiz',
                style: const TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldExit = await _showExitConfirmationDialog();
              if (shouldExit && context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          actions: [
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showHelpDialog(),
                );
              },
            ),
          ],
        ),
        body: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            if (!appProvider.isQuizInProgress ||
                appProvider.currentQuestion == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No quiz in progress',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(appProvider),

                // Question content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildQuestionCard(appProvider),
                        const SizedBox(height: 24),
                        _buildOptionsCard(appProvider),
                        const SizedBox(height: 24),
                        if (_isAnswered) _buildExplanationCard(appProvider),
                      ],
                    ),
                  ),
                ),

                // Navigation controls
                _buildNavigationControls(appProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AppProvider appProvider) {
    final currentIndex = appProvider.currentQuestionIndex + 1;
    final totalQuestions = appProvider.totalQuestions;
    final progress = appProvider.quizProgress;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $currentIndex of $totalQuestions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AppProvider appProvider) {
    final question = appProvider.currentQuestion!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Question',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard(AppProvider appProvider) {
    final question = appProvider.currentQuestion!;
    final userAnswer =
        appProvider.userAnswers[appProvider.currentQuestionIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your answer:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected =
                  _selectedOption == index || userAnswer == index;
              final isCorrect = index == question.correctAnswerIndex;
              final showResult = _isAnswered || userAnswer != null;

              Color? backgroundColor;
              Color? textColor;
              IconData? iconData;

              if (showResult) {
                if (isCorrect) {
                  backgroundColor = Colors.green.withValues(alpha: 0.1);
                  textColor = Colors.green.shade700;
                  iconData = Icons.check_circle;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red.withValues(alpha: 0.1);
                  textColor = Colors.red.shade700;
                  iconData = Icons.cancel;
                }
              } else if (isSelected) {
                backgroundColor = Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1);
                textColor = Theme.of(context).primaryColor;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: userAnswer == null
                      ? () => _selectOption(index, appProvider)
                      : null,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultRadius,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? (showResult && isCorrect)
                                  ? Colors.green
                                  : (showResult && !isCorrect)
                                  ? Colors.red
                                  : Theme.of(context).primaryColor
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (showResult && isCorrect)
                                      ? Colors.green
                                      : (showResult && !isCorrect)
                                      ? Colors.red
                                      : Theme.of(context).primaryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: showResult && iconData != null
                              ? Icon(iconData, size: 16, color: Colors.white)
                              : isSelected
                              ? const Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(AppProvider appProvider) {
    final question = appProvider.currentQuestion!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Explanation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.explanation,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(AppProvider appProvider) {
    final canGoBack = appProvider.currentQuestionIndex > 0;
    final canGoNext =
        appProvider.currentQuestionIndex < appProvider.totalQuestions - 1;
    final isLastQuestion =
        appProvider.currentQuestionIndex == appProvider.totalQuestions - 1;
    final userAnswer =
        appProvider.userAnswers[appProvider.currentQuestionIndex];
    final hasAnswered = userAnswer != null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (canGoBack)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _selectedOption = appProvider
                        .userAnswers[appProvider.currentQuestionIndex - 1];
                    _isAnswered = _selectedOption != null;
                    appProvider.previousQuestion();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              ),
            if (canGoBack && (canGoNext || isLastQuestion))
              const SizedBox(width: 12),
            if (canGoNext)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasAnswered
                      ? () {
                          _selectedOption =
                              appProvider.userAnswers[appProvider
                                      .currentQuestionIndex +
                                  1];
                          _isAnswered = _selectedOption != null;
                          appProvider.nextQuestion();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ),
            if (isLastQuestion)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasAnswered
                      ? () => _completeQuiz(appProvider)
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Finish Quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectOption(int optionIndex, AppProvider appProvider) {
    setState(() {
      _selectedOption = optionIndex;
      _isAnswered = true;
    });

    appProvider.answerQuestion(optionIndex);
  }

  Future<void> _completeQuiz(AppProvider appProvider) async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Quiz'),
        content: const Text(
          'Are you sure you want to finish this quiz? You won\'t be able to change your answers after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    final ctx = context;

    if (shouldComplete == true && ctx.mounted) {
      await appProvider.completeQuiz();
      if (ctx.mounted) {
        Navigator.of(ctx).pushReplacementNamed('/quiz-result');
      }
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be saved and you can resume later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to take the quiz:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Select an answer by tapping on one of the options'),
            Text(
              '• After selecting, you\'ll see the correct answer and explanation',
            ),
            Text('• Use Previous/Next buttons to navigate between questions'),
            Text('• Complete all questions to finish the quiz'),
            Text('• Your progress is automatically saved'),
            SizedBox(height: 16),
            Text('Scoring:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• You need to answer correctly to pass'),
            Text('• Passing qualifies you for Web3 token rewards'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize state based on current question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      final userAnswer =
          appProvider.userAnswers[appProvider.currentQuestionIndex];

      setState(() {
        _selectedOption = userAnswer;
        _isAnswered = userAnswer != null;
      });
    });
  }
}
