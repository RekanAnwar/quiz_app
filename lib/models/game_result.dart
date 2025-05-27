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
}
