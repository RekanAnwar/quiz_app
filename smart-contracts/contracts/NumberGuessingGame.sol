// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GuessToken.sol";

/**
 * @title NumberGuessingGame
 * @dev Contract for a blockchain-based number guessing reward game
 * Players can play for free and only receive rewards when they win
 */
contract NumberGuessingGame is Ownable, Pausable, ReentrancyGuard {
    GuessToken public immutable guessToken;
    
    // Game state
    uint256 public constant MIN_NUMBER = 0;
    uint256 public constant MAX_NUMBER = 100;
    uint256 public constant BASE_REWARD = 10 * 10**18; // 10 tokens base reward
    uint256 public constant PERFECT_BONUS = 40 * 10**18; // 40 extra tokens for perfect guess
    
    // Mapping from user address to game history
    mapping(address => GameResult[]) public userGameHistory;
    
    // Mapping from user address to total rewards earned
    mapping(address => uint256) public userTotalRewards;
    
    // Mapping from user address to total games played
    mapping(address => uint256) public userTotalGames;
    
    // Nonce for randomness (in production, use Chainlink VRF)
    uint256 private nonce;
    
    struct GameResult {
        uint256 targetNumber;
        uint256 userGuess;
        uint256 difference;
        uint256 rewardAmount;
        uint256 timestamp;
    }
    
    // Events
    event GamePlayed(
        address indexed user,
        uint256 targetNumber,
        uint256 userGuess,
        uint256 difference,
        uint256 rewardAmount,
        uint256 timestamp
    );
    
    event RewardDistributed(address indexed user, uint256 amount);
    event PlayerWon(address indexed user, uint256 targetNumber, uint256 guess, uint256 reward);
    event PlayerLost(address indexed user, uint256 targetNumber, uint256 guess);
    
    constructor(address _guessToken) {
        require(_guessToken != address(0), "NumberGuessingGame: token address cannot be zero");
        guessToken = GuessToken(_guessToken);
        nonce = block.timestamp;
    }
    
    /**
     * @dev Play the number guessing game - FREE TO PLAY!
     * @param guess The user's guess (must be between 0 and 100)
     */
    function playGame(uint256 guess) external whenNotPaused nonReentrant {
        require(guess >= MIN_NUMBER && guess <= MAX_NUMBER, "NumberGuessingGame: guess must be between 0 and 100");
        
        // Generate random number (in production, use Chainlink VRF for true randomness)
        uint256 targetNumber = _generateRandomNumber();
        
        // Calculate difference
        uint256 difference = guess > targetNumber ? guess - targetNumber : targetNumber - guess;
        
        // Determine if player wins or loses
        bool playerWins = _isWinningGuess(difference);
        uint256 tokenAmount = _calculateTokenAmount(difference);
        
        // Handle token transfers based on win/loss
        if (playerWins) {
            // Player wins: transfer tokens from owner to player
            require(guessToken.balanceOf(owner()) >= tokenAmount, "NumberGuessingGame: owner has insufficient tokens");
            require(guessToken.transferFrom(owner(), msg.sender, tokenAmount), "NumberGuessingGame: reward transfer failed");
            emit PlayerWon(msg.sender, targetNumber, guess, tokenAmount);
            emit RewardDistributed(msg.sender, tokenAmount);
        } else {
            // Player loses: no payment required - completely free to play!
            tokenAmount = 0; // No reward for losing
            emit PlayerLost(msg.sender, targetNumber, guess);
        }
        
        // Store game result
        GameResult memory result = GameResult({
            targetNumber: targetNumber,
            userGuess: guess,
            difference: difference,
            rewardAmount: playerWins ? tokenAmount : 0,
            timestamp: block.timestamp
        });
        
        userGameHistory[msg.sender].push(result);
        if (playerWins) {
            userTotalRewards[msg.sender] += tokenAmount;
        }
        userTotalGames[msg.sender]++;
        
        emit GamePlayed(
            msg.sender,
            targetNumber,
            guess,
            difference,
            playerWins ? tokenAmount : 0,
            block.timestamp
        );
    }
    
    /**
     * @dev Check if the guess is considered a winning guess
     * @param difference The absolute difference between guess and target
     * @return true if player wins, false if player loses
     */
    function _isWinningGuess(uint256 difference) internal pure returns (bool) {
        // Player wins if they guess within 20 points of the target
        return difference <= 20;
    }
    
    /**
     * @dev Calculate token amount based on the difference between guess and target
     * @param difference The absolute difference between guess and target
     * @return The token amount for rewards
     */
    function _calculateTokenAmount(uint256 difference) internal pure returns (uint256) {
        if (difference == 0) {
            // Perfect guess: base reward + perfect bonus
            return BASE_REWARD + PERFECT_BONUS;
        } else if (difference <= 5) {
            // Very close: base reward + 75% bonus
            return BASE_REWARD + (BASE_REWARD * 75 / 100);
        } else if (difference <= 10) {
            // Close: base reward + 50% bonus
            return BASE_REWARD + (BASE_REWARD * 50 / 100);
        } else if (difference <= 20) {
            // Moderate: base reward + 25% bonus
            return BASE_REWARD + (BASE_REWARD * 25 / 100);
        } else {
            // Losing guess: no reward
            return 0;
        }
    }
    
    /**
     * @dev Calculate reward based on the difference between guess and target (deprecated - kept for backward compatibility)
     * @param difference The absolute difference between guess and target
     * @return The reward amount in tokens
     */
    function _calculateReward(uint256 difference) internal pure returns (uint256) {
        return _calculateTokenAmount(difference);
    }
    
    /**
     * @dev Generate a random number between MIN_NUMBER and MAX_NUMBER
     * @return Random number
     */
    function _generateRandomNumber() internal returns (uint256) {
        // WARNING: This is not truly random and should not be used in production
        // Use Chainlink VRF for true randomness in production
        nonce++;
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            nonce
        ))) % (MAX_NUMBER - MIN_NUMBER + 1) + MIN_NUMBER;
    }
    
    /**
     * @dev Get user's game history
     * @param user The user address
     * @return Array of game results
     */
    function getUserGameHistory(address user) external view returns (GameResult[] memory) {
        return userGameHistory[user];
    }
    
    /**
     * @dev Get user's latest game result
     * @param user The user address
     * @return Latest game result
     */
    function getLatestGameResult(address user) external view returns (GameResult memory) {
        require(userGameHistory[user].length > 0, "NumberGuessingGame: no games played");
        return userGameHistory[user][userGameHistory[user].length - 1];
    }
    
    /**
     * @dev Get user's total rewards
     * @param user The user address
     * @return Total rewards earned by the user
     */
    function getUserTotalRewards(address user) external view returns (uint256) {
        return userTotalRewards[user];
    }
    
    /**
     * @dev Get user's total games played
     * @param user The user address
     * @return Total games played by the user
     */
    function getUserTotalGames(address user) external view returns (uint256) {
        return userTotalGames[user];
    }
    
    /**
     * @dev Get user's average accuracy
     * @param user The user address
     * @return Average difference (lower is better)
     */
    function getUserAverageAccuracy(address user) external view returns (uint256) {
        require(userTotalGames[user] > 0, "NumberGuessingGame: no games played");
        
        uint256 totalDifference = 0;
        for (uint i = 0; i < userGameHistory[user].length; i++) {
            totalDifference += userGameHistory[user][i].difference;
        }
        
        return totalDifference / userTotalGames[user];
    }
    
    /**
     * @dev Get the entry fee required to play the game
     * @return Entry fee amount in tokens
     */
    function getEntryFee() external pure returns (uint256) {
        return 0; // Free to play
    }
    
    /**
     * @dev Owner approves the contract to spend tokens for rewards
     * @param amount Amount of tokens to approve
     */
    function approveRewardTokens(uint256 amount) external onlyOwner {
        require(guessToken.approve(address(this), amount), "NumberGuessingGame: approval failed");
    }
    
    /**
     * @dev Get owner's token balance
     * @return Owner's token balance
     */
    function getOwnerTokenBalance() external view returns (uint256) {
        return guessToken.balanceOf(owner());
    }
    
    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency function to withdraw any accidentally sent tokens
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != address(guessToken), "NumberGuessingGame: cannot withdraw guess tokens");
        IERC20(token).transfer(owner(), amount);
    }
} 