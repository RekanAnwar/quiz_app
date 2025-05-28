const hre = require("hardhat");

async function main() {
    console.log("🚀 Deploying Updated Free-to-Play Number Guessing Game...\n");

    const [deployer] = await hre.ethers.getSigners();
    console.log(`👑 Deploying with account: ${deployer.address}`);

    // Check deployer balance
    const balance = await deployer.provider.getBalance(deployer.address);
    console.log(`💰 Account balance: ${hre.ethers.formatEther(balance)} ETH\n`);

    try {
        // Deploy GuessToken first
        console.log("📝 Deploying GuessToken...");
        const GuessToken = await hre.ethers.getContractFactory("GuessToken");
        const guessToken = await GuessToken.deploy();
        await guessToken.waitForDeployment();

        const guessTokenAddress = await guessToken.getAddress();
        console.log(`✅ GuessToken deployed to: ${guessTokenAddress}`);

        // Deploy NumberGuessingGame
        console.log("\n📝 Deploying NumberGuessingGame...");
        const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
        const numberGuessingGame = await NumberGuessingGame.deploy(guessTokenAddress);
        await numberGuessingGame.waitForDeployment();

        const gameAddress = await numberGuessingGame.getAddress();
        console.log(`✅ NumberGuessingGame deployed to: ${gameAddress}`);

        // Check initial token balance
        const ownerTokenBalance = await guessToken.balanceOf(deployer.address);
        console.log(`\n💰 Owner initial GUESS token balance: ${hre.ethers.formatEther(ownerTokenBalance)}`);

        // Approve the game contract to spend owner's tokens for rewards
        console.log("\n🔐 Setting up token approvals for game contract...");
        const approvalAmount = hre.ethers.parseEther("10000"); // 10,000 tokens
        const approveTx = await guessToken.connect(deployer).approve(gameAddress, approvalAmount);
        await approveTx.wait();
        console.log(`✅ Approved ${hre.ethers.formatEther(approvalAmount)} GUESS tokens for game contract`);

        // Verify the approval
        const allowance = await guessToken.allowance(deployer.address, gameAddress);
        console.log(`🔍 Current allowance: ${hre.ethers.formatEther(allowance)} GUESS tokens`);

        console.log("\n🎉 DEPLOYMENT SUCCESSFUL!");
        console.log("=".repeat(80));
        console.log(`🪙 GuessToken Contract: ${guessTokenAddress}`);
        console.log(`🎮 NumberGuessingGame Contract: ${gameAddress}`);
        console.log(`👑 Owner Address: ${deployer.address}`);
        console.log(`💰 Owner Token Balance: ${hre.ethers.formatEther(ownerTokenBalance)} GUESS`);
        console.log(`🔐 Game Contract Allowance: ${hre.ethers.formatEther(allowance)} GUESS`);

        console.log("\n📋 UPDATE YOUR FLUTTER APP:");
        console.log("=".repeat(80));
        console.log("Update lib/constants/app_constants.dart with:");
        console.log(`static const String guessTokenAddress = '${guessTokenAddress}';`);
        console.log(`static const String numberGuessingGameAddress = '${gameAddress}';`);

        console.log("\n🎮 GAME FEATURES:");
        console.log("=".repeat(80));
        console.log("✅ Completely FREE to play - no entry fees!");
        console.log("✅ Players get rewards when they win (within 20 points)");
        console.log("✅ Players pay nothing when they lose");
        console.log("✅ Owner funds all rewards from their token balance");
        console.log("✅ No need for players to have tokens or approve contracts");

        console.log("\n🔗 ETHERSCAN LINKS:");
        console.log("=".repeat(80));
        console.log(`🪙 GuessToken: https://sepolia.etherscan.io/address/${guessTokenAddress}`);
        console.log(`🎮 Game Contract: https://sepolia.etherscan.io/address/${gameAddress}`);
        console.log(`👑 Owner: https://sepolia.etherscan.io/address/${deployer.address}`);

    } catch (error) {
        console.error("\n❌ Deployment failed:", error);
        process.exit(1);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 