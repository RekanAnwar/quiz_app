import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/quiz_question.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Initialize the storage service
  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Wallet address management
  Future<String?> getWalletAddress() async {
    await initialize();
    return _prefs.getString(AppConstants.walletAddressKey);
  }

  Future<bool> setWalletAddress(String address) async {
    await initialize();
    return await _prefs.setString(AppConstants.walletAddressKey, address);
  }

  Future<bool> removeWalletAddress() async {
    await initialize();
    return await _prefs.remove(AppConstants.walletAddressKey);
  }

  // API key management
  Future<String?> getApiKey() async {
    await initialize();
    return _prefs.getString(AppConstants.apiKeyKey);
  }

  Future<bool> setApiKey(String apiKey) async {
    await initialize();
    return await _prefs.setString(AppConstants.apiKeyKey, apiKey);
  }

  Future<bool> removeApiKey() async {
    await initialize();
    return await _prefs.remove(AppConstants.apiKeyKey);
  }

  // Quiz results management
  Future<List<QuizResult>> getCompletedQuizzes() async {
    await initialize();
    final jsonString = _prefs.getString(AppConstants.completedQuizzesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => QuizResult.fromJson(json)).toList();
    } catch (e) {
      developer.log('Error parsing completed quizzes: $e');
      return [];
    }
  }

  Future<bool> saveQuizResult(QuizResult result) async {
    await initialize();
    final currentResults = await getCompletedQuizzes();
    currentResults.add(result);

    try {
      final jsonString = json.encode(
        currentResults.map((r) => r.toJson()).toList(),
      );
      return await _prefs.setString(
        AppConstants.completedQuizzesKey,
        jsonString,
      );
    } catch (e) {
      developer.log('Error saving quiz result: $e');
      return false;
    }
  }

  Future<bool> hasCompletedQuizCategory(
    String category,
    String walletAddress,
  ) async {
    final completedQuizzes = await getCompletedQuizzes();
    return completedQuizzes.any(
      (quiz) =>
          quiz.category.toLowerCase() == category.toLowerCase() &&
          quiz.walletAddress.toLowerCase() == walletAddress.toLowerCase(),
    );
  }

  Future<QuizResult?> getQuizResultForCategory(
    String category,
    String walletAddress,
  ) async {
    final completedQuizzes = await getCompletedQuizzes();
    try {
      return completedQuizzes.firstWhere(
        (quiz) =>
            quiz.category.toLowerCase() == category.toLowerCase() &&
            quiz.walletAddress.toLowerCase() == walletAddress.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<QuizResult>> getQuizResultsForWallet(String walletAddress) async {
    final completedQuizzes = await getCompletedQuizzes();
    return completedQuizzes
        .where(
          (quiz) =>
              quiz.walletAddress.toLowerCase() == walletAddress.toLowerCase(),
        )
        .toList();
  }

  // Statistics and analytics
  Future<Map<String, dynamic>> getQuizStatistics(String walletAddress) async {
    final results = await getQuizResultsForWallet(walletAddress);

    if (results.isEmpty) {
      return {
        'totalQuizzes': 0,
        'totalCorrectAnswers': 0,
        'averageScore': 0.0,
        'passedQuizzes': 0,
        'rewardsClaimed': 0,
        'categoriesCompleted': <String>[],
      };
    }

    final totalQuizzes = results.length;
    final totalCorrectAnswers = results.fold<int>(
      0,
      (sum, result) => sum + result.correctAnswers,
    );
    final totalQuestions = results.fold<int>(
      0,
      (sum, result) => sum + result.totalQuestions,
    );
    final averageScore = totalQuestions > 0
        ? (totalCorrectAnswers / totalQuestions * 100)
        : 0.0;
    final passedQuizzes = results.where((result) => result.passed).length;
    final rewardsClaimed = results
        .where((result) => result.rewardClaimed)
        .length;
    final categoriesCompleted = results
        .map((result) => result.category)
        .toSet()
        .toList();

    return {
      'totalQuizzes': totalQuizzes,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalQuestions': totalQuestions,
      'averageScore': averageScore,
      'passedQuizzes': passedQuizzes,
      'rewardsClaimed': rewardsClaimed,
      'categoriesCompleted': categoriesCompleted,
    };
  }

  // Settings management
  Future<bool> setFirstTimeUser(bool isFirstTime) async {
    await initialize();
    return await _prefs.setBool('first_time_user', isFirstTime);
  }

  Future<bool> isFirstTimeUser() async {
    await initialize();
    return _prefs.getBool('first_time_user') ?? true;
  }

  Future<bool> setThemeMode(String themeMode) async {
    await initialize();
    return await _prefs.setString('theme_mode', themeMode);
  }

  Future<String> getThemeMode() async {
    await initialize();
    return _prefs.getString('theme_mode') ?? 'system';
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    await initialize();
    return await _prefs.setBool('notifications_enabled', enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    await initialize();
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  // Temporary quiz state management (for in-progress quizzes)
  Future<bool> saveTemporaryQuizState({
    required String category,
    required List<QuizQuestion> questions,
    required int currentQuestionIndex,
    required List<int?> userAnswers,
    required int correctAnswers,
  }) async {
    await initialize();

    final quizState = {
      'category': category,
      'questions': questions.map((q) => q.toJson()).toList(),
      'currentQuestionIndex': currentQuestionIndex,
      'userAnswers': userAnswers,
      'correctAnswers': correctAnswers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final jsonString = json.encode(quizState);
      return await _prefs.setString('temp_quiz_state', jsonString);
    } catch (e) {
      developer.log('Error saving temporary quiz state: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTemporaryQuizState() async {
    await initialize();
    final jsonString = _prefs.getString('temp_quiz_state');
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString);
    } catch (e) {
      developer.log('Error parsing temporary quiz state: $e');
      return null;
    }
  }

  Future<bool> clearTemporaryQuizState() async {
    await initialize();
    return await _prefs.remove('temp_quiz_state');
  }

  // Check if temporary quiz state is recent (within last hour)
  Future<bool> hasRecentTemporaryQuizState() async {
    final state = await getTemporaryQuizState();
    if (state == null) return false;

    final timestamp = state['timestamp'] as int?;
    if (timestamp == null) return false;

    final stateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(stateTime);

    return difference.inHours < 1; // Consider recent if within last hour
  }

  // Clear all data (useful for logout or reset)
  Future<bool> clearAllData() async {
    await initialize();
    try {
      await _prefs.clear();
      return true;
    } catch (e) {
      developer.log('Error clearing all data: $e');
      return false;
    }
  }

  // Clear only user-specific data (keep settings)
  Future<bool> clearUserData() async {
    await initialize();
    try {
      await removeWalletAddress();
      await _prefs.remove(AppConstants.completedQuizzesKey);
      await clearTemporaryQuizState();
      return true;
    } catch (e) {
      developer.log('Error clearing user data: $e');
      return false;
    }
  }
}
