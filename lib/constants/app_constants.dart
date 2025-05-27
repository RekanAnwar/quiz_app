class AppConstants {
  // Ethereum Sepolia Testnet Configuration
  static const String sepoliaRpcUrl =
      'https://ethereum-sepolia-rpc.publicnode.com';
  static const int sepoliaChainId = 11155111;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;

  // Colors
  static const int primaryColorValue = 0xFF4CAF50;

  // Storage Keys
  static const String walletAddressKey = 'wallet_address';

  // Contract Configuration - REAL DEPLOYED CONTRACTS ON SEPOLIA
  static const String guessTokenContractAddress =
      '0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03'; // GuessToken (ERC-20)
  static const String gameContractAddress =
      '0x647c9421FeA2f05a87Da16D927B5e6F7d5C0f667'; // NumberGuessingGame
}
