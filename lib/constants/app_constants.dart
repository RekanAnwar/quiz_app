class AppConstants {
  // Ethereum Sepolia Testnet Configuration
  static const String sepoliaRpcUrl =
      'https://ethereum-sepolia-rpc.publicnode.com';
  static const int sepoliaChainId = 11155111;
  static const String sepoliaExplorer = 'https://sepolia.etherscan.io/';

  // Quiz Configuration
  static const int questionsPerQuiz = 5;
  static const int passingScore = 3;
  static const double tokenRewardAmount = 10.0;

  // Quiz Categories
  static const List<String> quizCategories = [
    'Blockchain',
    'Science',
    'History',
    'Technology',
    'Geography',
    'Mathematics',
  ];

  // API Configuration
  static const String openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';

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
  static const String completedQuizzesKey = 'completed_quizzes';
  static const String apiKeyKey = 'api_key';

  // Contract Configuration - Deployed on Ethereum Sepolia
  static const String tokenContractAddress =
      '0x716666A410b13846f86fa693313f76C22fFfF637'; // QuizToken (ERC-20)
  static const String rewardContractAddress =
      '0x1Db0fBAd7898103a9D57E86a89D288554Efc3523'; // QuizRewardDistributor
}
