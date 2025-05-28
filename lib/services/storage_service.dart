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

  // Clear user data
  Future<bool> clearUserData() async {
    await initialize();
    try {
      await removeWalletAddress();
      return true;
    } catch (e) {
      developer.log('Error clearing user data: $e');
      return false;
    }
  }
}
