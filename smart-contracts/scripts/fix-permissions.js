const { ethers } = require("hardhat");

async function main() {
    console.log("🔧 Checking and fixing minter permissions...\n");

    // Contract addresses
    const tokenAddress = "0x716666A410b13846f86fa693313f76C22fFfF637";
    const rewardAddress = "0x1Db0fBAd7898103a9D57E86a89D288554Efc3523";

    const [deployer] = await ethers.getSigners();
    console.log("Using account:", deployer.address);

    // Get contract instances
    const GuessToken = await ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(tokenAddress);

    console.log("📋 Contract Status:");
    console.log("- GuessToken:", tokenAddress);
    console.log("- RewardDistributor:", rewardAddress);

    try {
        // Check if RewardDistributor has minter permissions
        console.log("\n🔍 Checking minter permissions...");

        const isMinter = await guessToken.minters(rewardAddress);
        console.log("RewardDistributor is minter:", isMinter);

        if (!isMinter) {
            console.log("\n❌ RewardDistributor does NOT have minter permissions!");
            console.log("🔧 Adding minter permissions...");

            const tx = await guessToken.addMinter(rewardAddress);
            await tx.wait();

            console.log("✅ Minter permissions granted!");
            console.log("Transaction hash:", tx.hash);

            // Verify again
            const isMinterNow = await guessToken.minters(rewardAddress);
            console.log("Verification - RewardDistributor is minter:", isMinterNow);
        } else {
            console.log("✅ RewardDistributor already has minter permissions!");
        }

        // Check token supply and balances
        console.log("\n📊 Token Information:");
        const totalSupply = await guessToken.totalSupply();
        const deployerBalance = await guessToken.balanceOf(deployer.address);

        console.log("Total Supply:", ethers.formatEther(totalSupply), "GUESS");
        console.log("Deployer Balance:", ethers.formatEther(deployerBalance), "GUESS");

        console.log("\n🎉 Permission check complete!");

    } catch (error) {
        console.error("❌ Error:", error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 