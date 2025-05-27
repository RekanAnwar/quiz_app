import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

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

  // Clear only user-specific data (keep settings)
  Future<bool> clearUserData() async {
    await initialize();
    try {
      await removeWalletAddress();

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
