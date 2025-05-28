const hre = require("hardhat");

async function main() {
    console.log("🔍 Available Test Addresses for Your Game\n");

    const GUESS_TOKEN_ADDRESS = "0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03";

    // Get contract instance
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    // Get the main signer (your current address)
    const [mainSigner] = await hre.ethers.getSigners();
    console.log(`👑 Your Current Address (Owner): ${mainSigner.address}`);

    const ownerBalance = await guessToken.balanceOf(mainSigner.address);
    console.log(`💰 Owner Balance: ${hre.ethers.formatEther(ownerBalance)} GUESS\n`);

    console.log("📋 ALTERNATIVE TEST ADDRESSES YOU CAN USE:");
    console.log("=".repeat(70));

    // Common test addresses that you can create private keys for
    const testAddresses = [
        {
            name: "Test Account 1",
            address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            privateKey: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
            note: "Standard Hardhat test account #1"
        },
        {
            name: "Test Account 2",
            address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            privateKey: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
            note: "Standard Hardhat test account #2"
        },
        {
            name: "Test Account 3",
            address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            privateKey: "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
            note: "Standard Hardhat test account #3"
        }
    ];

    for (let i = 0; i < testAddresses.length; i++) {
        const account = testAddresses[i];
        const balance = await guessToken.balanceOf(account.address);

        console.log(`${i + 1}. ${account.name}:`);
        console.log(`   Address: ${account.address}`);
        console.log(`   Current GUESS Balance: ${hre.ethers.formatEther(balance)}`);
        console.log(`   Private Key: ${account.privateKey}`);
        console.log(`   Note: ${account.note}\n`);
    }

    console.log("🎯 HOW TO USE THESE ADDRESSES:");
    console.log("=".repeat(70));
    console.log("Option A - MetaMask Import:");
    console.log("1. 📱 Open MetaMask");
    console.log("2. 🔑 Click 'Import Account'");
    console.log("3. 📋 Paste one of the private keys above");
    console.log("4. 💸 Transfer GUESS tokens from your main account");
    console.log("5. 🎮 Test the game with this imported account\n");

    console.log("Option B - Flutter App Direct:");
    console.log("1. 📱 Copy one of the addresses above");
    console.log("2. 🔗 Connect your Flutter app with that address");
    console.log("3. 💸 First transfer tokens to that address");
    console.log("4. 🎮 Play games and see balance changes!\n");

    console.log("💸 TRANSFER TOKENS TO TEST ADDRESS:");
    console.log("=".repeat(70));
    console.log("Use this command to transfer tokens:");
    console.log(`npx hardhat run scripts/transfer-tokens.js --network sepolia\n`);

    console.log("📱 FOR MOBILE/REAL TESTING:");
    console.log("=".repeat(70));
    console.log("1. 📲 Install MetaMask Mobile App");
    console.log("2. 🆕 Create a NEW wallet (or import using private keys above)");
    console.log("3. 🔗 Connect to Sepolia Testnet");
    console.log("4. 💸 Send GUESS tokens from your main wallet");
    console.log("5. 🎮 Use Flutter app with this new wallet\n");

    console.log("🔗 USEFUL LINKS:");
    console.log("=".repeat(70));
    console.log(`🪙 GUESS Token: https://sepolia.etherscan.io/address/${GUESS_TOKEN_ADDRESS}`);
    console.log(`👑 Your Address: https://sepolia.etherscan.io/address/${mainSigner.address}`);
    console.log(`🎮 Game Contract: https://sepolia.etherscan.io/address/0x647c9421FeA2f05a87Da16D927B5e6F7d5C0f667`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 