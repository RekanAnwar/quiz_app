import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/app_provider.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final result = appProvider.lastQuizResult;

          if (result == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64),
                  SizedBox(height: 16),
                  Text('No quiz results found'),
                ],
              ),
            );
          }

          final passed = result.passed;
          final canClaimReward = passed && !result.rewardClaimed;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Result Header
                Card(
                  color: passed
                      ? const Color(
                          AppConstants.accentColorValue,
                        ).withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(
                      AppConstants.defaultPadding * 1.5,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          passed
                              ? Icons.celebration
                              : Icons.sentiment_dissatisfied,
                          size: 80,
                          color: passed
                              ? const Color(AppConstants.accentColorValue)
                              : Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          passed
                              ? 'Congratulations!'
                              : 'Better Luck Next Time!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: passed
                                    ? const Color(AppConstants.accentColorValue)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          passed
                              ? 'You passed the ${result.category} quiz!'
                              : 'You didn\'t pass this time, but you can try again!',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: passed
                                    ? const Color(AppConstants.accentColorValue)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Score Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quiz Statistics',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Score Circle
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: passed
                                  ? const Color(
                                      AppConstants.accentColorValue,
                                    ).withValues(alpha: 0.1)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                              border: Border.all(
                                color: passed
                                    ? const Color(AppConstants.accentColorValue)
                                    : Theme.of(context).colorScheme.error,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${result.score.toInt()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: passed
                                              ? const Color(
                                                  AppConstants.accentColorValue,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                        ),
                                  ),
                                  Text(
                                    'Score',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: passed
                                              ? const Color(
                                                  AppConstants.accentColorValue,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Detailed Stats
                        _buildStatRow(
                          context,
                          'Category',
                          result.category,
                          Icons.category,
                        ),
                        _buildStatRow(
                          context,
                          'Correct Answers',
                          '${result.correctAnswers} / ${result.totalQuestions}',
                          Icons.check_circle,
                        ),
                        _buildStatRow(
                          context,
                          'Passing Score',
                          '${AppConstants.passingScore} / ${AppConstants.questionsPerQuiz}',
                          Icons.flag,
                        ),
                        _buildStatRow(
                          context,
                          'Status',
                          passed ? 'Passed' : 'Failed',
                          passed ? Icons.thumb_up : Icons.thumb_down,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Reward Section
                if (passed) ...[
                  Card(
                    color: canClaimReward
                        ? const Color(
                            AppConstants.accentColorValue,
                          ).withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: canClaimReward
                                    ? const Color(AppConstants.accentColorValue)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Token Reward',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: canClaimReward
                                          ? const Color(
                                              AppConstants.accentColorValue,
                                            )
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (canClaimReward) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  AppConstants.accentColorValue,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultRadius,
                                ),
                                border: Border.all(
                                  color: const Color(
                                    AppConstants.accentColorValue,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.stars,
                                    color: const Color(
                                      AppConstants.accentColorValue,
                                    ),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${AppConstants.tokenRewardAmount.toInt()} Tokens',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(
                                            AppConstants.accentColorValue,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You\'ve earned ${AppConstants.tokenRewardAmount.toInt()} tokens for passing this quiz!',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: appProvider.isLoading
                                    ? null
                                    : () async {
                                        await appProvider.claimReward();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    AppConstants.accentColorValue,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: appProvider.isLoading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Claiming Reward...'),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.redeem),
                                          SizedBox(width: 8),
                                          Text(
                                            'Claim Reward',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultRadius,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reward Already Claimed',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error Display
                if (appProvider.error != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appProvider.error!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        child: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/quiz-categories',
                            (route) => false,
                          );
                        },
                        child: const Text('More Quizzes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
