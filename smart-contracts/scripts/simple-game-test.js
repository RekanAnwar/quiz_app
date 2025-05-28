const hre = require("hardhat");

async function main() {
    console.log("🎮 Simple Game Test\n");

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
        // Check initial state
        console.log("📊 Initial State:");
        const ownerBalance = await guessToken.balanceOf(owner.address);
        console.log(`💰 Owner balance: ${hre.ethers.formatEther(ownerBalance)} GUESS`);

        const allowance = await guessToken.allowance(owner.address, GAME_CONTRACT_ADDRESS);
        console.log(`🔐 Allowance: ${hre.ethers.formatEther(allowance)} GUESS`);

        // Check if any games have been played
        let totalGames;
        try {
            totalGames = await gameContract.getUserTotalGames(owner.address);
            console.log(`🎮 Previous games: ${totalGames}`);
        } catch (e) {
            console.log(`🎮 Previous games: 0 (first time)`);
            totalGames = 0;
        }

        // Try to get latest game result (should fail if no games)
        if (totalGames > 0) {
            try {
                const latestResult = await gameContract.getLatestGameResult(owner.address);
                console.log(`📊 Latest game target: ${latestResult.targetNumber}`);
            } catch (e) {
                console.log(`📊 Cannot get latest result: ${e.message}`);
            }
        } else {
            console.log(`📊 No previous games to show results for`);
        }

        console.log("\n🎲 Playing a game with guess = 42...");

        // Use higher gas limit to ensure transaction doesn't fail
        const tx = await gameContract.connect(owner).playGame(42, {
            gasLimit: 500000
        });

        console.log(`📝 Transaction hash: ${tx.hash}`);
        console.log(`⏳ Waiting for confirmation...`);

        const receipt = await tx.wait();
        console.log(`✅ Transaction confirmed in block ${receipt.blockNumber}`);
        console.log(`⛽ Gas used: ${receipt.gasUsed}`);

        // Check if transaction was successful
        if (receipt.status === 1) {
            console.log(`✅ Transaction was successful!`);

            // Get the latest game result
            const gameResult = await gameContract.getLatestGameResult(owner.address);
            console.log(`\n🎲 Game Result:`);
            console.log(`   Target: ${gameResult.targetNumber}`);
            console.log(`   Guess: ${gameResult.userGuess}`);
            console.log(`   Difference: ${gameResult.difference}`);
            console.log(`   Reward: ${hre.ethers.formatEther(gameResult.rewardAmount)} GUESS`);

            const newBalance = await guessToken.balanceOf(owner.address);
            const balanceChange = Number(hre.ethers.formatEther(newBalance - ownerBalance));
            console.log(`   Balance change: ${balanceChange} GUESS`);

            if (Number(gameResult.difference) <= 20) {
                console.log(`🎉 YOU WON! Reward received.`);
            } else {
                console.log(`💔 You lost, but it's free to play!`);
            }

        } else {
            console.log(`❌ Transaction failed with status: ${receipt.status}`);
        }

        console.log(`\n🔗 View on Etherscan: https://sepolia.etherscan.io/tx/${tx.hash}`);

    } catch (error) {
        console.log(`❌ Error: ${error.message}`);

        if (error.message.includes("insufficient funds")) {
            console.log("💡 Issue: Insufficient ETH for gas fees");
        } else if (error.message.includes("execution reverted")) {
            console.log("💡 Issue: Contract execution reverted - check contract logic");
        } else if (error.message.includes("nonce")) {
            console.log("💡 Issue: Nonce problem - try again");
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 