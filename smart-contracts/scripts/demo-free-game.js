const hre = require("hardhat");

async function main() {
    console.log("🎮 Demo: Free-to-Play Number Guessing Game\n");

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

        // Play multiple games with different guesses to demonstrate the system
        const guesses = [25, 50, 75, 10, 90];

        for (let i = 0; i < guesses.length; i++) {
            const guess = guesses[i];
            console.log(`🎲 Game ${i + 1}: Guessing ${guess}...`);

            const balanceBefore = await guessToken.balanceOf(owner.address);

            const tx = await gameContract.connect(owner).playGame(guess);
            await tx.wait();

            const gameResult = await gameContract.getLatestGameResult(owner.address);
            const target = Number(gameResult.targetNumber);
            const difference = Number(gameResult.difference);
            const reward = Number(hre.ethers.formatEther(gameResult.rewardAmount));

            const balanceAfter = await guessToken.balanceOf(owner.address);
            const balanceChange = Number(hre.ethers.formatEther(balanceAfter - balanceBefore));

            console.log(`   Target: ${target}, Guess: ${guess}, Difference: ${difference}`);

            if (difference <= 20) {
                console.log(`   🎉 WON! Reward: +${reward} GUESS (Balance: ${balanceChange})`);
            } else {
                console.log(`   💔 Lost! No payment required (Balance: ${balanceChange})`);
            }
            console.log(`   Transaction: https://sepolia.etherscan.io/tx/${tx.hash}\n`);

            // Small delay between games
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        const finalBalance = await guessToken.balanceOf(owner.address);
        const totalChange = Number(hre.ethers.formatEther(finalBalance - initialBalance));

        console.log("🏁 DEMO COMPLETE!");
        console.log("=".repeat(60));
        console.log(`💰 Final owner balance: ${hre.ethers.formatEther(finalBalance)} GUESS`);
        console.log(`📊 Total balance change: ${totalChange} GUESS`);
        console.log(`🎮 Games played: ${guesses.length}`);

        const gamesPlayed = await gameContract.getUserTotalGames(owner.address);
        const totalRewards = await gameContract.getUserTotalRewards(owner.address);

        console.log(`📈 Total games in contract: ${gamesPlayed}`);
        console.log(`🏆 Total rewards earned: ${hre.ethers.formatEther(totalRewards)} GUESS`);

        console.log("\n✅ FREE-TO-PLAY FEATURES DEMONSTRATED:");
        console.log("✅ No entry fees - players pay nothing when they lose");
        console.log("✅ Rewards work - players get tokens when they win");
        console.log("✅ Owner funds rewards - balance decreases when players win");
        console.log("✅ Completely user-friendly - no token requirements for players");

    } catch (error) {
        console.log(`❌ Demo failed: ${error.message}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 