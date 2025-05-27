const hre = require("hardhat");

async function main() {
    console.log("🚀 Deploying to REAL TESTNET for actual transactions!\n");

    // Get network info
    const network = hre.network.name;
    console.log(`📡 Deploying to network: ${network}`);
    console.log(`⛽ Gas price: ${hre.ethers.formatUnits((await hre.ethers.provider.getFeeData()).gasPrice || 0, "gwei")} gwei`);

    // Get deployer info
    const [deployer] = await hre.ethers.getSigners();
    console.log(`👑 Deployer address: ${deployer.address}`);
    console.log(`💰 Deployer balance: ${hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address))} ETH\n`);

    // Deploy GuessToken first
    console.log("📦 Deploying GuessToken...");
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = await GuessToken.deploy();
    await guessToken.waitForDeployment();

    const tokenAddress = await guessToken.getAddress();
    console.log("✅ GuessToken deployed to:", tokenAddress);

    // Deploy NumberGuessingGame
    console.log("\n📦 Deploying NumberGuessingGame...");
    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const numberGuessingGame = await NumberGuessingGame.deploy(tokenAddress);
    await numberGuessingGame.waitForDeployment();

    const gameAddress = await numberGuessingGame.getAddress();
    console.log("✅ NumberGuessingGame deployed to:", gameAddress);

    // Setup token approvals for the game contract
    console.log("\n🔐 Setting up token approvals...");
    const rewardPool = hre.ethers.parseEther("50000"); // 50k tokens for rewards
    const tx = await guessToken.approve(gameAddress, rewardPool);
    await tx.wait();
    console.log("✅ Game contract approved to spend tokens for rewards!");

    // Get deployment info
    const ownerBalance = await guessToken.balanceOf(deployer.address);
    const entryFee = await numberGuessingGame.getEntryFee();

    console.log("\n📊 DEPLOYMENT COMPLETE!");
    console.log("=".repeat(70));
    console.log(`🪙 GuessToken: ${tokenAddress}`);
    console.log(`🎮 NumberGuessingGame: ${gameAddress}`);
    console.log(`👑 Owner: ${deployer.address}`);
    console.log(`💰 Owner balance: ${hre.ethers.formatEther(ownerBalance)} GUESS tokens`);
    console.log(`💸 Entry fee: ${hre.ethers.formatEther(entryFee)} GUESS tokens`);

    // Network-specific explorer links
    const explorers = {
        goerli: "https://goerli.etherscan.io",
        sepolia: "https://sepolia.etherscan.io",
        mumbai: "https://mumbai.polygonscan.com",
        polygon: "https://polygonscan.com",
        bsc: "https://bscscan.com",
        bscTestnet: "https://testnet.bscscan.com",
        arbitrum: "https://arbiscan.io",
        arbitrumGoerli: "https://goerli.arbiscan.io"
    };

    const explorerUrl = explorers[network] || "https://etherscan.io";

    console.log("\n🔍 VIEW TRANSACTIONS HERE:");
    console.log("=".repeat(70));
    console.log(`🌐 Block Explorer: ${explorerUrl}`);
    console.log(`🪙 Token Contract: ${explorerUrl}/address/${tokenAddress}`);
    console.log(`🎮 Game Contract: ${explorerUrl}/address/${gameAddress}`);
    console.log(`👑 Owner Address: ${explorerUrl}/address/${deployer.address}`);

    console.log("\n📱 HOW TO SEE YOUR GAME TRANSACTIONS:");
    console.log("=".repeat(70));
    console.log("1. 🎮 Play games using the Flutter app or web interface");
    console.log("2. 🔍 Go to the game contract URL above");
    console.log("3. 📊 Click 'Events' tab to see all GamePlayed events");
    console.log("4. 💸 Click 'Internal Txns' to see token transfers");
    console.log("5. 🎯 Filter by your address to see only your games");

    console.log("\n🎮 NEXT STEPS:");
    console.log("=".repeat(70));
    console.log("1. 💰 Get some testnet tokens for gas:");
    if (network === 'goerli') {
        console.log("   • Goerli ETH: https://goerlifaucet.com");
    } else if (network === 'sepolia') {
        console.log("   • Sepolia ETH: https://sepoliafaucet.com");
    } else if (network === 'mumbai') {
        console.log("   • Mumbai MATIC: https://faucet.polygon.technology");
    }
    console.log("2. 🎯 Update your Flutter app with these contract addresses");
    console.log("3. 🎮 Start playing games!");
    console.log("4. 🔍 Watch transactions appear in real-time on the explorer");

    console.log("\n💡 IMPORTANT: Save these addresses in your .env file!");
    console.log(`GUESS_TOKEN_ADDRESS=${tokenAddress}`);
    console.log(`GAME_CONTRACT_ADDRESS=${gameAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 