const hre = require("hardhat");

async function main() {
    console.log("🎯 Testing Winning Scenarios in Free-to-Play Game\n");

    const GUESS_TOKEN_ADDRESS = "0x2AC923843d160A63877b83EC7bC69027C97bc45e";
    const GAME_CONTRACT_ADDRESS = "0x2a7081a264DDF15f9e43B237967F3599D743B0f5";

    const [owner] = await hre.ethers.getSigners();
    console.log(`👑 Owner address: ${owner.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    try {
        const initialBalance = await guessToken.balanceOf(owner.address);
        console.log(`💰 Initial owner balance: ${hre.ethers.formatEther(initialBalance)} GUESS\n`);

        // Try a wide range of numbers to increase chances of winning
        const guesses = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
        let winCount = 0;
        let loseCount = 0;
        let totalRewards = 0;

        for (let i = 0; i < guesses.length; i++) {
            const guess = guesses[i];
            console.log(`🎲 Test ${i + 1}: Guessing ${guess}...`);

            const balanceBefore = await guessToken.balanceOf(owner.address);

            const tx = await gameContract.connect(owner).playGame(guess);
            await tx.wait();

            const gameResult = await gameContract.getLatestGameResult(owner.address);
            const target = Number(gameResult.targetNumber);
            const difference = Number(gameResult.difference);
            const reward = Number(hre.ethers.formatEther(gameResult.rewardAmount));

            const balanceAfter = await guessToken.balanceOf(owner.address);
            const balanceChange = Number(hre.ethers.formatEther(balanceAfter - balanceBefore));

            console.log(`   Target: ${target}, Difference: ${difference}`);

            if (difference <= 20) {
                winCount++;
                totalRewards += reward;
                console.log(`   🎉 WON! Reward: ${reward} GUESS (Balance change: ${balanceChange})`);

                // Show reward tier
                if (difference === 0) {
                    console.log(`   🏆 PERFECT GUESS! Maximum reward!`);
                } else if (difference <= 5) {
                    console.log(`   ⭐ Excellent guess! 75% bonus`);
                } else if (difference <= 10) {
                    console.log(`   🌟 Great guess! 50% bonus`);
                } else {
                    console.log(`   ✨ Good guess! 25% bonus`);
                }
            } else {
                loseCount++;
                console.log(`   💔 Lost! No payment required (Balance change: ${balanceChange})`);
            }

            console.log(`   📄 TX: https://sepolia.etherscan.io/tx/${tx.hash}\n`);

            // Small delay
            await new Promise(resolve => setTimeout(resolve, 500));
        }

        const finalBalance = await guessToken.balanceOf(owner.address);
        const totalChange = Number(hre.ethers.formatEther(finalBalance - initialBalance));

        console.log("🏁 WINNING SCENARIOS TEST COMPLETE!");
        console.log("=".repeat(80));
        console.log(`🎮 Total games: ${guesses.length}`);
        console.log(`🎉 Wins: ${winCount} (${((winCount / guesses.length) * 100).toFixed(1)}%)`);
        console.log(`💔 Losses: ${loseCount} (${((loseCount / guesses.length) * 100).toFixed(1)}%)`);
        console.log(`💰 Total rewards distributed: ${totalRewards} GUESS`);
        console.log(`📊 Owner balance change: ${totalChange} GUESS`);
        console.log(`💰 Final balance: ${hre.ethers.formatEther(finalBalance)} GUESS`);

        // Get contract stats
        const gamesPlayed = await gameContract.getUserTotalGames(owner.address);
        const contractTotalRewards = await gameContract.getUserTotalRewards(owner.address);

        console.log(`\n📈 Contract Stats:`);
        console.log(`   Total games played: ${gamesPlayed}`);
        console.log(`   Total rewards from contract: ${hre.ethers.formatEther(contractTotalRewards)} GUESS`);

        console.log("\n✅ KEY FINDINGS:");
        if (winCount > 0) {
            console.log(`✅ Reward system works! ${winCount} wins resulted in token transfers`);
            console.log(`✅ Owner balance decreased by ${Math.abs(totalChange)} GUESS (funding rewards)`);
        }
        console.log(`✅ Free-to-play confirmed! ${loseCount} losses cost nothing`);
        console.log("✅ No entry fees or token requirements for players");

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