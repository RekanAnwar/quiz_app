import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Result'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final result = appProvider.lastGameResult;

          if (result == null) {
            return const Center(child: Text('No game result available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Result Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: [
                        Icon(
                          _getResultIcon(result.difference),
                          size: 80,
                          color: _getResultColor(result.difference),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          result.performanceLevel,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getResultColor(result.difference),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You earned ${result.rewardAmount.toStringAsFixed(1)} GUESS tokens!',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Game Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game Details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Target Number',
                          '${result.targetNumber}',
                          Icons.flag,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Your Guess',
                          '${result.userGuess}',
                          Icons.casino,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Difference',
                          '${result.difference}',
                          Icons.compare_arrows,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Accuracy',
                          '${result.accuracyPercentage.toStringAsFixed(1)}%',
                          Icons.percent,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Reward Multiplier',
                          '${result.rewardMultiplier}x',
                          Icons.star,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Performance Analysis Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Analysis',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildPerformanceAnalysis(result),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          appProvider.clearLastGameResult();
                          Navigator.of(context).pushReplacementNamed('/home');
                        },
                        child: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          appProvider.clearLastGameResult();
                          appProvider.startGame();
                          Navigator.of(context).pushReplacementNamed('/game');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: const Text('Play Again'),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPerformanceAnalysis(GameResult result) {
    String analysis;
    String tip;

    if (result.difference == 0) {
      analysis = "🎯 Perfect! You nailed it exactly!";
      tip = "Amazing intuition! Keep playing to maintain this streak.";
    } else if (result.difference <= 5) {
      analysis = "🔥 Excellent! You were very close!";
      tip = "Great guessing! You're getting the hang of this game.";
    } else if (result.difference <= 10) {
      analysis = "⭐ Very good! You were quite close!";
      tip = "Nice work! Try to narrow down your range next time.";
    } else if (result.difference <= 20) {
      analysis = "👍 Good attempt! You were in the right ballpark.";
      tip = "Consider the middle ranges more carefully next time.";
    } else if (result.difference <= 30) {
      analysis = "📈 Fair try! Room for improvement.";
      tip =
          "Think about probability distributions - numbers near 50 are more likely.";
    } else if (result.difference <= 40) {
      analysis = "📊 Keep practicing! You'll get better.";
      tip = "Try to avoid extreme numbers unless you have a strong feeling.";
    } else {
      analysis =
          "🎲 That was quite far off, but every guess teaches you something!";
      tip =
          "Random numbers can be tricky. Consider staying closer to the middle range.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          analysis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getResultIcon(int difference) {
    if (difference == 0) return Icons.emoji_events;
    if (difference <= 5) return Icons.star;
    if (difference <= 10) return Icons.thumb_up;
    if (difference <= 20) return Icons.trending_up;
    if (difference <= 30) return Icons.sentiment_neutral;
    if (difference <= 40) return Icons.sentiment_dissatisfied;
    return Icons.refresh;
  }

  Color _getResultColor(int difference) {
    if (difference == 0) return Colors.amber;
    if (difference <= 5) return Colors.green;
    if (difference <= 10) return Colors.lightGreen;
    if (difference <= 20) return Colors.blue;
    if (difference <= 30) return Colors.orange;
    if (difference <= 40) return Colors.deepOrange;
    return Colors.red;
  }
}
