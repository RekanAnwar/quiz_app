import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/quiz_question.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/web3_service.dart';

class AppProvider with ChangeNotifier {
  final Web3Service _web3Service = Web3Service();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  // App state
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Wallet state
  String? _walletAddress;
  double _ethBalance = 0.0;
  double _tokenBalance = 0.0;
  bool _isWalletConnecting = false;

  // Quiz state
  Quiz? _currentQuiz;
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  int _correctAnswers = 0;
  bool _isQuizInProgress = false;
  bool _isGeneratingQuiz = false;
  QuizResult? _lastQuizResult;

  // User data
  List<QuizResult> _completedQuizzes = [];
  Map<String, dynamic> _userStats = {};

  // Settings
  bool _hasApiKey = false;
  String _themeMode = 'system';
  bool _notificationsEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Wallet getters
  String? get walletAddress => _walletAddress;
  String? get formattedWalletAddress => _walletAddress != null
      ? _web3Service.formatAddress(_walletAddress!)
      : null;
  double get ethBalance => _ethBalance;
  double get tokenBalance => _tokenBalance;
  bool get isWalletConnected => _walletAddress != null;
  bool get isWalletConnecting => _isWalletConnecting;

  // Quiz getters
  Quiz? get currentQuiz => _currentQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<int?> get userAnswers => _userAnswers;
  int get correctAnswers => _correctAnswers;
  bool get isQuizInProgress => _isQuizInProgress;
  bool get isGeneratingQuiz => _isGeneratingQuiz;
  QuizResult? get lastQuizResult => _lastQuizResult;

  QuizQuestion? get currentQuestion =>
      _currentQuiz != null &&
          _currentQuestionIndex < _currentQuiz!.questions.length
      ? _currentQuiz!.questions[_currentQuestionIndex]
      : null;

  int get totalQuestions => _currentQuiz?.questions.length ?? 0;
  double get quizProgress =>
      totalQuestions > 0 ? (_currentQuestionIndex + 1) / totalQuestions : 0.0;

  // User data getters
  List<QuizResult> get completedQuizzes => _completedQuizzes;
  Map<String, dynamic> get userStats => _userStats;

  // Settings getters
  bool get hasApiKey => _hasApiKey;
  String get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;

  // Initialize the app
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);

      // Initialize services
      await _storageService.initialize();
      await _web3Service.initialize();

      // Load saved data
      await _loadSavedData();

      _isInitialized = true;
      _setError(null);
    } catch (e) {
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load saved data from storage
  Future<void> _loadSavedData() async {
    try {
      // Load wallet address
      final savedAddress = await _storageService.getWalletAddress();
      if (savedAddress != null) {
        await connectWallet(savedAddress, updateBalance: false);
      }

      // Load API key
      final savedApiKey = await _storageService.getApiKey();
      if (savedApiKey != null) {
        _aiService.setApiKey(savedApiKey);
        _hasApiKey = true;
      }

      // Load completed quizzes
      _completedQuizzes = await _storageService.getCompletedQuizzes();

      // Load settings
      _themeMode = await _storageService.getThemeMode();
      _notificationsEnabled = await _storageService.getNotificationsEnabled();

      // Load user stats
      if (_walletAddress != null) {
        _userStats = await _storageService.getQuizStatistics(_walletAddress!);
      }

      // Check for incomplete quiz
      await _checkForIncompleteQuiz();
    } catch (e) {
      developer.log('Error loading saved data: $e');
    }
  }

  // Check for incomplete quiz and offer to resume
  Future<void> _checkForIncompleteQuiz() async {
    try {
      if (await _storageService.hasRecentTemporaryQuizState()) {
        final state = await _storageService.getTemporaryQuizState();
        if (state != null) {
          // Quiz can be resumed - this would typically show a dialog to the user
          developer.log('Found incomplete quiz that can be resumed');
        }
      }
    } catch (e) {
      developer.log('Error checking for incomplete quiz: $e');
    }
  }

  // Connect wallet
  Future<void> connectWallet(
    String address, {
    bool updateBalance = true,
  }) async {
    try {
      _setWalletConnecting(true);

      if (!Web3Service.isValidAddress(address)) {
        throw Exception('Invalid wallet address format');
      }

      _web3Service.setUserAddress(address);
      _walletAddress = address;

      // Save wallet address
      await _storageService.setWalletAddress(address);

      if (updateBalance) {
        await _updateBalances();
      }

      // Update user stats
      _userStats = await _storageService.getQuizStatistics(address);

      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to connect wallet: $e');
    } finally {
      _setWalletConnecting(false);
    }
  }

  // Disconnect wallet
  Future<void> disconnectWallet() async {
    try {
      _web3Service.disconnect();
      _walletAddress = null;
      _ethBalance = 0.0;
      _tokenBalance = 0.0;
      _userStats = {};

      await _storageService.removeWalletAddress();
      await _storageService.clearUserData();

      // Clear quiz state if in progress
      if (_isQuizInProgress) {
        await _clearQuizState();
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to disconnect wallet: $e');
    }
  }

  // Update wallet balances
  Future<void> _updateBalances() async {
    try {
      final futures = await Future.wait([
        _web3Service.getEthBalance(),
        _web3Service.getTokenBalance(),
      ]);

      _ethBalance = futures[0];
      _tokenBalance = futures[1];

      notifyListeners();
    } catch (e) {
      developer.log('Error updating balances: $e');
    }
  }

  // Set API key
  Future<void> setApiKey(String apiKey) async {
    try {
      _aiService.setApiKey(apiKey);
      await _storageService.setApiKey(apiKey);
      _hasApiKey = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to save API key: $e');
    }
  }

  // Start a new quiz
  Future<void> startQuiz(String category) async {
    if (_walletAddress == null) {
      _setError('Please connect your wallet first');
      return;
    }

    try {
      _setGeneratingQuiz(true);
      _setError(null);

      // Check if user has already completed this category
      final hasCompleted = await _storageService.hasCompletedQuizCategory(
        category,
        _walletAddress!,
      );

      if (hasCompleted) {
        final existingResult = await _storageService.getQuizResultForCategory(
          category,
          _walletAddress!,
        );
        if (existingResult != null && existingResult.rewardClaimed) {
          throw Exception(
            'You have already completed this quiz category and claimed your reward.',
          );
        }
      }

      // Generate quiz questions
      List<QuizQuestion> questions;
      if (_hasApiKey) {
        try {
          questions = await _aiService.generateQuizQuestions(category);
        } catch (e) {
          developer.log('AI generation failed, using fallback: $e');
          questions = await _aiService.generateMockQuizQuestions(category);
        }
      } else {
        questions = await _aiService.generateMockQuizQuestions(category);
      }

      // Initialize quiz state
      _currentQuiz = Quiz(
        category: category,
        questions: questions,
        createdAt: DateTime.now(),
      );
      _currentQuestionIndex = 0;
      _userAnswers = List.filled(questions.length, null);
      _correctAnswers = 0;
      _isQuizInProgress = true;

      // Save temporary state
      await _saveTemporaryQuizState();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setGeneratingQuiz(false);
    }
  }

  // Answer current question
  Future<void> answerQuestion(int selectedOptionIndex) async {
    if (_currentQuiz == null || !_isQuizInProgress) return;

    try {
      final currentQ = _currentQuiz!.questions[_currentQuestionIndex];
      _userAnswers[_currentQuestionIndex] = selectedOptionIndex;

      if (selectedOptionIndex == currentQ.correctAnswerIndex) {
        _correctAnswers++;
      }

      // Save temporary state
      await _saveTemporaryQuizState();

      notifyListeners();
    } catch (e) {
      _setError('Failed to save answer: $e');
    }
  }

  // Move to next question
  void nextQuestion() {
    if (_currentQuiz == null || !_isQuizInProgress) return;

    if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  // Move to previous question
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  // Complete the quiz
  Future<void> completeQuiz() async {
    if (_currentQuiz == null || _walletAddress == null || !_isQuizInProgress) {
      return;
    }

    try {
      _setLoading(true);

      final score = (_correctAnswers / _currentQuiz!.questions.length) * 100;
      final passed = _correctAnswers >= AppConstants.passingScore;

      _lastQuizResult = QuizResult(
        category: _currentQuiz!.category,
        totalQuestions: _currentQuiz!.questions.length,
        correctAnswers: _correctAnswers,
        score: score,
        passed: passed,
        rewardClaimed: false,
        completedAt: DateTime.now(),
        walletAddress: _walletAddress!,
      );

      // Save quiz result
      await _storageService.saveQuizResult(_lastQuizResult!);
      _completedQuizzes.add(_lastQuizResult!);

      // Update user stats
      _userStats = await _storageService.getQuizStatistics(_walletAddress!);

      // Clear temporary state
      await _storageService.clearTemporaryQuizState();
      _isQuizInProgress = false;

      notifyListeners();
    } catch (e) {
      _setError('Failed to complete quiz: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Claim reward for completed quiz
  Future<void> claimReward() async {
    if (_lastQuizResult == null ||
        !_lastQuizResult!.passed ||
        _walletAddress == null) {
      _setError('No eligible reward to claim');
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      // Check if reward was already claimed
      if (_lastQuizResult!.rewardClaimed) {
        throw Exception('Reward has already been claimed for this quiz');
      }

      // Distribute reward
      final txHash = await _web3Service.distributeReward(
        _lastQuizResult!.category,
        AppConstants.tokenRewardAmount,
      );

      if (txHash != null) {
        // Update quiz result as reward claimed
        final updatedResult = QuizResult(
          category: _lastQuizResult!.category,
          totalQuestions: _lastQuizResult!.totalQuestions,
          correctAnswers: _lastQuizResult!.correctAnswers,
          score: _lastQuizResult!.score,
          passed: _lastQuizResult!.passed,
          rewardClaimed: true,
          completedAt: _lastQuizResult!.completedAt,
          walletAddress: _lastQuizResult!.walletAddress,
        );

        _lastQuizResult = updatedResult;

        // Update stored results
        final index = _completedQuizzes.indexWhere(
          (r) =>
              r.category == updatedResult.category &&
              r.walletAddress == updatedResult.walletAddress,
        );

        if (index != -1) {
          _completedQuizzes[index] = updatedResult;
        }

        // Update balances
        await _updateBalances();

        // Update user stats
        _userStats = await _storageService.getQuizStatistics(_walletAddress!);

        notifyListeners();
      } else {
        throw Exception('Failed to distribute reward');
      }
    } catch (e) {
      _setError('Failed to claim reward: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save temporary quiz state
  Future<void> _saveTemporaryQuizState() async {
    if (_currentQuiz == null) return;

    try {
      await _storageService.saveTemporaryQuizState(
        category: _currentQuiz!.category,
        questions: _currentQuiz!.questions,
        currentQuestionIndex: _currentQuestionIndex,
        userAnswers: _userAnswers,
        correctAnswers: _correctAnswers,
      );
    } catch (e) {
      developer.log('Error saving temporary quiz state: $e');
    }
  }

  // Clear quiz state
  Future<void> _clearQuizState() async {
    _currentQuiz = null;
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _correctAnswers = 0;
    _isQuizInProgress = false;
    _lastQuizResult = null;

    await _storageService.clearTemporaryQuizState();
    notifyListeners();
  }

  // Update settings
  Future<void> updateThemeMode(String themeMode) async {
    _themeMode = themeMode;
    await _storageService.setThemeMode(themeMode);
    notifyListeners();
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _storageService.setNotificationsEnabled(enabled);
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setWalletConnecting(bool connecting) {
    _isWalletConnecting = connecting;
    notifyListeners();
  }

  void _setGeneratingQuiz(bool generating) {
    _isGeneratingQuiz = generating;
    notifyListeners();
  }

  // Check if category can be attempted
  bool canAttemptCategory(String category) {
    if (_walletAddress == null) return false;

    final existingResult = _completedQuizzes
        .where(
          (quiz) =>
              quiz.category.toLowerCase() == category.toLowerCase() &&
              quiz.walletAddress.toLowerCase() == _walletAddress!.toLowerCase(),
        )
        .firstOrNull;

    return existingResult == null || !existingResult.rewardClaimed;
  }

  // Get category status
  String getCategoryStatus(String category) {
    if (_walletAddress == null) return 'Connect Wallet';

    final existingResult = _completedQuizzes
        .where(
          (quiz) =>
              quiz.category.toLowerCase() == category.toLowerCase() &&
              quiz.walletAddress.toLowerCase() == _walletAddress!.toLowerCase(),
        )
        .firstOrNull;

    if (existingResult == null) {
      return 'Start Quiz';
    } else if (existingResult.rewardClaimed) {
      return 'Completed';
    } else if (existingResult.passed) {
      return 'Claim Reward';
    } else {
      return 'Retake Quiz';
    }
  }

  @override
  void dispose() {
    _web3Service.dispose();
    super.dispose();
  }
}
