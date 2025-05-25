import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/app_provider.dart';

class QuizCategoryScreen extends StatelessWidget {
  const QuizCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Categories'), centerTitle: true),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choose Your Quiz Category',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete quizzes to earn ${AppConstants.tokenRewardAmount.toInt()} tokens. You need ${AppConstants.passingScore}/${AppConstants.questionsPerQuiz} correct answers to pass.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Wallet Status
                if (!appProvider.isWalletConnected) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wallet Not Connected',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                ),
                                Text(
                                  'Connect your wallet to start taking quizzes and earning tokens.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed('/wallet-connect');
                            },
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Categories Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: AppConstants.quizCategories.length,
                  itemBuilder: (context, index) {
                    final category = AppConstants.quizCategories[index];
                    return _CategoryCard(
                      category: category,
                      appProvider: appProvider,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // API Key Status
                if (!appProvider.hasApiKey) ...[
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.key,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Using Mock Questions',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add an OpenAI API key in settings to get AI-generated questions.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/settings');
                            },
                            child: const Text('Go to Settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final AppProvider appProvider;

  const _CategoryCard({required this.category, required this.appProvider});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'blockchain':
        return Icons.link;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'technology':
        return Icons.computer;
      case 'geography':
        return Icons.public;
      case 'mathematics':
        return Icons.calculate;
      default:
        return Icons.quiz;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Completed':
        return Theme.of(context).colorScheme.primary;
      case 'Claim Reward':
        return const Color(AppConstants.accentColorValue);
      case 'Retake Quiz':
        return const Color(AppConstants.warningColorValue);
      case 'Connect Wallet':
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _onCategoryTap(BuildContext context) async {
    if (!appProvider.isWalletConnected) {
      Navigator.of(context).pushNamed('/wallet-connect');
      return;
    }

    final status = appProvider.getCategoryStatus(category);

    if (status == 'Completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have already completed the $category quiz and claimed your reward.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    if (status == 'Claim Reward') {
      // Navigate to results screen to claim reward
      Navigator.of(context).pushNamed('/quiz-result');
      return;
    }

    // Start the quiz
    await appProvider.startQuiz(category);

    if (appProvider.error == null && context.mounted) {
      Navigator.of(context).pushNamed('/quiz');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = appProvider.getCategoryStatus(category);
    final canAttempt = appProvider.canAttemptCategory(category);
    final statusColor = _getStatusColor(context, status);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: appProvider.isGeneratingQuiz
            ? null
            : () => _onCategoryTap(context),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  size: 32,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 12),

              // Category Name
              Text(
                category,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Additional Info
              if (status == 'Completed') ...[
                Icon(Icons.check_circle, size: 16, color: statusColor),
              ] else if (status == 'Claim Reward') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      '${AppConstants.tokenRewardAmount.toInt()} tokens',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else if (appProvider.isGeneratingQuiz) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else if (canAttempt) ...[
                Text(
                  '${AppConstants.questionsPerQuiz} questions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
