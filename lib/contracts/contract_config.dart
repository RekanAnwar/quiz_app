import '../constants/app_constants.dart';

class ContractConfig {
  // Contract Addresses - Update these when you deploy your contracts
  static const String guessTokenContractAddress =
      AppConstants.guessTokenContractAddress;
  static const String gameContractAddress = AppConstants.gameContractAddress;

  // For server-side game management
  // IMPORTANT: In production, this should be handled by a secure backend service
  // DO NOT store private keys in the mobile app
  // This should be implemented as an API call to your backend
  //
  // ⚠️ TESTING ONLY: Replace with your deployer's private key for testing
  // Remove this before deploying to production!
  static const String gameManagerPrivateKey =
      'b6bab8ea399ed398b6541ce38f510a24a0050d4290d15a26e8ae4b12bf9124aa';

  // Backend API Configuration (for production)
  // In production, replace direct contract calls with API calls to your backend
  static const String backendApiUrl = 'https://your-backend-api.com';
  static const String gamePlayEndpoint = '/api/play-game';

  // Network Configuration
  static const String rpcUrl = AppConstants.sepoliaRpcUrl;
  static const int chainId = AppConstants.sepoliaChainId;

  // Game Configuration
  static const int minNumber = AppConstants.minNumber;
  static const int maxNumber = AppConstants.maxNumber;
  static const double baseReward = AppConstants.baseRewardAmount;

  // Validation
  static bool get isConfigured {
    return guessTokenContractAddress != '0x...' &&
        gameContractAddress != '0x...' &&
        gameManagerPrivateKey != 'YOUR_PRIVATE_KEY_HERE';
  }

  static String get configurationError {
    if (guessTokenContractAddress == '0x...') {
      return 'GUESS token contract address not configured';
    }
    if (gameContractAddress == '0x...') {
      return 'Game contract address not configured';
    }
    if (gameManagerPrivateKey == 'YOUR_PRIVATE_KEY_HERE') {
      return 'Game manager private key not configured';
    }
    return '';
  }
}
