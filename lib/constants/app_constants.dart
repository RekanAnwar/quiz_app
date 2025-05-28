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

  // Contract Configuration - FREE-TO-PLAY CONTRACTS ON SEPOLIA
  static const String guessTokenContractAddress =
      '0x2AC923843d160A63877b83EC7bC69027C97bc45e'; // GuessToken (ERC-20)
  static const String gameContractAddress =
      '0xa106300c8eFaF15C7e2487B3607c4d265f8b0573'; // NumberGuessingGame (Updated with playGameForUser)
}
