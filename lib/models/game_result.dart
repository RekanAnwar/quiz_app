class GameResult {
  final int targetNumber;
  final int userGuess;
  final int difference;
  final double rewardAmount;
  final DateTime timestamp;

  GameResult({
    required this.targetNumber,
    required this.userGuess,
    required this.difference,
    required this.rewardAmount,
    required this.timestamp,
  });

  // Calculate accuracy percentage
  double get accuracyPercentage {
    return ((100 - difference) / 100) * 100;
  }

  // Get performance level based on difference
  String get performanceLevel {
    if (difference == 0) return 'Perfect!';
    if (difference <= 5) return 'Excellent';
    if (difference <= 10) return 'Very Good';
    if (difference <= 20) return 'Good';
    if (difference <= 30) return 'Fair';
    if (difference <= 40) return 'Poor';
    return 'Very Poor';
  }

  // Get reward multiplier
  double get rewardMultiplier {
    if (difference == 0) return 5.0; // Perfect guess: 5x base reward
    if (difference <= 5) return 1.75; // Very close: 1.75x base reward
    if (difference <= 10) return 1.5; // Close: 1.5x base reward
    if (difference <= 20) return 1.25; // Moderate: 1.25x base reward
    if (difference <= 30) return 1.0; // Fair: 1x base reward
    if (difference <= 40) return 0.5; // Poor: 0.5x base reward
    return 0.25; // Very poor: 0.25x base reward
  }

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      targetNumber: map['targetNumber'] ?? 0,
      userGuess: map['userGuess'] ?? 0,
      difference: map['difference'] ?? 0,
      rewardAmount: (map['rewardAmount'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetNumber': targetNumber,
      'userGuess': userGuess,
      'difference': difference,
      'rewardAmount': rewardAmount,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
