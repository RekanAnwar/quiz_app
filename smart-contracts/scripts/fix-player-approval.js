const hre = require("hardhat");

async function main() {
    console.log("🔧 Fixing Player Token Approval for Entry Fees...\n");

    // Contract addresses
    const GUESS_TOKEN_ADDRESS = "0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03";
    const GAME_CONTRACT_ADDRESS = "0x647c9421FeA2f05a87Da16D927B5e6F7d5C0f667";

    // Get the signer (player)
    const [player] = await hre.ethers.getSigners();
    console.log(`👤 Player address: ${player.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    // Check current state
    console.log("📊 Current Player Status:");
    console.log("=".repeat(50));

    const playerBalance = await guessToken.balanceOf(player.address);
    console.log(`💰 Player token balance: ${hre.ethers.formatEther(playerBalance)} GUESS`);

    const playerAllowance = await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS);
    console.log(`🔐 Player's game contract allowance: ${hre.ethers.formatEther(playerAllowance)} GUESS`);

    const entryFee = await gameContract.ENTRY_FEE();
    console.log(`💸 Entry fee per game: ${hre.ethers.formatEther(entryFee)} GUESS`);

    // Calculate recommended allowance (enough for many games)
    const recommendedPlayerAllowance = hre.ethers.parseEther("1000"); // 1000 tokens = 200 games

    if (playerAllowance < entryFee) {
        console.log("\n🚨 CRITICAL ISSUE: Player cannot pay entry fees!");
        console.log(`   Player allowance: ${hre.ethers.formatEther(playerAllowance)} GUESS`);
        console.log(`   Needed per game: ${hre.ethers.formatEther(entryFee)} GUESS`);

        console.log("\n🔧 Approving player tokens for entry fees...");

        // Approve the game contract to spend player's tokens for entry fees
        const tx = await guessToken.approve(GAME_CONTRACT_ADDRESS, recommendedPlayerAllowance);
        console.log(`📝 Transaction sent: ${tx.hash}`);

        // Wait for confirmation
        const receipt = await tx.wait();
        console.log(`✅ Transaction confirmed in block: ${receipt.blockNumber}`);

        // Verify the new allowance
        const newPlayerAllowance = await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS);
        console.log(`✅ New player allowance: ${hre.ethers.formatEther(newPlayerAllowance)} GUESS`);

        console.log(`🎮 Player can now play approximately ${Math.floor(Number(hre.ethers.formatEther(newPlayerAllowance)) / Number(hre.ethers.formatEther(entryFee)))} games!`);

    } else {
        console.log("\n✅ Player allowance is sufficient for entry fees!");
    }

    // Also check owner allowance for rewards
    console.log("\n📊 Owner Status (for rewards):");
    console.log("=".repeat(50));

    const ownerAllowance = await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS);
    console.log(`🔐 Owner's game contract allowance: ${hre.ethers.formatEther(ownerAllowance)} GUESS`);

    console.log("\n🎮 TOKEN APPROVAL SUMMARY:");
    console.log("=".repeat(50));
    console.log("Two types of approvals are needed:");
    console.log("1. 👑 OWNER approves game contract → for giving rewards to winners");
    console.log("2. 👤 PLAYER approves game contract → for paying entry fees when losing");
    console.log("");
    console.log("Current status:");
    console.log(`👑 Owner allowance: ${hre.ethers.formatEther(await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS))} GUESS`);
    console.log(`👤 Player allowance: ${hre.ethers.formatEther(await guessToken.allowance(player.address, GAME_CONTRACT_ADDRESS))} GUESS`);

    console.log("\n🔍 View transactions on Etherscan:");
    console.log(`https://sepolia.etherscan.io/address/${player.address}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 