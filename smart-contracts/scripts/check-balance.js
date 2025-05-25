const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);

    console.log("Network:", hre.network.name);
    console.log("Address:", deployer.address);
    console.log("Balance (Wei):", balance.toString());
    console.log("Balance (ETH):", ethers.formatEther(balance));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 