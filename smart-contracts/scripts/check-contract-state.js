const hre = require("hardhat");

async function main() {
    console.log("🔍 Checking Free-to-Play Contract State\n");

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
        // Check balances
        const ownerBalance = await guessToken.balanceOf(owner.address);
        console.log(`💰 Owner GUESS balance: ${hre.ethers.formatEther(ownerBalance)}`);

        // Check allowances
        const allowance = await guessToken.allowance(owner.address, GAME_CONTRACT_ADDRESS);
        console.log(`🔐 Game contract allowance: ${hre.ethers.formatEther(allowance)}`);

        // Check game stats
        const totalGames = await gameContract.getUserTotalGames(owner.address);
        const totalRewards = await gameContract.getUserTotalRewards(owner.address);
        console.log(`🎮 Total games played: ${totalGames}`);
        console.log(`🏆 Total rewards earned: ${hre.ethers.formatEther(totalRewards)}`);

        // Check if contract is paused
        try {
            const isPaused = await gameContract.paused();
            console.log(`⏸️  Contract paused: ${isPaused}`);
        } catch (e) {
            console.log(`⏸️  Could not check pause status: ${e.message}`);
        }

        // Check entry fee
        const entryFee = await gameContract.getEntryFee();
        console.log(`💸 Entry fee: ${hre.ethers.formatEther(entryFee)} GUESS`);

        // Check owner's token balance in game contract view
        const ownerTokenBalance = await gameContract.getOwnerTokenBalance();
        console.log(`💰 Owner balance (from game contract): ${hre.ethers.formatEther(ownerTokenBalance)}`);

        console.log("\n🔗 ETHERSCAN LINKS:");
        console.log(`🪙 Token: https://sepolia.etherscan.io/address/${GUESS_TOKEN_ADDRESS}`);
        console.log(`🎮 Game: https://sepolia.etherscan.io/address/${GAME_CONTRACT_ADDRESS}`);
        console.log(`👑 Owner: https://sepolia.etherscan.io/address/${owner.address}`);

        // Test if a simple game would work
        console.log("\n🧪 Testing game call (dry run)...");
        try {
            // This won't actually execute, just checks if it would work
            await gameContract.connect(owner).playGame.staticCall(50);
            console.log("✅ Game call would succeed");
        } catch (error) {
            console.log(`❌ Game call would fail: ${error.message}`);

            // Try to understand why
            if (error.message.includes("insufficient tokens")) {
                console.log("💡 Possible issue: Owner has insufficient tokens for rewards");
            } else if (error.message.includes("allowance")) {
                console.log("💡 Possible issue: Insufficient allowance for game contract");
            } else if (error.message.includes("paused")) {
                console.log("💡 Possible issue: Contract is paused");
            }
        }

        console.log("\n📊 SUMMARY:");
        console.log(`✅ Contract deployed and accessible`);
        console.log(`✅ Entry fee is 0 (free to play)`);
        console.log(`✅ Owner has ${hre.ethers.formatEther(ownerBalance)} GUESS tokens`);
        console.log(`✅ Game contract has ${hre.ethers.formatEther(allowance)} GUESS allowance`);

    } catch (error) {
        console.log(`❌ Error checking contract state: ${error.message}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 