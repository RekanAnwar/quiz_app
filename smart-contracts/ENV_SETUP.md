# Environment Setup for Real Testnet Deployment

## 1. Create `.env` file in smart-contracts folder:

```bash
# Private key for your wallet (NEVER share this!)
# You can get this from MetaMask: Account Details > Export Private Key
PRIVATE_KEY=your_private_key_here

# Optional: API keys for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
BSCSCAN_API_KEY=your_bscscan_api_key
SCROLL_SCAN_API_KEY=your_scrollscan_api_key

# Contract addresses (filled after deployment)
GUESS_TOKEN_ADDRESS=
GAME_CONTRACT_ADDRESS=
```

## 2. Get Testnet Tokens:

### Sepolia ETH (Recommended):
- https://sepoliafaucet.com/
- https://www.infura.io/faucet/sepolia

### Mumbai MATIC:
- https://faucet.polygon.technology/

### Goerli ETH:
- https://goerlifaucet.com/

### BSC Testnet BNB:
- https://testnet.binance.org/faucet-smart

## 3. Deploy Commands:

```bash
# Deploy to Sepolia (Recommended)
npx hardhat run scripts/deploy-testnet.js --network sepolia

# Deploy to Mumbai Polygon
npx hardhat run scripts/deploy-testnet.js --network mumbai

# Deploy to BSC Testnet
npx hardhat run scripts/deploy-testnet.js --network bscTestnet
```

## 4. View Transactions:

After deployment, you'll get contract addresses. Visit:

- **Sepolia**: https://sepolia.etherscan.io/address/YOUR_CONTRACT_ADDRESS
- **Mumbai**: https://mumbai.polygonscan.com/address/YOUR_CONTRACT_ADDRESS  
- **BSC Testnet**: https://testnet.bscscan.com/address/YOUR_CONTRACT_ADDRESS

## 5. What You'll See:

1. **Contract Creation Transaction** (when you deploy)
2. **Token Transfer Events** (when players win/lose)
3. **Game Events** (every time someone plays)
4. **Player addresses** and **amounts won/lost**
5. **Transaction hashes** for each game

## 🔒 Security Warning:
NEVER commit your `.env` file to git! It contains your private key. 