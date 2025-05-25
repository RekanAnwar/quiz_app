const fs = require('fs');
const path = require('path');

async function main() {
    console.log("📋 Generating ABI files for Flutter integration...\n");

    // Get the compiled artifacts
    const rewardArtifact = require('../artifacts/contracts/QuizRewardDistributor.sol/QuizRewardDistributor.json');
    const tokenArtifact = require('../artifacts/contracts/QuizToken.sol/QuizToken.json');

    // Extract the ABI
    const rewardAbi = rewardArtifact.abi;
    const tokenAbi = tokenArtifact.abi;

    // Filter out only the functions we need for the reward contract
    const rewardFunctions = rewardAbi.filter(item => {
        if (item.type === 'function') {
            return ['hasClaimedReward', 'distributeReward', 'getUserRewards', 'getCompletedCategories'].includes(item.name);
        }
        if (item.type === 'event') {
            return item.name === 'RewardDistributed';
        }
        return false;
    });

    // Filter out only the functions we need for the token contract
    const tokenFunctions = tokenAbi.filter(item => {
        if (item.type === 'function') {
            return ['name', 'symbol', 'totalSupply', 'balanceOf', 'transfer', 'mint', 'burn'].includes(item.name);
        }
        return false;
    });

    console.log("📝 Reward Contract Functions Found:");
    rewardFunctions.forEach(func => {
        if (func.type === 'function') {
            const inputs = func.inputs.map(input => `${input.type} ${input.name}`).join(', ');
            console.log(`- ${func.name}(${inputs})`);
        }
    });

    console.log("\n📝 Token Contract Functions Found:");
    tokenFunctions.forEach(func => {
        if (func.type === 'function') {
            const inputs = func.inputs.map(input => `${input.type} ${input.name}`).join(', ');
            console.log(`- ${func.name}(${inputs})`);
        }
    });

    // Generate Dart files
    const rewardAbiDart = `// Quiz Reward Contract ABI
const String rewardContractAbi = '''
${JSON.stringify(rewardFunctions, null, 2)}
''';
`;

    const tokenAbiDart = `// ERC20 Token Contract ABI
const String erc20Abi = '''
${JSON.stringify(tokenFunctions, null, 2)}
''';
`;

    // Write to Flutter files
    const flutterLibPath = '../lib/contracts';

    fs.writeFileSync(path.join(flutterLibPath, 'reward_contract_abi.dart'), rewardAbiDart);
    fs.writeFileSync(path.join(flutterLibPath, 'erc20_abi.dart'), tokenAbiDart);

    console.log("\n✅ ABI files generated successfully!");
    console.log("- lib/contracts/reward_contract_abi.dart");
    console.log("- lib/contracts/erc20_abi.dart");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 