import '../constants/app_constants.dart';

class ContractConfig {
  static const String guessTokenContractAddress =
      AppConstants.guessTokenContractAddress;
  static const String gameContractAddress = AppConstants.gameContractAddress;

  static const String gameManagerPrivateKey =
      'b6bab8ea399ed398b6541ce38f510a24a0050d4290d15a26e8ae4b12bf9124aa';

  // Network Configuration
  static const String rpcUrl = AppConstants.sepoliaRpcUrl;
  static const int chainId = AppConstants.sepoliaChainId;
}
