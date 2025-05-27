const fs = require('fs');
const path = require('path');

async function main() {
    console.log("📋 Generating ABI files for Flutter integration...\n");

    // Get the compiled artifacts
    const gameArtifact = require('../artifacts/contracts/NumberGuessingGame.sol/NumberGuessingGame.json');
    const tokenArtifact = require('../artifacts/contracts/GuessToken.sol/GuessToken.json');

    // Extract the ABI
    const gameAbi = gameArtifact.abi;
    const tokenAbi = tokenArtifact.abi;

    // Filter out only the functions we need for the game contract
    const gameFunctions = gameAbi.filter(item => {
        if (item.type === 'function') {
            return ['playGame', 'getUserTotalRewards', 'getUserTotalGames', 'getUserGameHistory', 'getLatestGameResult', 'getUserAverageAccuracy', 'paused'].includes(item.name);
        }
        if (item.type === 'event') {
            return ['GamePlayed', 'RewardDistributed'].includes(item.name);
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

    console.log("📝 Number Guessing Game Contract Functions Found:");
    gameFunctions.forEach(func => {
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
    const gameAbiDart = `// Number Guessing Game Contract ABI
const String gameContractAbi = '''
${JSON.stringify(gameFunctions, null, 2)}
''';
`;

    const tokenAbiDart = `// ERC20 Token Contract ABI
const String erc20Abi = '''
${JSON.stringify(tokenFunctions, null, 2)}
''';
`;

    // Write to Flutter files
    const flutterLibPath = '../lib/contracts';

    fs.writeFileSync(path.join(flutterLibPath, 'game_contract_abi.dart'), gameAbiDart);
    fs.writeFileSync(path.join(flutterLibPath, 'erc20_abi.dart'), tokenAbiDart);

    console.log("\n✅ ABI files generated successfully!");
    console.log("- lib/contracts/game_contract_abi.dart");
    console.log("- lib/contracts/erc20_abi.dart");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 