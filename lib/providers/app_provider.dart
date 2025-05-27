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
  double _ethBalance = 0.0;
  double _tokenBalance = 0.0;
  bool _isWalletConnecting = false;

  // Game state
  bool _isGameInProgress = false;
  GameResult? _lastGameResult;

  // Settings
  String _themeMode = 'system';
  bool _notificationsEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Wallet getters
  String? get walletAddress => _walletAddress;
  String? get formattedWalletAddress =>
      _walletAddress != null
          ? _web3Service.formatAddress(_walletAddress!)
          : null;
  double get ethBalance => _ethBalance;
  double get tokenBalance => _tokenBalance;
  bool get isWalletConnected => _walletAddress != null;
  bool get isWalletConnecting => _isWalletConnecting;

  // Game getters
  bool get isGameInProgress => _isGameInProgress;
  GameResult? get lastGameResult => _lastGameResult;

  // Settings getters
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
        await connectWallet(savedAddress, updateBalance: true);
      }

      // Load settings
      _themeMode = await _storageService.getThemeMode();
      _notificationsEnabled = await _storageService.getNotificationsEnabled();

      // Check for incomplete game
      await _checkForIncompleteGame();
    } catch (e) {
      developer.log('Error loading saved data: $e');
    }
  }

  // Check for incomplete game and offer to resume
  Future<void> _checkForIncompleteGame() async {
    try {
      if (await _storageService.hasRecentTemporaryGameState()) {
        final state = await _storageService.getTemporaryGameState();
        if (state != null) {
          // Game can be resumed - this would typically show a dialog to the user
          developer.log('Found incomplete game that can be resumed');
        }
      }
    } catch (e) {
      developer.log('Error checking for incomplete game: $e');
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

      await _storageService.removeWalletAddress();
      await _storageService.clearUserData();

      // Clear game state if in progress
      if (_isGameInProgress) {
        await _clearGameState();
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

  // Start a new game
  Future<void> startGame() async {
    if (_walletAddress == null) {
      _setError('Please connect your wallet first');
      return;
    }

    try {
      _setError(null);
      _isGameInProgress = true;

      // Save temporary game state
      await _storageService.saveTemporaryGameState(
        walletAddress: _walletAddress!,
        isInProgress: true,
        timestamp: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
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

      // Wait for transaction confirmation
      bool isConfirmed = false;
      int attempts = 0;
      const maxAttempts = 30; // Wait up to 30 seconds

      while (!isConfirmed && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));
        isConfirmed = await _web3Service.isTransactionConfirmed(txHash!);
        attempts++;
      }

      if (!isConfirmed) {
        throw Exception(
          'Transaction not confirmed after timeout. Check Etherscan: $txHash',
        );
      }

      // Wait a moment for blockchain state to update
      await Future.delayed(const Duration(seconds: 2));

      // Get the latest game result
      final latestResult = await _web3Service.getLatestGameResult();
      if (latestResult == null) {
        throw Exception('Could not retrieve game result from blockchain');
      }

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

      // Update balances
      await _updateBalances();

      // Clear temporary game state
      await _storageService.clearTemporaryGameState();

      _isGameInProgress = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to play game: $e');
    } finally {
      _setLoading(false);
    }
  }

  // End the current game
  void endGame() {
    _isGameInProgress = false;
    _storageService.clearTemporaryGameState();
    notifyListeners();
  }

  // Clear last game result
  void clearLastGameResult() {
    _lastGameResult = null;
    notifyListeners();
  }

  // Clear game state
  Future<void> _clearGameState() async {
    _isGameInProgress = false;
    _lastGameResult = null;
    await _storageService.clearTemporaryGameState();
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

  @override
  void dispose() {
    _web3Service.dispose();
    super.dispose();
  }
}
