const hre = require("hardhat");

async function main() {
    console.log("Deploying Number Guessing Game contracts...");

    // Deploy GuessToken first
    const GuessToken = await hre.ethers.getContractFactory("GuessToken");
    const guessToken = await GuessToken.deploy();
    await guessToken.waitForDeployment();
    
    console.log("GuessToken deployed to:", await guessToken.getAddress());

    // Deploy NumberGuessingGame
    const NumberGuessingGame = await hre.ethers.getContractFactory("NumberGuessingGame");
    const numberGuessingGame = await NumberGuessingGame.deploy(await guessToken.getAddress());
    await numberGuessingGame.waitForDeployment();
    
    console.log("NumberGuessingGame deployed to:", await numberGuessingGame.getAddress());

    // Add NumberGuessingGame as a minter for GuessToken
    console.log("Adding NumberGuessingGame as minter...");
    await guessToken.addMinter(await numberGuessingGame.getAddress());
    console.log("NumberGuessingGame added as minter successfully!");

    console.log("\nDeployment Summary:");
    console.log("==================");
    console.log("GuessToken:", await guessToken.getAddress());
    console.log("NumberGuessingGame:", await numberGuessingGame.getAddress());
    console.log("\nSave these addresses for your frontend configuration!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 