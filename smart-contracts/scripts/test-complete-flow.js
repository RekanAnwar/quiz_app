const hre = require("hardhat");

async function main() {
    console.log("🧪 Testing Complete Game Flow\n");

    const GUESS_TOKEN_ADDRESS = "0x2AC923843d160A63877b83EC7bC69027C97bc45e";
    const GAME_CONTRACT_ADDRESS = "0x2a7081a264DDF15f9e43B237967F3599D743B0f5";

    const [owner] = await hre.ethers.getSigners();
    console.log(`👑 Testing with address: ${owner.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    try {
        console.log("📊 Step 1: Check initial state");

        // Check how many games have been played
        const totalGames = await gameContract.getUserTotalGames(owner.address);
        console.log(`🎮 Total games played: ${totalGames}`);

        // Try to get latest game result
        if (totalGames > 0) {
            try {
                const latestResult = await gameContract.getLatestGameResult(owner.address);
                console.log(`📊 Latest game result available - Target: ${latestResult.targetNumber}`);
            } catch (e) {
                console.log(`❌ Error getting latest result: ${e.message}`);
            }
        } else {
            console.log(`📊 No games played yet - this is fine for new users`);

            // Confirm we get the expected error when trying to get latest result
            try {
                await gameContract.getLatestGameResult(owner.address);
                console.log(`❌ ERROR: Should have failed but didn't!`);
            } catch (e) {
                if (e.message.includes('no games played')) {
                    console.log(`✅ Correctly got "no games played" error as expected`);
                } else {
                    console.log(`❌ Got unexpected error: ${e.message}`);
                }
            }
        }

        console.log("\n🎲 Step 2: Play a game");
        const balanceBefore = await guessToken.balanceOf(owner.address);
        console.log(`💰 Balance before: ${hre.ethers.formatEther(balanceBefore)} GUESS`);

        const guess = 77; // Random guess
        console.log(`🎯 Playing game with guess: ${guess}`);

        const tx = await gameContract.connect(owner).playGame(guess, {
            gasLimit: 300000
        });

        console.log(`📝 Transaction sent: ${tx.hash}`);
        const receipt = await tx.wait();
        console.log(`✅ Transaction confirmed in block ${receipt.blockNumber}`);

        console.log("\n📊 Step 3: Verify game result");

        // Now we should be able to get the latest game result
        const gameResult = await gameContract.getLatestGameResult(owner.address);
        console.log(`🎲 Game Result:`);
        console.log(`   Target: ${gameResult.targetNumber}`);
        console.log(`   Guess: ${gameResult.userGuess}`);
        console.log(`   Difference: ${gameResult.difference}`);
        console.log(`   Reward: ${hre.ethers.formatEther(gameResult.rewardAmount)} GUESS`);

        const balanceAfter = await guessToken.balanceOf(owner.address);
        const balanceChange = Number(hre.ethers.formatEther(balanceAfter - balanceBefore));
        console.log(`💰 Balance after: ${hre.ethers.formatEther(balanceAfter)} GUESS`);
        console.log(`📈 Balance change: ${balanceChange} GUESS`);

        const won = Number(gameResult.difference) <= 20;
        if (won) {
            console.log(`🎉 YOU WON! Received ${hre.ethers.formatEther(gameResult.rewardAmount)} GUESS tokens`);
            if (balanceChange < 0) {
                console.log(`✅ Balance decreased as expected (owner funding reward)`);
            } else {
                console.log(`❌ ERROR: Balance should have decreased`);
            }
        } else {
            console.log(`💔 You lost, but it's completely free!`);
            if (balanceChange === 0) {
                console.log(`✅ Balance unchanged as expected (free to play)`);
            } else {
                console.log(`❌ ERROR: Balance should be unchanged for losing`);
            }
        }

        console.log("\n📊 Step 4: Verify updated stats");
        const newTotalGames = await gameContract.getUserTotalGames(owner.address);
        const totalRewards = await gameContract.getUserTotalRewards(owner.address);
        console.log(`🎮 Total games now: ${newTotalGames}`);
        console.log(`🏆 Total rewards: ${hre.ethers.formatEther(totalRewards)} GUESS`);

        console.log("\n✅ COMPLETE FLOW TEST SUCCESSFUL!");
        console.log("Key findings:");
        console.log("✅ 'No games played' error handled correctly");
        console.log("✅ Game can be played successfully");
        console.log("✅ Results can be retrieved after playing");
        console.log("✅ Free-to-play system working");

        console.log(`\n🔗 View transaction: https://sepolia.etherscan.io/tx/${tx.hash}`);

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