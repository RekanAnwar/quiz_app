# Web3 Number Guessing Game

A blockchain-based number guessing reward game built with Flutter and Solidity. Players guess numbers between 0-100 and earn GUESS tokens based on their accuracy.

## 🎯 Game Overview

This is a simple yet engaging blockchain game where:
- Players guess a number between 0 and 100
- A random number is generated on-chain
- Rewards are distributed based on how close the guess is to the target
- All rewards are paid in GUESS tokens (ERC-20)

## 🏆 Reward Structure

- **Perfect Guess (difference = 0)**: 50 GUESS tokens
- **Very Close (≤5 difference)**: 17.5 GUESS tokens  
- **Close (≤10 difference)**: 15 GUESS tokens
- **Moderate (≤20 difference)**: 12.5 GUESS tokens
- **Fair (≤30 difference)**: 10 GUESS tokens
- **Poor (≤40 difference)**: 5 GUESS tokens
- **Very Poor (>40 difference)**: 2.5 GUESS tokens

## 🛠 Technology Stack

### Frontend (Flutter)
- **Flutter**: Cross-platform mobile app framework
- **Provider**: State management
- **Web3Dart**: Ethereum blockchain interaction
- **Material Design 3**: Modern UI components

### Backend (Smart Contracts)
- **Solidity**: Smart contract programming language
- **Hardhat**: Development environment
- **OpenZeppelin**: Security-audited contract libraries
- **ERC-20**: Token standard for GUESS tokens

## 📱 Features

- **Wallet Integration**: Connect Web3 wallets
- **Real-time Gaming**: Instant on-chain game results
- **Token Rewards**: Earn GUESS tokens for accurate guesses
- **Game History**: Track your performance over time
- **Statistics**: View games played, total rewards, and accuracy
- **Modern UI**: Beautiful, responsive design

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.0+)
- Node.js (16+)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd guess_game
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install smart contract dependencies**
   ```bash
   cd smart-contracts
   npm install
   cd ..
   ```

### Smart Contract Deployment

1. **Configure network** (edit `smart-contracts/hardhat.config.js`)
   ```javascript
   networks: {
     sepolia: {
       url: "YOUR_RPC_URL",
       accounts: ["YOUR_PRIVATE_KEY"]
     }
   }
   ```

2. **Deploy contracts**
   ```bash
   cd smart-contracts
   npx hardhat run scripts/deploy.js --network sepolia
   ```

3. **Update contract addresses** in `lib/constants/app_constants.dart`

### Running the App

```bash
flutter run
```

## 📁 Project Structure

```
guess_game/
├── lib/
│   ├── constants/          # App constants and configuration
│   ├── models/            # Data models (GameResult)
│   ├── providers/         # State management (AppProvider)
│   ├── screens/           # UI screens
│   ├── services/          # Web3, AI, and storage services
│   └── main.dart          # App entry point
├── smart-contracts/
│   ├── contracts/         # Solidity smart contracts
│   │   ├── GuessToken.sol # ERC-20 token contract
│   │   └── NumberGuessingGame.sol # Main game contract
│   ├── scripts/           # Deployment scripts
│   └── hardhat.config.js  # Hardhat configuration
└── assets/               # Images and other assets
```

## 🔧 Smart Contracts

### GuessToken.sol
- ERC-20 token contract for GUESS tokens
- Mintable by authorized addresses (game contract)
- 1,000,000 total supply cap
- Pausable for emergency situations

### NumberGuessingGame.sol
- Main game logic contract
- Generates pseudo-random numbers (use Chainlink VRF in production)
- Calculates rewards based on guess accuracy
- Tracks user statistics and game history
- Mints GUESS tokens as rewards

## 🎮 How to Play

1. **Connect Wallet**: Link your Web3 wallet to the app
2. **Start Game**: Tap "Start Playing" on the home screen
3. **Make Guess**: Enter a number between 0-100
4. **Submit**: Confirm your guess and wait for results
5. **Earn Rewards**: Receive GUESS tokens based on accuracy
6. **Play Again**: Continue playing to improve your stats

## 🔒 Security Considerations

- Smart contracts use OpenZeppelin libraries for security
- Reentrancy protection on all state-changing functions
- Access control for administrative functions
- Pausable contracts for emergency stops

**⚠️ Note**: The current random number generation is pseudo-random and not suitable for production. Use Chainlink VRF for true randomness in live deployments.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenZeppelin for secure smart contract libraries
- Flutter team for the amazing framework
- Ethereum community for Web3 tools and resources

## 📞 Support

For questions or support, please open an issue in the GitHub repository.

---

**Happy Guessing! 🎯**
