const { ethers } = require("hardhat");

async function main() {
    console.log("🔧 Checking and fixing minter permissions...\n");

    // Contract addresses
    const tokenAddress = "0x716666A410b13846f86fa693313f76C22fFfF637";
    const rewardAddress = "0x1Db0fBAd7898103a9D57E86a89D288554Efc3523";

    const [deployer] = await ethers.getSigners();
    console.log("Using account:", deployer.address);

    // Get contract instances
    const QuizToken = await ethers.getContractFactory("QuizToken");
    const quizToken = QuizToken.attach(tokenAddress);

    console.log("📋 Contract Status:");
    console.log("- QuizToken:", tokenAddress);
    console.log("- RewardDistributor:", rewardAddress);

    try {
        // Check if RewardDistributor has minter permissions
        console.log("\n🔍 Checking minter permissions...");

        const isMinter = await quizToken.minters(rewardAddress);
        console.log("RewardDistributor is minter:", isMinter);

        if (!isMinter) {
            console.log("\n❌ RewardDistributor does NOT have minter permissions!");
            console.log("🔧 Adding minter permissions...");

            const tx = await quizToken.addMinter(rewardAddress);
            await tx.wait();

            console.log("✅ Minter permissions granted!");
            console.log("Transaction hash:", tx.hash);

            // Verify again
            const isMinterNow = await quizToken.minters(rewardAddress);
            console.log("Verification - RewardDistributor is minter:", isMinterNow);
        } else {
            console.log("✅ RewardDistributor already has minter permissions!");
        }

        // Check token supply and balances
        console.log("\n📊 Token Information:");
        const totalSupply = await quizToken.totalSupply();
        const deployerBalance = await quizToken.balanceOf(deployer.address);

        console.log("Total Supply:", ethers.formatEther(totalSupply), "QUIZ");
        console.log("Deployer Balance:", ethers.formatEther(deployerBalance), "QUIZ");

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