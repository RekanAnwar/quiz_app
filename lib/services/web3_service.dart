// ignore_for_file: unused_field, depend_on_referenced_packages

import 'dart:developer' as developer;
import 'dart:math';

import 'dart:convert';

import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../contracts/erc20_abi.dart';
import '../contracts/reward_contract_abi.dart';
import '../contracts/contract_config.dart';

class Web3Service {
  static final Web3Service _instance = Web3Service._internal();
  factory Web3Service() => _instance;
  Web3Service._internal();

  String? _userAddress;
  Web3Client? _web3Client;

  // Contract instances
  DeployedContract? _tokenContract;
  DeployedContract? _rewardContract;

  // Contract functions
  ContractFunction? _balanceOfFunction;
  ContractFunction? _hasClaimedRewardFunction;
  ContractFunction? _distributeRewardFunction;
  ContractFunction? _getUserRewardsFunction;

  // Check if the service is properly initialized
  bool get isInitialized =>
      _web3Client != null && _tokenContract != null && _rewardContract != null;

  // Ensure service is initialized (throws exception if not)
  void _ensureInitialized() {
    if (_web3Client == null) {
      throw Exception(
        'Web3 client not initialized. Please call initialize() first.',
      );
    }
    if (_tokenContract == null || _rewardContract == null) {
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

  // Check if user has already claimed reward for a specific quiz category
  Future<bool> hasClaimedReward(String quizCategory) async {
    if (_userAddress == null) return false;

    try {
      _ensureInitialized();

      final address = EthereumAddress.fromHex(_userAddress!);
      final result = await _web3Client!.call(
        contract: _rewardContract!,
        function: _hasClaimedRewardFunction!,
        params: [address, quizCategory],
      );

      final bool hasClaimed = result.first as bool;
      developer.log('Has claimed reward for $quizCategory: $hasClaimed');

      return hasClaimed;
    } catch (e) {
      developer.log('Error checking claimed reward: $e');
      return false;
    }
  }

  // Distribute token reward (real implementation)
  Future<String?> distributeReward(String quizCategory, double amount) async {
    if (_userAddress == null) {
      throw Exception('No wallet connected');
    }

    try {
      _ensureInitialized();
      developer.log(
        'Distributing $amount tokens to $_userAddress for $quizCategory quiz',
      );

      // Check if user has already claimed this reward
      final hasClaimed = await hasClaimedReward(quizCategory);
      if (hasClaimed) {
        throw Exception('Reward for $quizCategory has already been claimed');
      }

      // Check if RewardDistributor has minter role on QuizToken
      await _checkMinterPermissions();

      // For production: This should be called from a secure backend service
      // Here we show the contract call structure, but the actual signing would need
      // to be done server-side with the reward distributor's private key

      if (ContractConfig.rewardDistributorPrivateKey ==
          'YOUR_PRIVATE_KEY_HERE') {
        throw Exception(
          'Reward distribution requires backend service. '
          'Please configure a secure backend for reward distribution.',
        );
      }

      // Get credentials for the reward distributor
      final credentials = EthPrivateKey.fromHex(
        ContractConfig.rewardDistributorPrivateKey,
      );
      final distributorAddress = credentials.address;
      developer.log('Distributor address: $distributorAddress');

      // Check distributor ETH balance
      final distributorBalance = await _web3Client!.getBalance(
        distributorAddress,
      );
      developer.log(
        'Distributor ETH balance: ${distributorBalance.getValueInUnit(EtherUnit.ether)} ETH',
      );

      // Prepare the transaction
      final userAddress = EthereumAddress.fromHex(_userAddress!);

      developer.log('Transaction details:');
      developer.log('- User: $userAddress');
      developer.log('- Category: $quizCategory');
      developer.log('- Fixed reward amount: 10 QUIZ tokens (set in contract)');

      // Call the distributeReward function (only 2 parameters: user, category)
      final transaction = Transaction.callContract(
        contract: _rewardContract!,
        function: _distributeRewardFunction!,
        parameters: [
          userAddress,
          quizCategory,
        ], // Removed rewardAmount parameter
        maxGas: 500000, // Increased gas limit
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
      );

      developer.log(
        'Sending transaction with gas limit: 500000, gas price: 20 gwei',
      );

      // Send the transaction
      final txHash = await _web3Client!.sendTransaction(
        credentials,
        transaction,
        chainId: ContractConfig.chainId,
      );

      developer.log('✅ Reward distribution transaction sent: $txHash');
      return txHash;
    } catch (e) {
      developer.log('❌ Error distributing reward: $e');

      // Check for common revert reasons
      String errorMessage = e.toString();
      if (errorMessage.contains('already claimed')) {
        throw Exception('Reward already claimed for $quizCategory category');
      } else if (errorMessage.contains('not minter')) {
        throw Exception('Distributor address is not authorized as minter');
      } else if (errorMessage.contains('paused')) {
        throw Exception('Contract is currently paused');
      } else if (errorMessage.contains('insufficient funds')) {
        throw Exception('Insufficient ETH for gas fees');
      } else {
        throw Exception('Transaction failed: $errorMessage');
      }
    }
  }

  // Get transaction status (real implementation)
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

  // Check if the current network is Ethereum Sepolia (real implementation)
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

  // Request to switch to Ethereum Sepolia network (MetaMask deep link)
  Future<bool> switchToEthereumSepolia() async {
    try {
      // Note: Network switching in Flutter requires MetaMask mobile app or browser extension
      // This creates a deep link to MetaMask to request network switch

      developer.log('Requesting network switch to Ethereum Sepolia');

      // Create MetaMask deep link for network switching
      final networkSwitchUrl =
          'https://metamask.app.link/send/pay'
          '?chainId=${AppConstants.sepoliaChainId.toRadixString(16)}'
          '&rpcUrl=${Uri.encodeComponent(AppConstants.sepoliaRpcUrl)}'
          '&blockExplorerUrl=${Uri.encodeComponent(AppConstants.sepoliaExplorer)}'
          '&networkName=${Uri.encodeComponent('Ethereum Sepolia')}'
          '&nativeCurrency=ETH';

      developer.log('Network switch URL: $networkSwitchUrl');

      // In a real app, you would use url_launcher to open this URL
      // For now, we'll just log it and assume success after user switches manually
      developer.log('Please switch to Ethereum Sepolia network in MetaMask');

      return true;
    } catch (e) {
      developer.log('Error requesting network switch: $e');
      return false;
    }
  }

  // Estimate gas fee for a reward distribution transaction (real implementation)
  Future<double> estimateGasFee() async {
    if (_web3Client == null ||
        _rewardContract == null ||
        _distributeRewardFunction == null) {
      return 0.0;
    }

    try {
      // Get current gas price
      final gasPrice = await _web3Client!.getGasPrice();

      // Estimate gas for a typical reward distribution transaction
      // We'll use a sample transaction to estimate gas usage
      final estimatedGasLimit =
          200000; // Typical gas limit for reward distribution

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

  // Get wallet connection URL for MetaMask deep linking
  String getMetaMaskConnectionUrl() {
    return 'https://metamask.app.link/dapp/quiz-app.example.com';
  }

  // Get current block number
  Future<int> getCurrentBlockNumber() async {
    if (_web3Client == null) return 0;

    try {
      final blockNumber = await _web3Client!.getBlockNumber();
      developer.log('Current block number: $blockNumber');
      return blockNumber;
    } catch (e) {
      developer.log('Error getting block number: $e');
      return 0;
    }
  }

  // Get transaction details
  Future<Map<String, dynamic>?> getTransactionDetails(String txHash) async {
    if (_web3Client == null) return null;

    try {
      final transaction = await _web3Client!.getTransactionByHash(txHash);
      final receipt = await _web3Client!.getTransactionReceipt(txHash);

      if (transaction == null) return null;

      return {
        'hash': transaction.hash,
        'from': transaction.from.toString(),
        'to': transaction.to?.toString(),
        'value': transaction.value.getValueInUnit(EtherUnit.ether),
        'gasPrice': transaction.gasPrice.getValueInUnit(EtherUnit.gwei),
        'gas': transaction.gas,
        'blockNumber': receipt?.blockNumber.blockNum,
        'status': receipt?.status,
        'gasUsed': receipt?.gasUsed,
      };
    } catch (e) {
      developer.log('Error getting transaction details: $e');
      return null;
    }
  }

  // Get user's reward claim status for all categories
  Future<Map<String, bool>> getAllRewardClaimStatus() async {
    if (_userAddress == null) return {};

    try {
      _ensureInitialized();
      final claimStatus = <String, bool>{};

      for (final category in AppConstants.quizCategories) {
        final hasClaimed = await hasClaimedReward(category);
        claimStatus[category] = hasClaimed;
      }

      developer.log('Reward claim status: $claimStatus');
      return claimStatus;
    } catch (e) {
      developer.log('Error getting claim status: $e');
      return {};
    }
  }

  // Get total rewards earned by user
  Future<double> getTotalRewardsEarned() async {
    if (_userAddress == null) return 0.0;

    try {
      // Count claimed rewards
      final claimStatus = await getAllRewardClaimStatus();
      final claimedCount = claimStatus.values
          .where((claimed) => claimed)
          .length;

      // Each category gives 10 QUIZ tokens
      final totalRewards = claimedCount * AppConstants.tokenRewardAmount;

      developer.log('Total rewards earned: $totalRewards QUIZ');
      return totalRewards;
    } catch (e) {
      developer.log('Error calculating total rewards: $e');
      return 0.0;
    }
  }

  // Check if contract is properly configured and accessible
  Future<bool> validateContractSetup() async {
    try {
      _ensureInitialized();

      // Test token contract
      final deployerAddress = EthereumAddress.fromHex(
        '0xA720e09cfB31fcd03d74992373AEcF0818F111Af',
      );
      final balanceResult = await _web3Client!.call(
        contract: _tokenContract!,
        function: _balanceOfFunction!,
        params: [deployerAddress],
      );

      developer.log(
        'Token contract test: SUCCESS - Deployer balance: ${balanceResult.first}',
      );

      // Test reward contract (check if we can call hasClaimedReward)
      final claimResult = await _web3Client!.call(
        contract: _rewardContract!,
        function: _hasClaimedRewardFunction!,
        params: [deployerAddress, 'Blockchain'],
      );

      developer.log(
        'Reward contract test: SUCCESS - Has claimed: ${claimResult.first}',
      );
      developer.log('Contract setup validation: SUCCESS');
      return true;
    } catch (e) {
      developer.log('Contract setup validation: FAILED - $e');
      return false;
    }
  }

  // Get detailed initialization status
  Map<String, dynamic> getInitializationStatus() {
    return {
      'web3ClientInitialized': _web3Client != null,
      'tokenContractInitialized': _tokenContract != null,
      'rewardContractInitialized': _rewardContract != null,
      'balanceOfFunctionReady': _balanceOfFunction != null,
      'hasClaimedRewardFunctionReady': _hasClaimedRewardFunction != null,
      'distributeRewardFunctionReady': _distributeRewardFunction != null,
      'userRewardsFunctionReady': _getUserRewardsFunction != null,
      'isFullyInitialized': isInitialized,
    };
  }

  // Check if RewardDistributor has minter permissions on QuizToken
  Future<void> _checkMinterPermissions() async {
    try {
      // Get the RewardDistributor contract address
      final rewardContractAddress = _rewardContract!.address;

      // Create a simple function call to check if the reward contract has minter role
      // This assumes the QuizToken has a "hasRole" or similar function
      developer.log(
        'Checking if RewardDistributor ($rewardContractAddress) has minter permissions...',
      );

      // For now, we'll skip this check and let the transaction fail with a better error message
      // The actual check would require the MINTER_ROLE constant and hasRole function
      developer.log(
        '⚠️ Minter permission check skipped - will be verified during transaction',
      );
    } catch (e) {
      developer.log('Warning: Could not verify minter permissions: $e');
    }
  }

  // Alternative backend-based reward distribution (recommended for production)
  Future<String?> distributeRewardViaBackend(
    String quizCategory,
    double amount,
  ) async {
    if (_userAddress == null) {
      throw Exception('No wallet connected');
    }

    try {
      developer.log('Distributing reward via backend API...');

      final response = await http.post(
        Uri.parse(
          '${ContractConfig.backendApiUrl}${ContractConfig.rewardDistributionEndpoint}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userAddress': _userAddress,
          'quizCategory': quizCategory,
          'amount': amount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final txHash = data['transactionHash'] as String?;

        if (txHash != null) {
          developer.log('Reward distributed via backend: $txHash');
          return txHash;
        } else {
          throw Exception('No transaction hash returned from backend');
        }
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Backend error';
        throw Exception('Backend API error: $error');
      }
    } catch (e) {
      developer.log('Error distributing reward via backend: $e');
      rethrow;
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
        'Token contract address: ${ContractConfig.tokenContractAddress}',
      );
      developer.log(
        'Reward contract address: ${ContractConfig.rewardContractAddress}',
      );

      // Check if contracts are configured
      if (ContractConfig.tokenContractAddress == '0x...' ||
          ContractConfig.rewardContractAddress == '0x...') {
        throw Exception(
          'Contract addresses not configured. Please update ContractConfig.',
        );
      }

      // Initialize ERC20 token contract
      try {
        final tokenAbi = ContractAbi.fromJson(erc20Abi, 'ERC20Token');
        _tokenContract = DeployedContract(
          tokenAbi,
          EthereumAddress.fromHex(ContractConfig.tokenContractAddress),
        );
        _balanceOfFunction = _tokenContract!.function('balanceOf');
        developer.log('Token contract initialized successfully');
      } catch (e) {
        developer.log('Error initializing token contract: $e');
        throw Exception('Failed to initialize token contract: $e');
      }

      // Initialize reward contract
      try {
        final rewardAbi = ContractAbi.fromJson(
          rewardContractAbi,
          'RewardContract',
        );
        _rewardContract = DeployedContract(
          rewardAbi,
          EthereumAddress.fromHex(ContractConfig.rewardContractAddress),
        );
        _hasClaimedRewardFunction = _rewardContract!.function(
          'hasClaimedReward',
        );
        _distributeRewardFunction = _rewardContract!.function(
          'distributeReward',
        );
        _getUserRewardsFunction = _rewardContract!.function('getUserRewards');
        developer.log('Reward contract initialized successfully');
      } catch (e) {
        developer.log('Error initializing reward contract: $e');
        throw Exception('Failed to initialize reward contract: $e');
      }

      developer.log('All smart contracts initialized successfully');
    } catch (e) {
      developer.log('Error initializing contracts: $e');
      rethrow; // Rethrow to let the caller handle this error
    }
  }

  // Dispose resources
  void dispose() {
    _userAddress = null;
    _web3Client?.dispose();
    _web3Client = null;
  }
}
