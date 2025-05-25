// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizQuestion _$QuizQuestionFromJson(Map<String, dynamic> json) => QuizQuestion(
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctAnswerIndex: (json['correctAnswerIndex'] as num).toInt(),
  explanation: json['explanation'] as String,
);

Map<String, dynamic> _$QuizQuestionToJson(QuizQuestion instance) =>
    <String, dynamic>{
      'question': instance.question,
      'options': instance.options,
      'correctAnswerIndex': instance.correctAnswerIndex,
      'explanation': instance.explanation,
    };

Quiz _$QuizFromJson(Map<String, dynamic> json) => Quiz(
  category: json['category'] as String,
  questions: (json['questions'] as List<dynamic>)
      .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$QuizToJson(Quiz instance) => <String, dynamic>{
  'category': instance.category,
  'questions': instance.questions,
  'createdAt': instance.createdAt.toIso8601String(),
};

QuizResult _$QuizResultFromJson(Map<String, dynamic> json) => QuizResult(
  category: json['category'] as String,
  totalQuestions: (json['totalQuestions'] as num).toInt(),
  correctAnswers: (json['correctAnswers'] as num).toInt(),
  score: (json['score'] as num).toDouble(),
  passed: json['passed'] as bool,
  rewardClaimed: json['rewardClaimed'] as bool,
  completedAt: DateTime.parse(json['completedAt'] as String),
  walletAddress: json['walletAddress'] as String,
);

Map<String, dynamic> _$QuizResultToJson(QuizResult instance) =>
    <String, dynamic>{
      'category': instance.category,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'score': instance.score,
      'passed': instance.passed,
      'rewardClaimed': instance.rewardClaimed,
      'completedAt': instance.completedAt.toIso8601String(),
      'walletAddress': instance.walletAddress,
    };
