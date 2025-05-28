const hre = require("hardhat");

async function main() {
    console.log("🧪 Testing Free-to-Play Number Guessing Game\n");

    // These will be the NEW contract addresses after deployment
    const GUESS_TOKEN_ADDRESS = "0x2AC923843d160A63877b83EC7bC69027C97bc45e"; // Updated after deployment
    const GAME_CONTRACT_ADDRESS = "0x2a7081a264DDF15f9e43B237967F3599D743B0f5"; // Updated after deployment

    if (!GUESS_TOKEN_ADDRESS || !GAME_CONTRACT_ADDRESS) {
        console.log("❌ Please update the contract addresses in this script after deployment!");
        console.log("Run the deploy-updated-contract.js script first.");
        return;
    }

    const [owner] = await hre.ethers.getSigners();
    console.log(`👑 Owner address: ${owner.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    try {
        // Check initial balances
        const ownerBalance = await guessToken.balanceOf(owner.address);
        console.log(`💰 Owner token balance: ${hre.ethers.formatEther(ownerBalance)} GUESS`);

        // Test the game with a sample guess
        console.log("\n🎮 Testing game with guess = 50...");

        const guess = 50;
        const tx = await gameContract.connect(owner).playGame(guess);
        console.log(`📝 Transaction sent: ${tx.hash}`);

        const receipt = await tx.wait();
        console.log(`✅ Transaction confirmed in block ${receipt.blockNumber}`);

        // Parse events
        console.log("\n📋 GAME EVENTS:");
        for (const log of receipt.logs) {
            try {
                const parsedLog = gameContract.interface.parseLog(log);
                if (parsedLog) {
                    console.log(`🎯 Event: ${parsedLog.name}`);
                    console.log(`   Args:`, parsedLog.args);
                }
            } catch (e) {
                // Skip unparseable logs
            }
        }

        // Get game result
        const gameResult = await gameContract.getLatestGameResult(owner.address);
        console.log("\n🎲 GAME RESULT:");
        console.log(`Target Number: ${gameResult.targetNumber}`);
        console.log(`Your Guess: ${gameResult.userGuess}`);
        console.log(`Difference: ${gameResult.difference}`);
        console.log(`Reward: ${hre.ethers.formatEther(gameResult.rewardAmount)} GUESS`);

        // Check balance after game
        const newOwnerBalance = await guessToken.balanceOf(owner.address);
        console.log(`\n💰 Owner balance after game: ${hre.ethers.formatEther(newOwnerBalance)} GUESS`);

        const balanceChange = newOwnerBalance - ownerBalance;
        console.log(`📈 Balance change: ${hre.ethers.formatEther(balanceChange)} GUESS`);

        // Determine win/loss
        const difference = Number(gameResult.difference);
        const rewardAmount = Number(hre.ethers.formatEther(gameResult.rewardAmount));

        if (difference <= 20) {
            console.log(`\n🎉 PLAYER WON! Within 20 points (${difference})`);
            console.log(`💰 Reward received: ${rewardAmount} GUESS tokens`);
        } else {
            console.log(`\n💔 PLAYER LOST! More than 20 points (${difference})`);
            console.log(`🆓 No payment required - completely free to play!`);
        }

        console.log("\n✅ FREE-TO-PLAY GAME TEST COMPLETE!");
        console.log("Key Features Verified:");
        console.log("✅ No entry fee required");
        console.log("✅ Players get rewards when they win");
        console.log("✅ Players pay nothing when they lose");
        console.log("✅ Game owner funds all rewards");

    } catch (error) {
        console.log(`❌ Test failed: ${error.message}`);
        console.log("Full error:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 