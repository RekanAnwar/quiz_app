import 'package:json_annotation/json_annotation.dart';

part 'quiz_question.g.dart';

@JsonSerializable()
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);
}

@JsonSerializable()
class Quiz {
  final String category;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  const Quiz({
    required this.category,
    required this.questions,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);

  Map<String, dynamic> toJson() => _$QuizToJson(this);
}

@JsonSerializable()
class QuizResult {
  final String category;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final bool passed;
  final bool rewardClaimed;
  final DateTime completedAt;
  final String walletAddress;

  const QuizResult({
    required this.category,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.passed,
    required this.rewardClaimed,
    required this.completedAt,
    required this.walletAddress,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) =>
      _$QuizResultFromJson(json);

  Map<String, dynamic> toJson() => _$QuizResultToJson(this);
}
