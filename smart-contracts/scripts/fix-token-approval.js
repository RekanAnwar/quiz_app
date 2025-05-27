const hre = require("hardhat");

async function main() {
    console.log("🔧 Checking and fixing token approval issue...\n");

    // Contract addresses (update these with your deployed contract addresses)
    const GUESS_TOKEN_ADDRESS = "0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03";
    const GAME_CONTRACT_ADDRESS = "0x647c9421FeA2f05a87Da16D927B5e6F7d5C0f667";

    // Get the signer (owner)
    const [owner] = await hre.ethers.getSigners();
    console.log(`👑 Owner address: ${owner.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    // Check current balances and allowances
    console.log("📊 Current Status:");
    console.log("=".repeat(50));

    const ownerBalance = await guessToken.balanceOf(owner.address);
    console.log(`💰 Owner token balance: ${hre.ethers.formatEther(ownerBalance)} GUESS`);

    const currentAllowance = await guessToken.allowance(owner.address, GAME_CONTRACT_ADDRESS);
    console.log(`🔐 Current allowance: ${hre.ethers.formatEther(currentAllowance)} GUESS`);

    const entryFee = await gameContract.ENTRY_FEE();
    console.log(`💸 Entry fee: ${hre.ethers.formatEther(entryFee)} GUESS`);

    // Check if we need to increase allowance
    const recommendedAllowance = hre.ethers.parseEther("10000"); // 10k tokens

    if (currentAllowance < recommendedAllowance) {
        console.log("\n🚨 ISSUE FOUND: Insufficient token allowance!");
        console.log(`   Current: ${hre.ethers.formatEther(currentAllowance)} GUESS`);
        console.log(`   Needed: ${hre.ethers.formatEther(recommendedAllowance)} GUESS`);

        console.log("\n🔧 Fixing token approval...");

        // Approve the game contract to spend owner's tokens
        const tx = await guessToken.approve(GAME_CONTRACT_ADDRESS, recommendedAllowance);
        console.log(`📝 Transaction sent: ${tx.hash}`);

        // Wait for confirmation
        const receipt = await tx.wait();
        console.log(`✅ Transaction confirmed in block: ${receipt.blockNumber}`);

        // Verify the new allowance
        const newAllowance = await guessToken.allowance(owner.address, GAME_CONTRACT_ADDRESS);
        console.log(`✅ New allowance: ${hre.ethers.formatEther(newAllowance)} GUESS`);

        console.log("\n🎉 FIXED! Players can now receive rewards when they win!");
    } else {
        console.log("\n✅ Token allowance is sufficient!");
        console.log("   Players should be able to receive rewards when they win.");
    }

    console.log("\n📊 Final Status:");
    console.log("=".repeat(50));
    console.log(`💰 Owner balance: ${hre.ethers.formatEther(ownerBalance)} GUESS`);
    console.log(`🔐 Game contract allowance: ${hre.ethers.formatEther(await guessToken.allowance(owner.address, GAME_CONTRACT_ADDRESS))} GUESS`);
    console.log(`💸 Entry fee per game: ${hre.ethers.formatEther(entryFee)} GUESS`);

    console.log("\n🎮 How the token system works:");
    console.log("=".repeat(50));
    console.log("🎯 Win (≤20 points difference): Get 12.5-50 GUESS tokens from owner");
    console.log("💔 Lose (>20 points difference): Pay 5 GUESS tokens to owner");
    console.log("🔄 Tokens flow between players and owner based on game results");

    console.log("\n🔍 View on Etherscan:");
    console.log(`https://sepolia.etherscan.io/address/${GAME_CONTRACT_ADDRESS}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 