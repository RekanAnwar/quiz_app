const hre = require("hardhat");

async function main() {
    console.log("🔍 Investigating Transaction Details\n");

    const GUESS_TOKEN_ADDRESS = "0x2AC923843d160A63877b83EC7bC69027C97bc45e";
    const GAME_CONTRACT_ADDRESS = "0x2a7081a264DDF15f9e43B237967F3599D743B0f5";
    const TEST_ADDRESS = "0xfC530E5ebA48fb740C91F3a45A927C67ADb9B45c";

    // Transaction hashes from the previous test
    const GAME_TX = "0x8dadbb503be570f68978afa7eedf85d24629057147e980eb8037a1b03a2f7d89";
    const TRANSFER_TX = "0x0a43cc6a4cc27eef7db25cd60ae74287e3832b6e31fa8e45e91b946877c7a663";

    const [owner] = await hre.ethers.getSigners();
    console.log(`👑 Owner address: ${owner.address}`);
    console.log(`🧪 Test address: ${TEST_ADDRESS}`);
    console.log(`🪙 Token contract: ${GUESS_TOKEN_ADDRESS}`);
    console.log(`🎮 Game contract: ${GAME_CONTRACT_ADDRESS}\n`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    try {
        console.log("📊 Transaction 1: Game Play Transaction");
        console.log(`🔗 ${GAME_TX}`);

        // Get transaction receipt
        const gameReceipt = await hre.ethers.provider.getTransactionReceipt(GAME_TX);

        console.log(`Block: ${gameReceipt.blockNumber}`);
        console.log(`Status: ${gameReceipt.status ? 'Success' : 'Failed'}`);
        console.log(`Gas used: ${gameReceipt.gasUsed}`);

        // Check logs for token transfers
        console.log(`\n📝 Logs in game transaction (${gameReceipt.logs.length} total):`);

        for (let i = 0; i < gameReceipt.logs.length; i++) {
            const log = gameReceipt.logs[i];
            console.log(`Log ${i + 1}:`);
            console.log(`   Address: ${log.address}`);
            console.log(`   Topics: ${log.topics.map(t => t.substring(0, 10) + '...')}`);

            // Try to decode if it's a Transfer event from the token contract
            if (log.address.toLowerCase() === GUESS_TOKEN_ADDRESS.toLowerCase()) {
                try {
                    const transferInterface = new hre.ethers.Interface([
                        "event Transfer(address indexed from, address indexed to, uint256 value)"
                    ]);
                    const decoded = transferInterface.parseLog(log);
                    console.log(`   ✅ DECODED TRANSFER:`);
                    console.log(`      From: ${decoded.args.from}`);
                    console.log(`      To: ${decoded.args.to}`);
                    console.log(`      Amount: ${hre.ethers.formatEther(decoded.args.value)} GUESS`);
                } catch (e) {
                    console.log(`   ⚠️ Could not decode as Transfer event`);
                }
            }
        }

        console.log("\n" + "=".repeat(50));
        console.log("📊 Transaction 2: Manual Transfer Transaction");
        console.log(`🔗 ${TRANSFER_TX}`);

        const transferReceipt = await hre.ethers.provider.getTransactionReceipt(TRANSFER_TX);

        console.log(`Block: ${transferReceipt.blockNumber}`);
        console.log(`Status: ${transferReceipt.status ? 'Success' : 'Failed'}`);
        console.log(`Gas used: ${transferReceipt.gasUsed}`);

        console.log(`\n📝 Logs in transfer transaction (${transferReceipt.logs.length} total):`);

        for (let i = 0; i < transferReceipt.logs.length; i++) {
            const log = transferReceipt.logs[i];
            console.log(`Log ${i + 1}:`);
            console.log(`   Address: ${log.address}`);

            if (log.address.toLowerCase() === GUESS_TOKEN_ADDRESS.toLowerCase()) {
                try {
                    const transferInterface = new hre.ethers.Interface([
                        "event Transfer(address indexed from, address indexed to, uint256 value)"
                    ]);
                    const decoded = transferInterface.parseLog(log);
                    console.log(`   ✅ DECODED TRANSFER:`);
                    console.log(`      From: ${decoded.args.from}`);
                    console.log(`      To: ${decoded.args.to}`);
                    console.log(`      Amount: ${hre.ethers.formatEther(decoded.args.value)} GUESS`);
                } catch (e) {
                    console.log(`   ⚠️ Could not decode as Transfer event`);
                }
            }
        }

        console.log("\n" + "=".repeat(50));
        console.log("📊 Current Balance Check");

        const ownerBalance = await guessToken.balanceOf(owner.address);
        const testBalance = await guessToken.balanceOf(TEST_ADDRESS);
        const contractBalance = await guessToken.balanceOf(GAME_CONTRACT_ADDRESS);

        console.log(`💰 Owner balance: ${hre.ethers.formatEther(ownerBalance)} GUESS`);
        console.log(`💰 Test address balance: ${hre.ethers.formatEther(testBalance)} GUESS`);
        console.log(`💰 Game contract balance: ${hre.ethers.formatEther(contractBalance)} GUESS`);

        console.log("\n📝 Summary of what happened:");
        console.log("1. Game was played and owner won 12.5 GUESS tokens");
        console.log("2. We manually transferred 12.5 GUESS from owner to test address");
        console.log("3. If you see transfers to the token contract address, that might be");
        console.log("   how some block explorers display internal contract operations");

        console.log(`\n🔗 View game transaction: https://sepolia.etherscan.io/tx/${GAME_TX}`);
        console.log(`🔗 View transfer transaction: https://sepolia.etherscan.io/tx/${TRANSFER_TX}`);
        console.log(`🔗 View test address: https://sepolia.etherscan.io/address/${TEST_ADDRESS}`);

    } catch (error) {
        console.log(`❌ Error investigating transactions: ${error.message}`);
        console.log("Full error:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 