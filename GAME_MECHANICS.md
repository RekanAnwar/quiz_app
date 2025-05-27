# Number Guessing Game - Token Transfer Mechanics

## Overview
This is a blockchain-based number guessing game where players can win tokens from the game owner or lose tokens to the owner based on their guessing accuracy.

## Game Rules

### How to Play
1. **Connect your wallet** with some GUESS tokens
2. **Pay entry fee**: 5 GUESS tokens per game
3. **Make a guess**: Choose a number between 0 and 100
4. **Win or lose** based on your accuracy

### Win/Loss Logic
- **YOU WIN** 🎉 if your guess is within **20 points** of the target number
  - You receive tokens **from the game owner**
  - Reward amount depends on accuracy (see rewards table below)
  
- **YOU LOSE** 💔 if your guess is more than **20 points** away from the target
  - You pay **5 GUESS tokens** as entry fee **to the game owner**
  - No reward received

### Reward Structure (for winning guesses only)

| Accuracy | Difference | Reward Amount | Description |
|----------|------------|---------------|-------------|
| Perfect | 0 points | 50 GUESS | Base (10) + Perfect Bonus (40) |
| Excellent | 1-5 points | 17.5 GUESS | Base (10) + 75% Bonus (7.5) |
| Great | 6-10 points | 15 GUESS | Base (10) + 50% Bonus (5) |
| Good | 11-20 points | 12.5 GUESS | Base (10) + 25% Bonus (2.5) |
| Loss | 21+ points | 0 GUESS | Pay 5 GUESS entry fee |

## Token Flow

### When You Win:
```
Game Owner's Wallet → [Smart Contract] → Your Wallet
(Reward tokens transferred from owner to you)
```

### When You Lose:
```
Your Wallet → [Smart Contract] → Game Owner's Wallet  
(Entry fee transferred from you to owner)
```

## Technical Details

### Smart Contracts
- **GuessToken.sol**: ERC20 token contract for GUESS tokens
- **NumberGuessingGame.sol**: Main game logic contract

### Key Features
- **Entry Fee**: 5 GUESS tokens per game
- **Win Threshold**: Guesses within 20 points of target
- **Token Transfers**: Direct transfers between players and owner
- **No Minting**: Uses existing token supply for rewards
- **Security**: Reentrancy protection, pausable, owner controls

### Owner Setup Required
The game owner must:
1. Have sufficient GUESS tokens for rewards
2. Approve the game contract to spend tokens: `approveRewardTokens(amount)`
3. Maintain token balance for player rewards

## Getting Started

### For Players
1. Get some GUESS tokens
2. Connect wallet to the game
3. Approve the game contract to spend your tokens
4. Start playing and guessing!

### For Deployment
1. Deploy the contracts:
   ```bash
   npx hardhat run scripts/deploy.js --network <your-network>
   ```
2. The owner will automatically have tokens and approve the game contract
3. Players can start playing immediately

### Testing
Run the test script to see the game mechanics in action:
```bash
npx hardhat run scripts/test-game.js --network <your-network>
```

## Game Strategy
- **Conservative**: Guess near the middle (around 50) for decent chances
- **Risky**: Guess extreme numbers (0-10 or 90-100) for higher variance
- **Remember**: You only need to be within 20 points to win!

## Security & Fairness
- Random number generation (note: use Chainlink VRF in production)
- All transactions are on-chain and verifiable
- Smart contract handles all token transfers automatically
- Owner cannot manipulate game results

---

**Have fun playing and may your guesses be accurate!** 🎯 