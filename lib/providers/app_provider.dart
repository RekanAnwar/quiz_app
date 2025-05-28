import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/web3_service.dart';

class AppProvider with ChangeNotifier {
  final Web3Service _web3Service = Web3Service();
  final StorageService _storageService = StorageService();

  // App state
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Wallet state
  String? _walletAddress;
  double _tokenBalance = 0.0;
  bool _isWalletConnecting = false;

  // Game state
  bool _isGameInProgress = false;
  GameResult? _lastGameResult;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Wallet getters
  String? get walletAddress => _walletAddress;
  String? get formattedWalletAddress =>
      _walletAddress != null
          ? '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}'
          : null;
  double get tokenBalance => _tokenBalance;
  bool get isWalletConnected => _walletAddress != null;
  bool get isWalletConnecting => _isWalletConnecting;

  // Game getters
  bool get isGameInProgress => _isGameInProgress;
  GameResult? get lastGameResult => _lastGameResult;

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
        await connectWallet(savedAddress, updateBalance: true);
      }
    } catch (e) {
      developer.log('Error loading saved data: $e');
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
        await _updateBalance();
      }

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
      _tokenBalance = 0.0;

      await _storageService.removeWalletAddress();
      await _storageService.clearUserData();

      // Clear game state
      _clearGameState();

      notifyListeners();
    } catch (e) {
      _setError('Failed to disconnect wallet: $e');
    }
  }

  // Start a new game
  void startGame() {
    if (_walletAddress == null) {
      _setError('Please connect your wallet first');
      return;
    }

    _setError(null);
    _isGameInProgress = true;
    notifyListeners();
  }

  // Play the number guessing game
  Future<void> playGame(int guess) async {
    if (_walletAddress == null) {
      _setError('Please connect your wallet first');
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      // Call the smart contract to play the game
      final txHash = await _web3Service.playGame(guess);

      developer.log('Game transaction sent: $txHash');

      // Wait a moment for blockchain state to update
      await Future.delayed(const Duration(seconds: 3));

      // Always try to update balance after a game (regardless of result retrieval)
      await _updateBalanceWithRetry();

      // Try to get the latest game result
      final latestResult = await _web3Service.getLatestGameResult();

      if (latestResult != null) {
        final result = GameResult(
          targetNumber: latestResult['targetNumber'] as int,
          userGuess: latestResult['userGuess'] as int,
          difference: latestResult['difference'] as int,
          rewardAmount: latestResult['rewardAmount'] as double,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (latestResult['timestamp'] as int) * 1000,
          ),
        );

        _lastGameResult = result;
      } else {
        developer.log(
          'Could not retrieve game result immediately, but transaction was sent',
        );
        // Try again after a longer delay
        await Future.delayed(const Duration(seconds: 2));
        await _updateBalanceWithRetry();
      }

      _isGameInProgress = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to play game: $e');
      _isGameInProgress = false;
      // Still try to update balance in case the transaction went through
      await _updateBalanceWithRetry();
    } finally {
      _setLoading(false);
    }
  }

  // Update token balance with retry logic
  Future<void> _updateBalanceWithRetry() async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await _updateBalance();
        break; // Success, exit retry loop
      } catch (e) {
        developer.log('Balance update attempt ${attempt + 1} failed: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
  }

  // Update token balance
  Future<void> _updateBalance() async {
    try {
      _tokenBalance = await _web3Service.getTokenBalance();
      notifyListeners();
    } catch (e) {
      developer.log('Error updating token balance: $e');
    }
  }

  // End the current game
  void endGame() {
    _clearGameState();
  }

  // Clear last game result and refresh balance
  Future<void> clearLastGameResult() async {
    _lastGameResult = null;
    // Refresh balance when starting a new game session
    await _updateBalanceWithRetry();
    notifyListeners();
  }

  // Manual balance refresh (can be called from UI)
  Future<void> refreshBalance() async {
    if (_walletAddress == null) return;

    try {
      await _updateBalanceWithRetry();
    } catch (e) {
      developer.log('Error refreshing balance: $e');
    }
  }

  // Clear game state
  void _clearGameState() {
    _isGameInProgress = false;
    _lastGameResult = null;
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

  @override
  void dispose() {
    _web3Service.dispose();
    super.dispose();
  }
}
