class AppConstants {
  // Ethereum Sepolia Testnet Configuration
  static const String sepoliaRpcUrl =
      'https://ethereum-sepolia-rpc.publicnode.com';
  static const int sepoliaChainId = 11155111;
  static const String sepoliaExplorer = 'https://sepolia.etherscan.io/';

  // Game Configuration
  static const int minNumber = 0;
  static const int maxNumber = 100;
  static const double baseRewardAmount = 10.0;
  static const double perfectBonusAmount = 40.0;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;

  // Colors
  static const int primaryColorValue = 0xFF4CAF50;
  static const int accentColorValue = 0xFF8BC34A;
  static const int errorColorValue = 0xFFEF4444;
  static const int warningColorValue = 0xFFF59E0B;

  // Storage Keys
  static const String walletAddressKey = 'wallet_address';

  // Contract Configuration - Updated with deployed contract addresses
  static const String guessTokenContractAddress =
      '0x552528d609a8cb5D98a0E89439073A05e47B8527'; // GuessToken (ERC-20)
  static const String gameContractAddress =
      '0x730cFa3b471565Bf343534153Ce8895F44d35be4'; // NumberGuessingGame
}
