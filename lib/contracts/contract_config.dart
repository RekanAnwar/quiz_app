import '../constants/app_constants.dart';

class ContractConfig {
  // Contract Addresses - Update these when you deploy your contracts
  static const String tokenContractAddress = AppConstants.tokenContractAddress;
  static const String rewardContractAddress =
      AppConstants.rewardContractAddress;

  // For server-side reward distribution
  // IMPORTANT: In production, this should be handled by a secure backend service
  // DO NOT store private keys in the mobile app
  // This should be implemented as an API call to your backend
  //
  // ⚠️ TESTING ONLY: Replace with your deployer's private key for testing
  // Remove this before deploying to production!
  static const String rewardDistributorPrivateKey =
      'b6bab8ea399ed398b6541ce38f510a24a0050d4290d15a26e8ae4b12bf9124aa';

  // Backend API Configuration (for production)
  // In production, replace direct contract calls with API calls to your backend
  static const String backendApiUrl = 'https://your-backend-api.com';
  static const String rewardDistributionEndpoint = '/api/distribute-reward';

  // Network Configuration
  static const String rpcUrl = AppConstants.sepoliaRpcUrl;
  static const int chainId = AppConstants.sepoliaChainId;

  // Validation
  static bool get isConfigured {
    return tokenContractAddress != '0x...' &&
        rewardContractAddress != '0x...' &&
        rewardDistributorPrivateKey != 'YOUR_PRIVATE_KEY_HERE';
  }

  static String get configurationError {
    if (tokenContractAddress == '0x...') {
      return 'Token contract address not configured';
    }
    if (rewardContractAddress == '0x...') {
      return 'Reward contract address not configured';
    }
    if (rewardDistributorPrivateKey == 'YOUR_PRIVATE_KEY_HERE') {
      return 'Reward distributor private key not configured';
    }
    return '';
  }
}
