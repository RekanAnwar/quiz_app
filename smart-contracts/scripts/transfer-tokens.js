const hre = require("hardhat");

async function main() {
    console.log("💸 Transfer GUESS Tokens to Test Address\n");

    const GUESS_TOKEN_ADDRESS = "0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03";

    // Get the owner signer
    const [owner] = await hre.ethers.getSigners();
    console.log(`👑 Owner address: ${owner.address}`);

    // Get contract instance
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    // Test addresses you can choose from
    const testAddresses = [
        {
            name: "Test Account 1",
            address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            recommended: true
        },
        {
            name: "Test Account 2",
            address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            recommended: false
        },
        {
            name: "Test Account 3",
            address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            recommended: false
        }
    ];

    // Choose the first test address (you can change this)
    const testAddress = testAddresses[0].address;
    const testName = testAddresses[0].name;

    console.log(`🎯 Transferring to: ${testName}`);
    console.log(`📍 Address: ${testAddress}\n`);

    // Check current balances
    const ownerBalance = await guessToken.balanceOf(owner.address);
    const testBalance = await guessToken.balanceOf(testAddress);

    console.log("📊 CURRENT BALANCES:");
    console.log(`👑 Owner: ${hre.ethers.formatEther(ownerBalance)} GUESS`);
    console.log(`🎯 Test Address: ${hre.ethers.formatEther(testBalance)} GUESS\n`);

    // Transfer amount (enough for multiple games)
    const transferAmount = hre.ethers.parseEther("50"); // 50 tokens = 10 losing games or rewards for multiple wins

    if (ownerBalance < transferAmount) {
        console.log("❌ Insufficient owner balance for transfer!");
        return;
    }

    console.log(`💸 Transferring ${hre.ethers.formatEther(transferAmount)} GUESS tokens...`);

    try {
        const tx = await guessToken.connect(owner).transfer(testAddress, transferAmount);
        console.log(`📝 Transaction sent: ${tx.hash}`);

        await tx.wait();
        console.log(`✅ Transaction confirmed!`);

        // Check new balances
        const newOwnerBalance = await guessToken.balanceOf(owner.address);
        const newTestBalance = await guessToken.balanceOf(testAddress);

        console.log("\n📊 NEW BALANCES:");
        console.log(`👑 Owner: ${hre.ethers.formatEther(newOwnerBalance)} GUESS`);
        console.log(`🎯 Test Address: ${hre.ethers.formatEther(newTestBalance)} GUESS`);

        console.log("\n📈 CHANGES:");
        console.log(`👑 Owner: ${hre.ethers.formatEther(newOwnerBalance - ownerBalance)} GUESS`);
        console.log(`🎯 Test Address: +${hre.ethers.formatEther(newTestBalance - testBalance)} GUESS`);

        console.log("\n🎮 NEXT STEPS:");
        console.log("=".repeat(60));
        console.log("1. 📱 Open MetaMask");
        console.log("2. 🔑 Import Account with private key:");
        console.log("   0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");
        console.log("3. 🔗 Make sure you're on Sepolia Testnet");
        console.log("4. 🪙 Add GUESS token contract:");
        console.log(`   ${GUESS_TOKEN_ADDRESS}`);
        console.log("5. 🎮 Use this account in your Flutter app");
        console.log("6. 🎉 Play games and see real balance changes!");

        console.log("\n🔍 VERIFY ON ETHERSCAN:");
        console.log(`https://sepolia.etherscan.io/tx/${tx.hash}`);

    } catch (error) {
        console.log(`❌ Transfer failed: ${error.message}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 