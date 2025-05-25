// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./QuizToken.sol";

/**
 * @title QuizRewardDistributor
 * @dev Contract for distributing quiz rewards
 */
contract QuizRewardDistributor is Ownable, Pausable, ReentrancyGuard {
    QuizToken public immutable quizToken;
    
    // Mapping from user address to quiz category to completion status
    mapping(address => mapping(string => bool)) public hasClaimedReward;
    
    // Mapping from user address to total rewards earned
    mapping(address => uint256) public userTotalRewards;
    
    // Mapping from user address to completed categories
    mapping(address => string[]) public userCompletedCategories;
    
    // Mapping to check if category exists for a user (for efficient lookups)
    mapping(address => mapping(string => bool)) private categoryExists;
    
    // Quiz categories and their reward amounts
    mapping(string => uint256) public categoryRewards;
    string[] public availableCategories;
    
    // Authorized distributors (backend services)
    mapping(address => bool) public authorizedDistributors;
    
    // Events
    event RewardDistributed(address indexed user, string category, uint256 amount);
    event CategoryAdded(string category, uint256 rewardAmount);
    event CategoryUpdated(string category, uint256 newRewardAmount);
    event DistributorAdded(address indexed distributor);
    event DistributorRemoved(address indexed distributor);
    
    modifier onlyDistributor() {
        require(
            authorizedDistributors[msg.sender] || msg.sender == owner(),
            "QuizRewardDistributor: caller is not authorized"
        );
        _;
    }
    
    constructor(address _quizToken) {
        require(_quizToken != address(0), "QuizRewardDistributor: token address cannot be zero");
        quizToken = QuizToken(_quizToken);
        
        // Initialize default categories with reward amounts (in wei, 18 decimals)
        _addCategory("Blockchain", 10 * 10**18); // 10 QUIZ tokens
        _addCategory("Science", 10 * 10**18);
        _addCategory("History", 10 * 10**18);
        _addCategory("Technology", 10 * 10**18);
        _addCategory("Geography", 10 * 10**18);
        _addCategory("Mathematics", 10 * 10**18);
        
        // Add owner as initial distributor
        authorizedDistributors[msg.sender] = true;
        emit DistributorAdded(msg.sender);
    }
    
    /**
     * @dev Add a new quiz category
     * @param category The category name
     * @param rewardAmount The reward amount in tokens (with 18 decimals)
     */
    function addCategory(string memory category, uint256 rewardAmount) external onlyOwner {
        _addCategory(category, rewardAmount);
    }
    
    /**
     * @dev Internal function to add a category
     */
    function _addCategory(string memory category, uint256 rewardAmount) internal {
        require(bytes(category).length > 0, "QuizRewardDistributor: category cannot be empty");
        require(rewardAmount > 0, "QuizRewardDistributor: reward amount must be positive");
        
        // Check if category already exists
        bool exists = false;
        for (uint i = 0; i < availableCategories.length; i++) {
            if (keccak256(bytes(availableCategories[i])) == keccak256(bytes(category))) {
                exists = true;
                break;
            }
        }
        
        if (!exists) {
            availableCategories.push(category);
        }
        
        categoryRewards[category] = rewardAmount;
        emit CategoryAdded(category, rewardAmount);
    }
    
    /**
     * @dev Update reward amount for a category
     * @param category The category name
     * @param newRewardAmount The new reward amount
     */
    function updateCategoryReward(string memory category, uint256 newRewardAmount) external onlyOwner {
        require(categoryRewards[category] > 0, "QuizRewardDistributor: category does not exist");
        require(newRewardAmount > 0, "QuizRewardDistributor: reward amount must be positive");
        
        categoryRewards[category] = newRewardAmount;
        emit CategoryUpdated(category, newRewardAmount);
    }
    
    /**
     * @dev Add an authorized distributor
     * @param distributor Address to authorize
     */
    function addDistributor(address distributor) external onlyOwner {
        require(distributor != address(0), "QuizRewardDistributor: distributor cannot be zero address");
        require(!authorizedDistributors[distributor], "QuizRewardDistributor: already authorized");
        
        authorizedDistributors[distributor] = true;
        emit DistributorAdded(distributor);
    }
    
    /**
     * @dev Remove an authorized distributor
     * @param distributor Address to remove authorization
     */
    function removeDistributor(address distributor) external onlyOwner {
        require(authorizedDistributors[distributor], "QuizRewardDistributor: not authorized");
        
        authorizedDistributors[distributor] = false;
        emit DistributorRemoved(distributor);
    }
    
    /**
     * @dev Distribute reward to a user for completing a quiz
     * @param user The user address
     * @param category The quiz category
     */
    function distributeReward(address user, string memory category) external onlyDistributor whenNotPaused nonReentrant {
        require(user != address(0), "QuizRewardDistributor: user cannot be zero address");
        require(bytes(category).length > 0, "QuizRewardDistributor: category cannot be empty");
        require(categoryRewards[category] > 0, "QuizRewardDistributor: invalid category");
        require(!hasClaimedReward[user][category], "QuizRewardDistributor: reward already claimed");
        
        uint256 rewardAmount = categoryRewards[category];
        
        // Mark as claimed
        hasClaimedReward[user][category] = true;
        
        // Update user's total rewards
        userTotalRewards[user] += rewardAmount;
        
        // Add to user's completed categories if not already added
        if (!categoryExists[user][category]) {
            userCompletedCategories[user].push(category);
            categoryExists[user][category] = true;
        }
        
        // Mint tokens to user
        quizToken.mint(user, rewardAmount);
        
        emit RewardDistributed(user, category, rewardAmount);
    }
    
    /**
     * @dev Get user's total rewards
     * @param user The user address
     * @return Total rewards earned by the user
     */
    function getUserRewards(address user) external view returns (uint256) {
        return userTotalRewards[user];
    }
    
    /**
     * @dev Get user's completed categories
     * @param user The user address
     * @return Array of completed category names
     */
    function getCompletedCategories(address user) external view returns (string[] memory) {
        return userCompletedCategories[user];
    }
    
    /**
     * @dev Get all available categories
     * @return Array of all category names
     */
    function getAvailableCategories() external view returns (string[] memory) {
        return availableCategories;
    }
    
    /**
     * @dev Get reward amount for a category
     * @param category The category name
     * @return Reward amount for the category
     */
    function getCategoryReward(string memory category) external view returns (uint256) {
        return categoryRewards[category];
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
        require(token != address(quizToken), "QuizRewardDistributor: cannot withdraw quiz tokens");
        IERC20(token).transfer(owner(), amount);
    }
} 