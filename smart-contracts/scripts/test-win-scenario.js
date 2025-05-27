const hre = require("hardhat");

async function main() {
    console.log("🎮 Testing Win Scenario - Playing a Game to Verify Rewards...\n");

    // Contract addresses
    const GUESS_TOKEN_ADDRESS = "0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03";
    const GAME_CONTRACT_ADDRESS = "0x647c9421FeA2f05a87Da16D927B5e6F7d5C0f667";

    // Get the signer (this will be both owner and player for testing)
    const [player] = await hre.ethers.getSigners();
    console.log(`🎯 Player/Owner address: ${player.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    // Check initial state
    console.log("📊 BEFORE PLAYING:");
    console.log("=".repeat(50));

    const initialBalance = await guessToken.balanceOf(player.address);
    console.log(`💰 Player balance: ${hre.ethers.formatEther(initialBalance)} GUESS`);

    const allowance = await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS);
    console.log(`🔐 Game contract allowance: ${hre.ethers.formatEther(allowance)} GUESS`);

    const entryFee = await gameContract.ENTRY_FEE();
    console.log(`💸 Entry fee: ${hre.ethers.formatEther(entryFee)} GUESS`);

    // Check total games played before
    const gamesBefore = await gameContract.userTotalGames(player.address);
    console.log(`🎮 Games played before: ${gamesBefore}`);

    // Play multiple games with different strategies to test win/lose scenarios
    const testCases = [
        { guess: 50, description: "Middle guess (50)" },
        { guess: 25, description: "Lower guess (25)" },
        { guess: 75, description: "Higher guess (75)" }
    ];

    for (let i = 0; i < testCases.length; i++) {
        const testCase = testCases[i];
        console.log(`\n🎲 GAME ${i + 1}: ${testCase.description}`);
        console.log("=".repeat(50));

        try {
            // Get balance before game
            const balanceBefore = await guessToken.balanceOf(player.address);
            console.log(`💰 Balance before: ${hre.ethers.formatEther(balanceBefore)} GUESS`);

            // Play the game
            console.log(`🎯 Playing with guess: ${testCase.guess}`);
            const tx = await gameContract.playGame(testCase.guess);
            console.log(`📝 Transaction sent: ${tx.hash}`);

            // Wait for confirmation
            const receipt = await tx.wait();
            console.log(`✅ Transaction confirmed in block: ${receipt.blockNumber}`);

            // Get balance after game
            const balanceAfter = await guessToken.balanceOf(player.address);
            console.log(`💰 Balance after: ${hre.ethers.formatEther(balanceAfter)} GUESS`);

            // Calculate change
            const balanceChange = balanceAfter - balanceBefore;
            const changeFormatted = hre.ethers.formatEther(balanceChange < 0 ? -balanceChange : balanceChange);

            if (balanceChange > 0) {
                console.log(`🎉 PLAYER WON! Received: +${changeFormatted} GUESS`);
            } else if (balanceChange < 0) {
                console.log(`💔 PLAYER LOST! Paid: -${changeFormatted} GUESS`);
            } else {
                console.log(`🤔 NO BALANCE CHANGE - Something might be wrong`);
            }

            // Get the latest game result
            try {
                const latestResult = await gameContract.getLatestGameResult(player.address);
                console.log(`📊 Game Result:`);
                console.log(`   Target: ${latestResult.targetNumber}`);
                console.log(`   Guess: ${latestResult.userGuess}`);
                console.log(`   Difference: ${latestResult.difference}`);
                console.log(`   Reward: ${hre.ethers.formatEther(latestResult.rewardAmount)} GUESS`);

                // Check if this should have been a win or loss
                const shouldWin = latestResult.difference <= 20;
                console.log(`   Should ${shouldWin ? 'WIN' : 'LOSE'} (difference ≤ 20: ${shouldWin})`);

                if (shouldWin && balanceChange <= 0) {
                    console.log(`❌ BUG DETECTED: Should have won but didn't receive tokens!`);
                } else if (!shouldWin && balanceChange >= 0) {
                    console.log(`❌ BUG DETECTED: Should have lost but didn't pay entry fee!`);
                } else {
                    console.log(`✅ Game result matches expected outcome`);
                }

            } catch (error) {
                console.log(`❌ Error getting game result: ${error.message}`);
            }

            // Parse transaction logs to see events
            console.log(`📋 Transaction Events:`);
            for (const log of receipt.logs) {
                try {
                    if (log.address.toLowerCase() === GAME_CONTRACT_ADDRESS.toLowerCase()) {
                        const parsed = gameContract.interface.parseLog(log);
                        if (parsed) {
                            console.log(`   ${parsed.name}:`, parsed.args);
                        }
                    }
                } catch (e) {
                    // Skip unparseable logs
                }
            }

        } catch (error) {
            console.log(`❌ Game failed: ${error.message}`);

            // Check if it's an allowance issue
            if (error.message.includes('transfer amount exceeds allowance') ||
                error.message.includes('insufficient allowance')) {
                console.log(`🔧 This looks like an allowance issue!`);

                // Check current allowance
                const currentAllowance = await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS);
                console.log(`   Current allowance: ${hre.ethers.formatEther(currentAllowance)} GUESS`);

                // Check if player needs to approve the game contract to spend their tokens
                console.log(`   Player needs to approve game contract to spend their tokens for entry fees`);
            }
        }

        // Wait a bit between games
        if (i < testCases.length - 1) {
            console.log(`⏳ Waiting 2 seconds before next game...`);
            await new Promise(resolve => setTimeout(resolve, 2000));
        }
    }

    // Final summary
    console.log(`\n📊 FINAL SUMMARY:`);
    console.log("=".repeat(50));

    const finalBalance = await guessToken.balanceOf(player.address);
    const totalChange = finalBalance - initialBalance;
    const gamesAfter = await gameContract.userTotalGames(player.address);

    console.log(`💰 Initial balance: ${hre.ethers.formatEther(initialBalance)} GUESS`);
    console.log(`💰 Final balance: ${hre.ethers.formatEther(finalBalance)} GUESS`);
    console.log(`📈 Total change: ${totalChange >= 0 ? '+' : ''}${hre.ethers.formatEther(totalChange)} GUESS`);
    console.log(`🎮 Games played: ${gamesAfter - gamesBefore}`);

    console.log(`\n🔍 View transactions on Etherscan:`);
    console.log(`https://sepolia.etherscan.io/address/${player.address}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 