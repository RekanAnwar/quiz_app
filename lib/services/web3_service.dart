// ignore_for_file: unused_field, depend_on_referenced_packages

import 'dart:developer' as developer;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../constants/app_constants.dart';
import '../contracts/contract_config.dart';
import '../contracts/erc20_abi.dart';
import '../contracts/game_contract_abi.dart';

class Web3Service {
  static final Web3Service _instance = Web3Service._internal();
  factory Web3Service() => _instance;
  Web3Service._internal();

  String? _userAddress;
  Web3Client? _web3Client;

  // Contract instances
  DeployedContract? _tokenContract;
  DeployedContract? _gameContract;

  // Token contract functions
  ContractFunction? _balanceOfFunction;
  ContractFunction? _transferFunction;

  // Game contract functions
  ContractFunction? _playGameFunction;
  ContractFunction? _getUserTotalRewardsFunction;
  ContractFunction? _getUserTotalGamesFunction;
  ContractFunction? _getUserGameHistoryFunction;
  ContractFunction? _getLatestGameResultFunction;
  ContractFunction? _pausedFunction;

  // Check if the service is properly initialized
  bool get isInitialized =>
      _web3Client != null && _tokenContract != null && _gameContract != null;

  // Ensure service is initialized (throws exception if not)
  void _ensureInitialized() {
    if (_web3Client == null) {
      throw Exception(
        'Web3 client not initialized. Please call initialize() first.',
      );
    }
    if (_tokenContract == null || _gameContract == null) {
      throw Exception(
        'Smart contracts not initialized. Please check contract configuration.',
      );
    }
  }

  // Set user wallet address (from MetaMask or manual input)
  void setUserAddress(String address) {
    if (isValidAddress(address)) {
      _userAddress = address.toLowerCase();
    } else {
      throw Exception('Invalid Ethereum address format');
    }
  }

  String? get userAddress => _userAddress;

  // Check if wallet is connected
  bool get isWalletConnected => _userAddress != null;

  // Validate Ethereum address format (basic validation)
  static bool isValidAddress(String address) {
    // Basic Ethereum address validation
    if (!address.startsWith('0x')) return false;
    if (address.length != 42) return false;

    // Check if the rest are valid hex characters
    final hexPart = address.substring(2);
    final hexPattern = RegExp(r'^[0-9a-fA-F]+$');
    return hexPattern.hasMatch(hexPart);
  }

  // Get ETH balance
  Future<double> getEthBalance() async {
    if (_userAddress == null) return 0.0;

    try {
      _ensureInitialized();

      final address = EthereumAddress.fromHex(_userAddress!);
      final balance = await _web3Client!.getBalance(address);

      // Convert from Wei to ETH
      final ethBalance = balance.getValueInUnit(EtherUnit.ether);
      developer.log('ETH Balance: $ethBalance');

      return ethBalance;
    } catch (e) {
      developer.log('Error getting ETH balance: $e');
      return 0.0;
    }
  }

  // Get token balance
  Future<double> getTokenBalance() async {
    if (_userAddress == null) return 0.0;

    try {
      _ensureInitialized();

      final address = EthereumAddress.fromHex(_userAddress!);
      final result = await _web3Client!.call(
        contract: _tokenContract!,
        function: _balanceOfFunction!,
        params: [address],
      );

      final BigInt balance = result.first as BigInt;
      // Assuming 18 decimals for the token
      final double tokenBalance = balance.toDouble() / pow(10, 18);

      developer.log('Token Balance: $tokenBalance');
      return tokenBalance;
    } catch (e) {
      developer.log('Error getting token balance: $e');
      return 0.0;
    }
  }

  // Play the number guessing game
  Future<String?> playGame(int guess) async {
    if (_userAddress == null) {
      throw Exception('No wallet connected');
    }

    try {
      _ensureInitialized();
      developer.log('Playing game with guess: $guess');

      // Check if game is paused
      final result = await _web3Client!.call(
        contract: _gameContract!,
        function: _pausedFunction!,
        params: [],
      );
      final bool isPaused = result.first as bool;

      if (isPaused) {
        throw Exception('Game is currently paused');
      }

      // Get credentials (this should be handled by MetaMask in production)
      if (ContractConfig.gameManagerPrivateKey == 'YOUR_PRIVATE_KEY_HERE') {
        throw Exception(
          'Game play requires user wallet connection. '
          'Please connect your MetaMask wallet.',
        );
      }

      final credentials = EthPrivateKey.fromHex(
        ContractConfig.gameManagerPrivateKey,
      );

      // Prepare the transaction
      final transaction = Transaction.callContract(
        contract: _gameContract!,
        function: _playGameFunction!,
        parameters: [BigInt.from(guess)],
        maxGas: 300000,
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
      );

      developer.log('Sending play game transaction...');

      // Send the transaction
      final txHash = await _web3Client!.sendTransaction(
        credentials,
        transaction,
        chainId: ContractConfig.chainId,
      );

      developer.log('✅ Game transaction sent: $txHash');
      return txHash;
    } catch (e) {
      developer.log('❌ Error playing game: $e');
      throw Exception('Game transaction failed: $e');
    }
  }

  // Get user's total rewards
  Future<double> getUserTotalRewards() async {
    if (_userAddress == null) return 0.0;

    try {
      _ensureInitialized();

      final address = EthereumAddress.fromHex(_userAddress!);
      final result = await _web3Client!.call(
        contract: _gameContract!,
        function: _getUserTotalRewardsFunction!,
        params: [address],
      );

      final BigInt rewards = result.first as BigInt;
      final double totalRewards = rewards.toDouble() / pow(10, 18);

      developer.log('User Total Rewards: $totalRewards');
      return totalRewards;
    } catch (e) {
      developer.log('Error getting user total rewards: $e');
      return 0.0;
    }
  }

  // Get user's total games played
  Future<int> getUserTotalGames() async {
    if (_userAddress == null) return 0;

    try {
      _ensureInitialized();

      final address = EthereumAddress.fromHex(_userAddress!);
      final result = await _web3Client!.call(
        contract: _gameContract!,
        function: _getUserTotalGamesFunction!,
        params: [address],
      );

      final BigInt games = result.first as BigInt;
      final int totalGames = games.toInt();

      developer.log('User Total Games: $totalGames');
      return totalGames;
    } catch (e) {
      developer.log('Error getting user total games: $e');
      return 0;
    }
  }

  // Get user's latest game result
  Future<Map<String, dynamic>?> getLatestGameResult() async {
    if (_userAddress == null) return null;

    try {
      _ensureInitialized();

      final address = EthereumAddress.fromHex(_userAddress!);
      final result = await _web3Client!.call(
        contract: _gameContract!,
        function: _getLatestGameResultFunction!,
        params: [address],
      );

      if (result.isNotEmpty) {
        final gameResult = result.first as List;

        return {
          'targetNumber': (gameResult[0] as BigInt).toInt(),
          'userGuess': (gameResult[1] as BigInt).toInt(),
          'difference': (gameResult[2] as BigInt).toInt(),
          'rewardAmount': (gameResult[3] as BigInt).toDouble() / pow(10, 18),
          'timestamp': (gameResult[4] as BigInt).toInt(),
        };
      }
      return null;
    } catch (e) {
      developer.log('Error getting latest game result: $e');
      return null;
    }
  }

  // Get transaction status
  Future<bool> isTransactionConfirmed(String txHash) async {
    if (_web3Client == null) return false;

    try {
      // Get transaction receipt
      final receipt = await _web3Client!.getTransactionReceipt(txHash);

      if (receipt == null) {
        // Transaction not yet mined
        return false;
      }

      // Check if transaction was successful (status = 1)
      final isSuccessful = receipt.status == true;

      // Also check if it has enough confirmations (at least 1 block)
      final currentBlock = await _web3Client!.getBlockNumber();
      final confirmations = currentBlock - receipt.blockNumber.blockNum;

      developer.log(
        'Transaction $txHash: successful=$isSuccessful, confirmations=$confirmations',
      );

      return isSuccessful && confirmations >= 1;
    } catch (e) {
      developer.log('Error checking transaction status: $e');
      return false;
    }
  }

  // Get network information
  Map<String, dynamic> getNetworkInfo() {
    return {
      'name': 'Ethereum Sepolia Testnet',
      'chainId': AppConstants.sepoliaChainId,
      'rpcUrl': AppConstants.sepoliaRpcUrl,
      'explorer': AppConstants.sepoliaExplorer,
      'currency': 'ETH',
    };
  }

  // Format address for display (show first 6 and last 4 characters)
  String formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Get formatted user address
  String? get formattedUserAddress {
    if (_userAddress == null) return null;
    return formatAddress(_userAddress!);
  }

  // Disconnect wallet
  void disconnect() {
    _userAddress = null;
  }

  // Check if the current network is Ethereum Sepolia
  Future<bool> isOnEthereumSepolia() async {
    if (_web3Client == null) return false;

    try {
      // Get the current chain ID from the network
      final chainId = await _web3Client!.getChainId();

      // Ethereum Sepolia chain ID is 11155111
      final isCorrectNetwork =
          chainId == BigInt.from(AppConstants.sepoliaChainId);

      developer.log(
        'Current chain ID: $chainId, Expected: ${AppConstants.sepoliaChainId}',
      );
      return isCorrectNetwork;
    } catch (e) {
      developer.log('Error checking network: $e');
      return false;
    }
  }

  // Estimate gas fee for a game transaction
  Future<double> estimateGasFee() async {
    if (_web3Client == null ||
        _gameContract == null ||
        _playGameFunction == null) {
      return 0.0;
    }

    try {
      // Get current gas price
      final gasPrice = await _web3Client!.getGasPrice();

      // Estimate gas for a typical game transaction
      final estimatedGasLimit = 300000; // Typical gas limit for playGame

      // Calculate total gas fee in Wei
      final gasFeeWei = gasPrice.getInWei * BigInt.from(estimatedGasLimit);

      // Convert to ETH
      final gasFeeEth = gasFeeWei.toDouble() / pow(10, 18);

      developer.log('Estimated gas fee: ${gasFeeEth.toStringAsFixed(6)} ETH');
      return gasFeeEth;
    } catch (e) {
      developer.log('Error estimating gas fee: $e');
      return 0.0;
    }
  }

  // Initialize the service
  Future<void> initialize() async {
    try {
      developer.log('Initializing Web3Service...');

      // Initialize Web3Client
      final httpClient = http.Client();
      _web3Client = Web3Client(ContractConfig.rpcUrl, httpClient);
      developer.log('Web3Client created with RPC: ${ContractConfig.rpcUrl}');

      // Test connection by getting chain ID
      try {
        final chainId = await _web3Client!.getChainId();
        developer.log('Connected to network with chain ID: $chainId');
      } catch (e) {
        developer.log(
          'Warning: Failed to get chain ID during initialization: $e',
        );
        // Continue with initialization as this might be a temporary network issue
      }

      // Initialize contracts
      await _initializeContracts();

      developer.log('Web3Service initialization completed successfully');
    } catch (e) {
      developer.log('Error initializing Web3Service: $e');
      // Don't throw here - allow the app to continue with limited functionality
      // The specific methods will handle the null checks appropriately
    }
  }

  // Initialize smart contracts
  Future<void> _initializeContracts() async {
    try {
      developer.log('Initializing smart contracts...');
      developer.log(
        'Token contract address: ${ContractConfig.guessTokenContractAddress}',
      );
      developer.log(
        'Game contract address: ${ContractConfig.gameContractAddress}',
      );

      // Check if contracts are configured
      if (ContractConfig.guessTokenContractAddress == '0x...' ||
          ContractConfig.gameContractAddress == '0x...') {
        throw Exception(
          'Contract addresses not configured. Please update ContractConfig.',
        );
      }

      // Initialize ERC20 token contract
      try {
        final tokenAbi = ContractAbi.fromJson(erc20Abi, 'ERC20Token');
        _tokenContract = DeployedContract(
          tokenAbi,
          EthereumAddress.fromHex(ContractConfig.guessTokenContractAddress),
        );
        _balanceOfFunction = _tokenContract!.function('balanceOf');
        _transferFunction = _tokenContract!.function('transfer');
        developer.log('Token contract initialized successfully');
      } catch (e) {
        developer.log('Error initializing token contract: $e');
        throw Exception('Failed to initialize token contract: $e');
      }

      // Initialize game contract
      try {
        final gameAbi = ContractAbi.fromJson(
          gameContractAbi,
          'NumberGuessingGame',
        );
        _gameContract = DeployedContract(
          gameAbi,
          EthereumAddress.fromHex(ContractConfig.gameContractAddress),
        );
        _playGameFunction = _gameContract!.function('playGame');
        _getUserTotalRewardsFunction = _gameContract!.function(
          'getUserTotalRewards',
        );
        _getUserTotalGamesFunction = _gameContract!.function(
          'getUserTotalGames',
        );
        _getUserGameHistoryFunction = _gameContract!.function(
          'getUserGameHistory',
        );
        _getLatestGameResultFunction = _gameContract!.function(
          'getLatestGameResult',
        );
        _pausedFunction = _gameContract!.function('paused');
        developer.log('Game contract initialized successfully');
      } catch (e) {
        developer.log('Error initializing game contract: $e');
        throw Exception('Failed to initialize game contract: $e');
      }

      developer.log('All smart contracts initialized successfully');
    } catch (e) {
      developer.log('Error initializing contracts: $e');
      rethrow; // Rethrow to let the caller handle this error
    }
  }

  // Get detailed initialization status
  Map<String, dynamic> getInitializationStatus() {
    return {
      'web3ClientInitialized': _web3Client != null,
      'tokenContractInitialized': _tokenContract != null,
      'gameContractInitialized': _gameContract != null,
      'balanceOfFunctionReady': _balanceOfFunction != null,
      'playGameFunctionReady': _playGameFunction != null,
      'getUserTotalRewardsFunctionReady': _getUserTotalRewardsFunction != null,
      'getUserTotalGamesFunctionReady': _getUserTotalGamesFunction != null,
      'isFullyInitialized': isInitialized,
    };
  }

  // Dispose resources
  void dispose() {
    _userAddress = null;
    _web3Client?.dispose();
    _web3Client = null;
  }
}
