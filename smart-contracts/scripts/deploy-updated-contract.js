const hre = require("hardhat");

async function main() {
    console.log("🚀 Deploying UPDATED NumberGuessingGame Contract!");
    console.log("=".repeat(60));
    console.log("✨ NEW FEATURE: playGameForUser() - Gasless gaming for users!");
    console.log("");

    // Get network info
    const network = hre.network.name;
    console.log(`📡 Network: ${network}`);

    // Get deployer info
    const [deployer] = await hre.ethers.getSigners();
    console.log(`👑 Deployer: ${deployer.address}`);
    console.log(`💰 Balance: ${hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address))} ETH`);
    console.log("");

    // Use existing token contract
    const existingTokenAddress = "0x2AC923843d160A63877b83EC7bC69027C97bc45e";
    console.log(`🪙 Using existing GuessToken: ${existingTokenAddress}`);

    // Deploy new NumberGuessingGame with playGameForUser function
    console.log("\n📦 Deploying UPDATED NumberGuessingGame...");
    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const numberGuessingGame = await NumberGuessingGame.deploy(existingTokenAddress);
    await numberGuessingGame.waitForDeployment();

    const gameAddress = await numberGuessingGame.getAddress();
    console.log("✅ UPDATED NumberGuessingGame deployed to:", gameAddress);

    // Get token contract for approvals
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(existingTokenAddress);

    // Setup token approvals for the new game contract
    console.log("\n🔐 Setting up token approvals...");
    const rewardPool = hre.ethers.parseEther("50000"); // 50k tokens for rewards
    const tx = await guessToken.approve(gameAddress, rewardPool);
    await tx.wait();
    console.log("✅ New game contract approved to spend tokens for rewards!");

    // Get deployment info
    const ownerBalance = await guessToken.balanceOf(deployer.address);

    console.log("\n📊 DEPLOYMENT COMPLETE!");
    console.log("=".repeat(70));
    console.log(`🪙 GuessToken (existing): ${existingTokenAddress}`);
    console.log(`🎮 NumberGuessingGame (NEW): ${gameAddress}`);
    console.log(`👑 Owner: ${deployer.address}`);
    console.log(`💰 Owner balance: ${hre.ethers.formatEther(ownerBalance)} GUESS tokens`);

    console.log("\n🆕 NEW FEATURES:");
    console.log("=".repeat(50));
    console.log("✅ playGameForUser(address user, uint256 guess)");
    console.log("   • Owner pays all gas fees");
    console.log("   • Games recorded under user's address");
    console.log("   • Users receive rewards directly");
    console.log("   • Perfect gasless gaming experience!");

    console.log("\n📱 UPDATE YOUR FLUTTER APP:");
    console.log("=".repeat(50));
    console.log("1. Update contract_config.dart:");
    console.log(`   gameContractAddress = "${gameAddress}"`);
    console.log("");
    console.log("2. The app will now use playGameForUser() function");
    console.log("3. Owner pays gas, users get rewards!");

    console.log("\n🧪 TEST THE FIX:");
    console.log("=".repeat(50));
    console.log("1. Update your Flutter app with the new contract address");
    console.log("2. Connect with any user address");
    console.log("3. Play games - they will be recorded under the user's address");
    console.log("4. Users will receive rewards when they win!");

    const explorerUrl = network === 'sepolia' ? 'https://sepolia.etherscan.io' : 'https://etherscan.io';
    console.log("\n🔍 VIEW ON EXPLORER:");
    console.log(`🌐 ${explorerUrl}/address/${gameAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 