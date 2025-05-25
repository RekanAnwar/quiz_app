const { ethers } = require("hardhat");

async function main() {
    const networkName = hre.network.name;
    console.log(`Starting deployment to ${networkName}...`);

    // Get the ContractFactory and Signers here.
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

    // Deploy QuizToken first
    console.log("\n1. Deploying QuizToken...");
    const QuizToken = await ethers.getContractFactory("QuizToken");
    const quizToken = await QuizToken.deploy();
    await quizToken.waitForDeployment();

    console.log("QuizToken deployed to:", await quizToken.getAddress());
    console.log("Transaction hash:", quizToken.deploymentTransaction()?.hash);

    // Wait for a few confirmations
    console.log("Waiting for confirmations...");
    const deployTx = quizToken.deploymentTransaction();
    if (deployTx) {
        await deployTx.wait(2);
        console.log("QuizToken confirmed!");
    }

    // Deploy QuizRewardDistributor
    console.log("\n2. Deploying QuizRewardDistributor...");
    const QuizRewardDistributor = await ethers.getContractFactory("QuizRewardDistributor");
    const rewardDistributor = await QuizRewardDistributor.deploy(await quizToken.getAddress());
    await rewardDistributor.waitForDeployment();

    console.log("QuizRewardDistributor deployed to:", await rewardDistributor.getAddress());
    console.log("Transaction hash:", rewardDistributor.deploymentTransaction()?.hash);

    // Wait for confirmations
    console.log("Waiting for confirmations...");
    const rewardDeployTx = rewardDistributor.deploymentTransaction();
    if (rewardDeployTx) {
        await rewardDeployTx.wait(2);
        console.log("QuizRewardDistributor confirmed!");
    }

    // Add RewardDistributor as a minter for QuizToken
    console.log("\n3. Setting up permissions...");
    console.log("Adding RewardDistributor as minter for QuizToken...");
    const addMinterTx = await quizToken.addMinter(await rewardDistributor.getAddress());
    await addMinterTx.wait(2);
    console.log("Minter added successfully!");

    // Display deployment summary
    console.log("\n" + "=".repeat(60));
    console.log("DEPLOYMENT SUMMARY");
    console.log("=".repeat(60));
    console.log("Network:", networkName === 'sepolia' ? 'Ethereum Sepolia Testnet' : 'Scroll Sepolia Testnet');
    console.log("Deployer:", deployer.address);
    console.log("QuizToken Address:", await quizToken.getAddress());
    console.log("QuizRewardDistributor Address:", await rewardDistributor.getAddress());
    console.log("=".repeat(60));

    // Verify initial token supply
    const totalSupply = await quizToken.totalSupply();
    const deployerBalance = await quizToken.balanceOf(deployer.address);
    console.log("Total Token Supply:", ethers.formatEther(totalSupply), "QUIZ");
    console.log("Deployer Balance:", ethers.formatEther(deployerBalance), "QUIZ");

    // Show contract configuration for Flutter app
    console.log("\n" + "=".repeat(60));
    console.log("FLUTTER APP CONFIGURATION");
    console.log("=".repeat(60));
    console.log("Add these addresses to your lib/constants/app_constants.dart:");
    console.log("");
    console.log(`static const String tokenContractAddress = '${await quizToken.getAddress()}';`);
    console.log(`static const String rewardContractAddress = '${await rewardDistributor.getAddress()}';`);
    console.log("");
    console.log("Make sure to update ContractConfig with your distributor private key!");
    console.log("=".repeat(60));

    // Verification instructions
    console.log("\nVERIFICATION INSTRUCTIONS:");
    console.log("1. Wait a few minutes for the contracts to be indexed");
    const explorerUrl = networkName === 'sepolia' ? 'https://sepolia.etherscan.io' : 'https://sepolia.scrollscan.com';
    const networkFlag = networkName === 'sepolia' ? 'sepolia' : 'scrollSepolia';

    console.log(`2. Verify on ${networkName === 'sepolia' ? 'Ethereum Sepolia' : 'Scroll Sepolia'} Explorer:`);
    console.log(`   - QuizToken: ${explorerUrl}/address/${await quizToken.getAddress()}`);
    console.log(`   - RewardDistributor: ${explorerUrl}/address/${await rewardDistributor.getAddress()}`);
    console.log("\n3. To verify contracts, run:");
    console.log(`   npx hardhat verify --network ${networkFlag} ${await quizToken.getAddress()}`);
    console.log(`   npx hardhat verify --network ${networkFlag} ${await rewardDistributor.getAddress()} "${await quizToken.getAddress()}"`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Deployment failed:", error);
        process.exit(1);
    }); 