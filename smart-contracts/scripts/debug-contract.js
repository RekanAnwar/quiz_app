const hre = require("hardhat");

async function main() {
    console.log("🔍 Debugging Contract Issues...\n");

    // Contract addresses
    const GUESS_TOKEN_ADDRESS = "0xa2a58aB44397df686067C2C7Cee8883C5dAf0e03";
    const GAME_CONTRACT_ADDRESS = "0x647c9421FeA2f05a87Da16D927B5e6F7d5C0f667";

    // Get the signer
    const [signer] = await hre.ethers.getSigners();
    console.log(`🔑 Signer address: ${signer.address}`);

    // Get contract instances
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = GuessToken.attach(GUESS_TOKEN_ADDRESS);

    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const gameContract = NumberGuessingGame.attach(GAME_CONTRACT_ADDRESS);

    try {
        // 1. Check basic contract state
        console.log("📊 Contract State Check:");
        console.log("=".repeat(50));

        const isPaused = await gameContract.paused();
        console.log(`🚦 Game contract paused: ${isPaused}`);

        const owner = await gameContract.owner();
        console.log(`👑 Game contract owner: ${owner}`);
        console.log(`🔍 Is signer the owner: ${signer.address.toLowerCase() === owner.toLowerCase()}`);

        const entryFee = await gameContract.ENTRY_FEE();
        console.log(`💸 Entry fee: ${hre.ethers.formatEther(entryFee)} GUESS`);

        // 2. Check token balances and allowances
        console.log("\n💰 Token State Check:");
        console.log("=".repeat(50));

        const signerBalance = await guessToken.balanceOf(signer.address);
        console.log(`💰 Signer token balance: ${hre.ethers.formatEther(signerBalance)} GUESS`);

        const ownerBalance = await guessToken.balanceOf(owner);
        console.log(`👑 Owner token balance: ${hre.ethers.formatEther(ownerBalance)} GUESS`);

        const signerAllowance = await guessToken.allowance(signer.address, GAME_CONTRACT_ADDRESS);
        console.log(`🔐 Signer → Game allowance: ${hre.ethers.formatEther(signerAllowance)} GUESS`);

        const ownerAllowance = await guessToken.allowance(owner, GAME_CONTRACT_ADDRESS);
        console.log(`🔐 Owner → Game allowance: ${hre.ethers.formatEther(ownerAllowance)} GUESS`);

        // 3. Check minimum requirements
        console.log("\n✅ Requirements Check:");
        console.log("=".repeat(50));
        console.log(`Game paused: ${isPaused} (should be false)`);
        console.log(`Signer has tokens: ${signerBalance >= entryFee} (needs ${hre.ethers.formatEther(entryFee)})`);
        console.log(`Signer allowance: ${signerAllowance >= entryFee} (needs ${hre.ethers.formatEther(entryFee)})`);
        console.log(`Owner has tokens: ${ownerBalance > 0} (should have some for rewards)`);
        console.log(`Owner allowance: ${ownerAllowance > 0} (should have some for rewards)`);

        // 4. Try to call the contract with more specific error handling
        console.log("\n🎯 Testing Contract Call:");
        console.log("=".repeat(50));

        try {
            // Try to call playGame with a simple guess
            console.log("Attempting to call playGame(50)...");

            // First, let's try to estimate gas
            const gasEstimate = await gameContract.playGame.estimateGas(50);
            console.log(`⛽ Estimated gas: ${gasEstimate}`);

            // Try to call with proper gas limit
            const tx = await gameContract.playGame(50, {
                gasLimit: gasEstimate * 2n // Double the estimated gas
            });

            console.log(`📝 Transaction sent: ${tx.hash}`);
            const receipt = await tx.wait();
            console.log(`✅ Transaction confirmed: ${receipt.hash}`);

        } catch (error) {
            console.log(`❌ Contract call failed: ${error.message}`);

            // Try to get more specific error info
            if (error.reason) {
                console.log(`Reason: ${error.reason}`);
            }
            if (error.code) {
                console.log(`Error code: ${error.code}`);
            }
            if (error.data) {
                console.log(`Error data: ${error.data}`);
            }

            // Check if it's a gas estimation error
            try {
                console.log("Trying gas estimation...");
                const gasEstimate = await gameContract.playGame.estimateGas(50);
                console.log(`Gas estimate succeeded: ${gasEstimate}`);
            } catch (gasError) {
                console.log(`❌ Gas estimation failed: ${gasError.message}`);

                // This suggests a revert in the contract logic
                if (gasError.reason) {
                    console.log(`🔍 Revert reason: ${gasError.reason}`);
                }
            }
        }

        // 5. Check if the problem is with transferFrom
        console.log("\n🔄 Testing Token Operations:");
        console.log("=".repeat(50));

        try {
            // Test if we can transfer tokens manually
            console.log("Testing manual token transfer...");
            const testAmount = hre.ethers.parseEther("1");

            // Check if signer can transfer to game contract
            const transferTx = await guessToken.transfer(GAME_CONTRACT_ADDRESS, testAmount);
            await transferTx.wait();
            console.log("✅ Manual token transfer succeeded");

            // Transfer back
            const gameBalance = await guessToken.balanceOf(GAME_CONTRACT_ADDRESS);
            if (gameBalance > 0) {
                console.log(`Game contract has ${hre.ethers.formatEther(gameBalance)} tokens`);
            }

        } catch (transferError) {
            console.log(`❌ Manual transfer failed: ${transferError.message}`);
        }

    } catch (error) {
        console.log(`❌ Critical error: ${error.message}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 