// ============================================================================
// CRYPTO ASSET MANAGEMENT SMART CONTRACT
// For: On-Chain Asset Tracking, Ownership Records, and Portfolio Management
// Language: Solidity ^0.8.0
// ============================================================================

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ============================================================================
// INTERFACE: Portfolio Manager Contract
// ============================================================================

interface IPortfolioManager {
    function addAsset(address assetAddress, uint256 amount) external;
    function removeAsset(address assetAddress, uint256 amount) external;
    function getAssetBalance(address assetAddress) external view returns (uint256);
    function getAllAssets() external view returns (address[] memory);
}

// ============================================================================
// CONTRACT 1: Asset Registry (Track all supported assets)
// ============================================================================

contract AssetRegistry is Ownable {
    struct Asset {
        address assetAddress;
        string name;
        string symbol;
        uint8 decimals;
        bool isActive;
        uint256 addedAt;
    }

    mapping(address => Asset) public assets;
    address[] public assetList;
    mapping(address => bool) public assetExists;

    event AssetRegistered(address indexed assetAddress, string name, string symbol);
    event AssetDeactivated(address indexed assetAddress);

    // Register a new asset (token)
    function registerAsset(
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external onlyOwner {
        require(!assetExists[_assetAddress], "Asset already registered");
        require(_assetAddress != address(0), "Invalid asset address");

        assets[_assetAddress] = Asset({
            assetAddress: _assetAddress,
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            isActive: true,
            addedAt: block.timestamp
        });

        assetExists[_assetAddress] = true;
        assetList.push(_assetAddress);

        emit AssetRegistered(_assetAddress, _name, _symbol);
    }

    // Get all active assets
    function getActiveAssets() external view returns (address[] memory) {
        address[] memory activeAssets = new address[](assetList.length);
        uint256 count = 0;

        for (uint256 i = 0; i < assetList.length; i++) {
            if (assets[assetList[i]].isActive) {
                activeAssets[count] = assetList[i];
                count++;
            }
        }

        // Resize array to actual count
        assembly {
            mstore(activeAssets, count)
        }
        return activeAssets;
    }

    // Get asset details
    function getAssetDetails(address _assetAddress)
        external
        view
        returns (Asset memory)
    {
        require(assetExists[_assetAddress], "Asset not registered");
        return assets[_assetAddress];
    }
}

// ============================================================================
// CONTRACT 2: User Portfolio (Individual user asset holdings)
// ============================================================================

contract UserPortfolio is ReentrancyGuard {
    struct AssetHolding {
        address assetAddress;
        uint256 balance;
        uint256 depositedAt;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
    }

    address public owner;
    AssetRegistry public assetRegistry;

    mapping(address => AssetHolding) public holdings;
    address[] public heldAssets;
    mapping(address => bool) public assetHeld;

    uint256 public totalPortfolioValue; // In base currency (e.g., USD equivalent)

    event AssetDeposited(address indexed asset, uint256 amount, uint256 timestamp);
    event AssetWithdrawn(address indexed asset, uint256 amount, uint256 timestamp);
    event PortfolioUpdated(uint256 newTotalValue);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor(address _assetRegistryAddress) {
        owner = msg.sender;
        assetRegistry = AssetRegistry(_assetRegistryAddress);
    }

    // ========================================================================
    // DEPOSIT FUNCTION: User deposits crypto assets
    // ========================================================================
    function depositAsset(address _assetAddress, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(assetRegistry.assetExists(_assetAddress), "Asset not registered");

        // Transfer asset from user to contract
        require(
            IERC20(_assetAddress).transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        // Update holding
        if (!assetHeld[_assetAddress]) {
            heldAssets.push(_assetAddress);
            assetHeld[_assetAddress] = true;
            holdings[_assetAddress].assetAddress = _assetAddress;
            holdings[_assetAddress].depositedAt = block.timestamp;
        }

        holdings[_assetAddress].balance += _amount;
        holdings[_assetAddress].totalDeposited += _amount;

        emit AssetDeposited(_assetAddress, _amount, block.timestamp);
        updatePortfolioValue();
    }

    // ========================================================================
    // WITHDRAW FUNCTION: User withdraws crypto assets
    // ========================================================================
    function withdrawAsset(address _assetAddress, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            holdings[_assetAddress].balance >= _amount,
            "Insufficient balance"
        );

        // Transfer asset from contract to user
        require(
            IERC20(_assetAddress).transfer(msg.sender, _amount),
            "Transfer failed"
        );

        // Update holding
        holdings[_assetAddress].balance -= _amount;
        holdings[_assetAddress].totalWithdrawn += _amount;

        // Remove from held assets if balance is 0
        if (holdings[_assetAddress].balance == 0) {
            assetHeld[_assetAddress] = false;
        }

        emit AssetWithdrawn(_assetAddress, _amount, block.timestamp);
        updatePortfolioValue();
    }

    // ========================================================================
    // VIEW FUNCTION: Get all holdings
    // ========================================================================
    function getAllHoldings()
        external
        view
        returns (AssetHolding[] memory)
    {
        AssetHolding[] memory portfolio = new AssetHolding[](heldAssets.length);

        for (uint256 i = 0; i < heldAssets.length; i++) {
            portfolio[i] = holdings[heldAssets[i]];
        }

        return portfolio;
    }

    // ========================================================================
    // VIEW FUNCTION: Get single asset holding
    // ========================================================================
    function getAssetHolding(address _assetAddress)
        external
        view
        returns (AssetHolding memory)
    {
        return holdings[_assetAddress];
    }

    // ========================================================================
    // UPDATE PORTFOLIO VALUE (Called after deposits/withdrawals)
    // ========================================================================
    function updatePortfolioValue() internal {
        uint256 newValue = 0;

        for (uint256 i = 0; i < heldAssets.length; i++) {
            newValue += holdings[heldAssets[i]].balance;
        }

        totalPortfolioValue = newValue;
        emit PortfolioUpdated(newValue);
    }

    // ========================================================================
    // EMERGENCY: Transfer ownership (owner can transfer portfolio to another address)
    // ========================================================================
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");
        owner = _newOwner;
    }
}

// ============================================================================
// CONTRACT 3: Multi-Asset Portfolio (Multiple users, shared registry)
// ============================================================================

contract MultiAssetPortfolio is Ownable, ReentrancyGuard {
    AssetRegistry public assetRegistry;

    struct UserPortfolioData {
        address walletAddress;
        mapping(address => uint256) assetBalances;
        address[] heldAssets;
        uint256 createdAt;
        bool exists;
    }

    mapping(address => UserPortfolioData) public userPortfolios;
    address[] public allUsers;

    event UserRegistered(address indexed userAddress);
    event AssetDepositedToPortfolio(
        address indexed user,
        address indexed asset,
        uint256 amount
    );
    event AssetWithdrawnFromPortfolio(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    constructor(address _assetRegistryAddress) {
        assetRegistry = AssetRegistry(_assetRegistryAddress);
    }

    // ========================================================================
    // REGISTER USER PORTFOLIO
    // ========================================================================
    function registerUserPortfolio() external {
        require(!userPortfolios[msg.sender].exists, "Portfolio already exists");

        userPortfolios[msg.sender].walletAddress = msg.sender;
        userPortfolios[msg.sender].exists = true;
        userPortfolios[msg.sender].createdAt = block.timestamp;

        allUsers.push(msg.sender);
        emit UserRegistered(msg.sender);
    }

    // ========================================================================
    // DEPOSIT TO USER PORTFOLIO
    // ========================================================================
    function depositToPortfolio(address _assetAddress, uint256 _amount)
        external
        nonReentrant
    {
        require(userPortfolios[msg.sender].exists, "Portfolio not registered");
        require(_amount > 0, "Amount must be > 0");
        require(assetRegistry.assetExists(_assetAddress), "Asset not registered");

        // Transfer from user to contract
        require(
            IERC20(_assetAddress).transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        // Update balance
        userPortfolios[msg.sender].assetBalances[_assetAddress] += _amount;

        // Track held assets
        bool assetAlreadyHeld = false;
        for (uint256 i = 0; i < userPortfolios[msg.sender].heldAssets.length; i++) {
            if (userPortfolios[msg.sender].heldAssets[i] == _assetAddress) {
                assetAlreadyHeld = true;
                break;
            }
        }

        if (!assetAlreadyHeld) {
            userPortfolios[msg.sender].heldAssets.push(_assetAddress);
        }

        emit AssetDepositedToPortfolio(msg.sender, _assetAddress, _amount);
    }

    // ========================================================================
    // WITHDRAW FROM USER PORTFOLIO
    // ========================================================================
    function withdrawFromPortfolio(address _assetAddress, uint256 _amount)
        external
        nonReentrant
    {
        require(userPortfolios[msg.sender].exists, "Portfolio not registered");
        require(
            userPortfolios[msg.sender].assetBalances[_assetAddress] >= _amount,
            "Insufficient balance"
        );

        // Transfer from contract to user
        require(
            IERC20(_assetAddress).transfer(msg.sender, _amount),
            "Transfer failed"
        );

        // Update balance
        userPortfolios[msg.sender].assetBalances[_assetAddress] -= _amount;

        emit AssetWithdrawnFromPortfolio(msg.sender, _assetAddress, _amount);
    }

    // ========================================================================
    // GET USER PORTFOLIO SUMMARY
    // ========================================================================
    function getUserPortfolioSummary(address _userAddress)
        external
        view
        returns (
            address[] memory assets,
            uint256[] memory balances,
            uint256 totalAssets
        )
    {
        require(userPortfolios[_userAddress].exists, "Portfolio not found");

        address[] memory assetArray = userPortfolios[_userAddress].heldAssets;
        uint256[] memory balanceArray = new uint256[](assetArray.length);

        for (uint256 i = 0; i < assetArray.length; i++) {
            balanceArray[i] = userPortfolios[_userAddress].assetBalances[assetArray[i]];
        }

        return (assetArray, balanceArray, assetArray.length);
    }

    // ========================================================================
    // GET TOTAL USERS
    // ========================================================================
    function getTotalUsers() external view returns (uint256) {
        return allUsers.length;
    }

    // ========================================================================
    // EMERGENCY: Admin can withdraw stuck tokens
    // ========================================================================
    function emergencyWithdraw(address _assetAddress) external onlyOwner {
        uint256 balance = IERC20(_assetAddress).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(_assetAddress).transfer(owner(), balance);
    }
}

// ============================================================================
// CONTRACT 4: Portfolio Analyzer (Calculate gains/losses, ROI)
// ============================================================================

contract PortfolioAnalyzer is Ownable {
    struct PriceSnapshot {
        address assetAddress;
        uint256 price; // Price in wei/base unit
        uint256 timestamp;
    }

    mapping(address => PriceSnapshot[]) public priceHistory;
    mapping(address => uint256) public latestPrice;

    event PriceUpdated(address indexed asset, uint256 newPrice, uint256 timestamp);

    // ========================================================================
    // UPDATE ASSET PRICE (Called by price oracle)
    // ========================================================================
    function updatePrice(address _assetAddress, uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be > 0");

        latestPrice[_assetAddress] = _price;
        priceHistory[_assetAddress].push(
            PriceSnapshot({
                assetAddress: _assetAddress,
                price: _price,
                timestamp: block.timestamp
            })
        );

        emit PriceUpdated(_assetAddress, _price, block.timestamp);
    }

    // ========================================================================
    // CALCULATE PORTFOLIO VALUE (At latest prices)
    // ========================================================================
    function calculatePortfolioValue(
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external view returns (uint256 totalValue) {
        require(_assets.length == _amounts.length, "Array length mismatch");

        for (uint256 i = 0; i < _assets.length; i++) {
            totalValue += (_amounts[i] * latestPrice[_assets[i]]) / 1e18;
        }

        return totalValue;
    }

    // ========================================================================
    // CALCULATE GAINS/LOSSES (Assuming entry price is stored off-chain)
    // ========================================================================
    function calculateGainLoss(
        address _assetAddress,
        uint256 _amount,
        uint256 _entryPrice
    ) external view returns (int256 gainLoss, uint256 percentage) {
        uint256 currentPrice = latestPrice[_assetAddress];
        require(currentPrice > 0, "Price not available");

        int256 priceDifference = int256(currentPrice) - int256(_entryPrice);
        gainLoss = (priceDifference * int256(_amount)) / 1e18;
        percentage = uint256((priceDifference * 100) / int256(_entryPrice));

        return (gainLoss, percentage);
    }

    // ========================================================================
    // GET PRICE HISTORY
    // ========================================================================
    function getPriceHistory(address _assetAddress)
        external
        view
        returns (PriceSnapshot[] memory)
    {
        return priceHistory[_assetAddress];
    }
}

// ============================================================================
// DEPLOYMENT & INTEGRATION GUIDE
// ============================================================================

/*
STEP 1: Deploy AssetRegistry
    - Owner: Your admin wallet
    - Register all supported cryptocurrencies (ETH, USDC, USDT, etc.)

STEP 2: Deploy MultiAssetPortfolio
    - Pass AssetRegistry address as constructor argument
    - This is the main contract users interact with

STEP 3: Deploy PortfolioAnalyzer
    - Connect to price feeds (Chainlink, etc.)
    - Update prices regularly

STEP 4: Backend Integration
    - Listen to contract events (AssetDepositedToPortfolio, AssetWithdrawn)
    - Store transaction data in database
    - Update UI with real-time portfolio changes

STEP 5: Security Audit
    - Audit smart contracts before mainnet deployment
    - Test on testnet (Sepolia, Mumbai, etc.)
    - Use OpenZeppelin contracts for standard implementations

KEY FEATURES:
✅ Decentralized asset tracking
✅ User portfolio management
✅ Multi-chain support (deploy on multiple networks)
✅ Transparent on-chain records
✅ Gas-efficient operations
✅ Reentrancy protection
✅ Owner controls for emergency withdrawals
*/

// ============================================================================
// TESTING EXAMPLES
// ============================================================================

/*
// Register an asset
assetRegistry.registerAsset(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC address
    "USD Coin",
    "USDC",
    6
);

// User registers portfolio
multiAssetPortfolio.registerUserPortfolio();

// User deposits USDC
multiAssetPortfolio.depositToPortfolio(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    1000 * 1e6 // 1000 USDC
);

// Get user portfolio
(address[] memory assets, uint256[] memory balances, uint256 count) = 
    multiAssetPortfolio.getUserPortfolioSummary(userAddress);

// Update price
portfolioAnalyzer.updatePrice(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    1e18 // $1 per USDC
);

// Calculate portfolio value
uint256 value = portfolioAnalyzer.calculatePortfolioValue(assets, balances);
*/
