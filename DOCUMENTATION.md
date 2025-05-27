# Web3 Number Guessing Game - Technical Documentation

## Project Overview

The Web3 Number Guessing Game is a blockchain-based application built with Flutter and Solidity where players guess numbers between 0-100 and earn GUESS tokens based on their accuracy. The game leverages Ethereum smart contracts to handle game logic and token distribution in a transparent and decentralized manner.

## Table of Contents

1. [Architecture](#architecture)
2. [Frontend (Flutter)](#frontend-flutter)
   - [Project Structure](#project-structure)
   - [Key Components](#key-components)
   - [State Management](#state-management)
   - [UI/UX Design](#uiux-design)
3. [Backend (Smart Contracts)](#backend-smart-contracts)
   - [Token Contract](#token-contract)
   - [Game Contract](#game-contract)
   - [Security Considerations](#security-considerations)
4. [Integration Layer](#integration-layer)
   - [Web3 Service](#web3-service)
   - [Storage Service](#storage-service)
5. [Getting Started](#getting-started)
   - [Prerequisites](#prerequisites)
   - [Installation](#installation)
   - [Deployment](#deployment)
6. [Game Mechanics](#game-mechanics)
   - [Gameplay](#gameplay)
   - [Reward Structure](#reward-structure)
7. [Testing](#testing)
8. [Known Issues & Limitations](#known-issues--limitations)
9. [Future Improvements](#future-improvements)

## Architecture

The project follows a client-server architecture with:

- **Client**: Flutter mobile application
- **Backend**: Ethereum blockchain with smart contracts
- **Integration**: Web3Dart library to connect the Flutter app with the blockchain

### High-Level Architecture Diagram

```
+------------------------+        +------------------------+
|                        |        |                        |
|   Flutter Application  |<------>|  Ethereum Blockchain   |
|                        |        |                        |
+------------------------+        +------------------------+
        |                                 |
        v                                 v
+------------------------+        +------------------------+
|                        |        |                        |
|    Local Storage       |        |   Smart Contracts      |
|  (SharedPreferences)   |        | (Game Logic & Tokens)  |
|                        |        |                        |
+------------------------+        +------------------------+
```

## Frontend (Flutter)

### Project Structure

```
lib/
├── constants/          # App constants and configuration
├── contracts/          # ABI definitions for smart contracts
├── models/             # Data models
├── providers/          # State management
├── screens/            # UI screens
├── services/           # Web3 and storage services
└── main.dart           # App entry point
```

### Key Components

1. **Main Application** (`main.dart`):
   - Entry point for the Flutter application
   - Configures theme, providers, and navigation
   - Initializes the application state

2. **Home Screen** (`screens/home_screen.dart`):
   - Primary user interface
   - Handles wallet connection, game play, and result display
   - Adapts UI based on game state (not started, in progress, results)

3. **Game Result Model** (`models/game_result.dart`):
   - Represents the outcome of a game
   - Stores target number, user guess, difference, reward amount, and timestamp
   - Provides helper methods for calculating accuracy and performance level

### State Management

The app uses the Provider pattern for state management:

- **AppProvider** (`providers/app_provider.dart`):
  - Centralized state container
  - Manages wallet connection state
  - Handles game state (initialization, playing, results)
  - Coordinates with Web3Service for blockchain interactions
  - Manages user settings (theme, notifications)

### UI/UX Design

- Uses Material Design 3 with customized themes for light and dark modes
- Responsive layout adapting to different screen sizes
- Interactive UI elements with appropriate feedback
- Game results visualized with color-coded indicators

## Backend (Smart Contracts)

### Token Contract

`GuessToken.sol` is an ERC-20 token contract with:

- **Token Details**:
  - Name: Guess Token
  - Symbol: GUESS
  - Decimals: 18
  - Max Supply: 1,000,000 tokens

- **Key Features**:
  - Minting capability by authorized addresses
  - Role-based access control for minters
  - Pausable for emergency situations
  - Burning functionality

### Game Contract

`NumberGuessingGame.sol` handles the core game logic:

- **Game Mechanics**:
  - Random number generation (pseudo-random for testing)
  - Guess validation and difference calculation
  - Reward calculation based on accuracy
  - Game history tracking per user

- **Key Functions**:
  - `playGame(uint256 guess)`: Processes a user's guess
  - `getUserGameHistory(address user)`: Retrieves a user's past games
  - `getLatestGameResult(address user)`: Gets the most recent game result
  - `getUserTotalRewards(address user)`: Gets total rewards earned
  - `getUserAverageAccuracy(address user)`: Calculates average guess accuracy

### Security Considerations

- Uses OpenZeppelin libraries for secure implementation patterns
- Implements reentrancy protection with ReentrancyGuard
- Includes access control for administrative functions
- Pausable functionality for emergency situations
- NOTE: The random number generation is pseudo-random and not suitable for production; Chainlink VRF is recommended for true randomness

## Integration Layer

### Web3 Service

`web3_service.dart` handles blockchain interactions:

- Initializes and manages Web3 client connection
- Loads and interacts with smart contracts
- Manages wallet connection state
- Processes transactions and retrieves blockchain data
- Handles error cases and transaction confirmations

### Storage Service

`storage_service.dart` manages local data persistence:

- Stores wallet address for reconnection
- Saves user preferences
- Manages temporary game state
- Handles user data clearing when disconnecting

## Getting Started

### Prerequisites

- Flutter SDK (3.8.0+)
- Node.js (16+)
- Hardhat for smart contract development
- Ethereum wallet (like MetaMask)
- Sepolia testnet ETH for testing

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

### Deployment

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

## Game Mechanics

### Gameplay

1. User connects their Ethereum wallet
2. User starts a new game and enters a guess between 0-100
3. Smart contract generates a random number
4. Difference between the guess and target is calculated
5. Rewards are distributed based on accuracy
6. Results are displayed to the user

### Reward Structure

| Performance | Difference | Reward |
|-------------|------------|--------|
| Perfect     | 0          | 50 GUESS tokens |
| Excellent   | ≤5         | 17.5 GUESS tokens |
| Very Good   | ≤10        | 15 GUESS tokens |
| Good        | ≤20        | 12.5 GUESS tokens |
| Fair        | ≤30        | 10 GUESS tokens |
| Poor        | ≤40        | 5 GUESS tokens |
| Very Poor   | >40        | 2.5 GUESS tokens |

#### Reward Structure Example

**Scenario**: The target number is 42

| Player | Guess | Difference | Performance | Reward |
|--------|-------|------------|------------|--------|
| Alice  | 42    | 0          | Perfect    | 50 GUESS tokens |
| Bob    | 46    | 4          | Excellent  | 17.5 GUESS tokens |
| Carol  | 51    | 9          | Very Good  | 15 GUESS tokens |
| Dave   | 60    | 18         | Good       | 12.5 GUESS tokens |
| Eve    | 72    | 30         | Fair       | 10 GUESS tokens |
| Frank  | 82    | 40         | Poor       | 5 GUESS tokens |
| Grace  | 98    | 56         | Very Poor  | 2.5 GUESS tokens |

The smart contract calculates the absolute difference between the player's guess and the target number, then awards tokens according to the established reward tiers.

## Testing

The application can be tested using:

1. **Flutter tests** for the frontend
2. **Hardhat tests** for the smart contracts
3. **Manual testing** on the Sepolia testnet

## Known Issues & Limitations

- Random number generation in the contract is not truly random (pseudo-random)
- Gas costs may be high for frequent game plays
- UI optimized primarily for mobile devices
- Limited support for older versions of Flutter

## Future Improvements

- Implement Chainlink VRF for true randomness
- Add multiplayer functionality
- Implement leader boards and tournaments
- Add social sharing features
- Support more wallet providers
- Add analytics and gameplay statistics
- Optimize gas usage for lower transaction costs 