import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';

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

  // Game history management
  Future<bool> saveGameHistory(
    String walletAddress,
    List<GameResult> gameHistory,
  ) async {
    await initialize();

    try {
      final gameHistoryData = gameHistory.map((game) => game.toMap()).toList();
      final jsonString = json.encode(gameHistoryData);
      return await _prefs.setString('game_history_$walletAddress', jsonString);
    } catch (e) {
      developer.log('Error saving game history: $e');
      return false;
    }
  }

  Future<List<GameResult>> getGameHistory(String walletAddress) async {
    await initialize();
    final jsonString = _prefs.getString('game_history_$walletAddress');
    if (jsonString == null) return [];

    try {
      final List<dynamic> gameHistoryData = json.decode(jsonString);
      return gameHistoryData.map((data) => GameResult.fromMap(data)).toList();
    } catch (e) {
      developer.log('Error parsing game history: $e');
      return [];
    }
  }

  // Game statistics management
  Future<Map<String, dynamic>> getGameStatistics(String walletAddress) async {
    await initialize();
    final gameHistory = await getGameHistory(walletAddress);

    if (gameHistory.isEmpty) {
      return {
        'totalGames': 0,
        'totalRewards': 0.0,
        'averageAccuracy': 0.0,
        'bestGuess': 0,
        'perfectGuesses': 0,
      };
    }

    final totalGames = gameHistory.length;
    final totalRewards = gameHistory.fold<double>(
      0.0,
      (sum, game) => sum + game.rewardAmount,
    );
    final totalDifference = gameHistory.fold<int>(
      0,
      (sum, game) => sum + game.difference,
    );
    final averageAccuracy = totalDifference / totalGames;
    final bestGuess = gameHistory
        .map((game) => game.difference)
        .reduce((a, b) => a < b ? a : b);
    final perfectGuesses =
        gameHistory.where((game) => game.difference == 0).length;

    return {
      'totalGames': totalGames,
      'totalRewards': totalRewards,
      'averageAccuracy': averageAccuracy,
      'bestGuess': bestGuess,
      'perfectGuesses': perfectGuesses,
    };
  }

  // Temporary game state management (for in-progress games)
  Future<bool> saveTemporaryGameState({
    required String walletAddress,
    required bool isInProgress,
    required DateTime timestamp,
  }) async {
    await initialize();

    final gameState = {
      'walletAddress': walletAddress,
      'isInProgress': isInProgress,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };

    try {
      final jsonString = json.encode(gameState);
      return await _prefs.setString('temp_game_state', jsonString);
    } catch (e) {
      developer.log('Error saving temporary game state: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTemporaryGameState() async {
    await initialize();
    final jsonString = _prefs.getString('temp_game_state');
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString);
    } catch (e) {
      developer.log('Error parsing temporary game state: $e');
      return null;
    }
  }

  Future<bool> clearTemporaryGameState() async {
    await initialize();
    return await _prefs.remove('temp_game_state');
  }

  // Check if temporary game state is recent (within last hour)
  Future<bool> hasRecentTemporaryGameState() async {
    final state = await getTemporaryGameState();
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
      // Clear all game history keys
      final keys = _prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('game_history_')) {
          await _prefs.remove(key);
        }
      }
      await clearTemporaryGameState();
      return true;
    } catch (e) {
      developer.log('Error clearing user data: $e');
      return false;
    }
  }
}
