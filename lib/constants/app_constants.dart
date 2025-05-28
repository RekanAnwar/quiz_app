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
      '0x2a7081a264DDF15f9e43B237967F3599D743B0f5'; // NumberGuessingGame (Free-to-Play)
}
