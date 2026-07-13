// ============================================================================
// CRYPTO ASSET AGGREGATION API - BACKEND BLUEPRINT
// For: Aggregating wallet data from multiple blockchain networks
// Tech Stack: Node.js + Express + Web3.js/Ethers.js
// ============================================================================

// FILE: api/routes/wallets.js
const express = require('express');
const router = express.Router();
const Web3 = require('web3');
const { getWalletBalance, getTransactionHistory } = require('../services/blockchainService');
const { getUserWallets, updateWalletBalance } = require('../models/wallet');
const { authenticateUser } = require('../middleware/auth');

// ============================================================================
// ENDPOINT 1: Get All User Wallets
// ============================================================================
router.get('/user/wallets', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const wallets = await getUserWallets(userId);
    res.json({ success: true, data: wallets });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================================
// ENDPOINT 2: Add New Wallet
// ============================================================================
router.post('/user/wallets', authenticateUser, async (req, res) => {
  try {
    const { wallet_address, wallet_label, network_id, wallet_type } = req.body;
    const userId = req.user.id;

    // Validate wallet address format
    if (!Web3.utils.isAddress(wallet_address)) {
      return res.status(400).json({ success: false, error: 'Invalid wallet address' });
    }

    const newWallet = await addUserWallet({
      user_id: userId,
      wallet_address: wallet_address.toLowerCase(),
      wallet_label,
      network_id,
      wallet_type
    });

    res.json({ success: true, data: newWallet });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================================
// ENDPOINT 3: Get Wallet Balance (Single Wallet)
// ============================================================================
router.get('/wallet/:walletId/balance', authenticateUser, async (req, res) => {
  try {
    const { walletId } = req.params;
    const balances = await getWalletBalance(walletId);
    res.json({ success: true, data: balances });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================================
// ENDPOINT 4: Get All User Balances (Aggregated)
// ============================================================================
router.get('/user/balances', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const wallets = await getUserWallets(userId);
    
    let aggregatedBalances = {};
    
    for (const wallet of wallets) {
      const balances = await getWalletBalance(wallet.wallet_id);
      for (const balance of balances) {
        const key = balance.symbol;
        aggregatedBalances[key] = (aggregatedBalances[key] || 0) + parseFloat(balance.amount);
      }
    }

    res.json({ success: true, data: aggregatedBalances });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================================
// ENDPOINT 5: Get Transaction History
// ============================================================================
router.get('/wallet/:walletId/transactions', authenticateUser, async (req, res) => {
  try {
    const { walletId } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    
    const transactions = await getTransactionHistory(walletId, limit, offset);
    res.json({ success: true, data: transactions });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================================
// ENDPOINT 6: Get Portfolio Summary
// ============================================================================
router.get('/user/portfolio', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const portfolio = await getPortfolioSummary(userId);
    res.json({ success: true, data: portfolio });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;

// ============================================================================
// FILE: services/blockchainService.js
// ============================================================================

const Web3 = require('web3');
const { ethers } = require('ethers');
const axios = require('axios');

// Initialize Web3 providers for different networks
const providers = {
  ethereum: new Web3('https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY'),
  polygon: new Web3('https://polygon-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY'),
  bsc: new Web3('https://bsc-dataseed1.binance.org:8545'),
  // Add more networks as needed
};

// ============================================================================
// SERVICE 1: Get Wallet Balance from Blockchain
// ============================================================================
async function getWalletBalance(walletId) {
  try {
    const wallet = await getWalletData(walletId);
    const network = await getNetworkData(wallet.network_id);
    const provider = providers[network.network_name.toLowerCase()];

    if (!provider) {
      throw new Error(`No provider configured for ${network.network_name}`);
    }

    // Get native token balance (ETH, MATIC, BNB, etc.)
    const balance = await provider.eth.getBalance(wallet.wallet_address);
    const balanceInTokens = Web3.utils.fromWei(balance, 'ether');

    // Store in database
    await updateWalletBalance(walletId, network.currency_symbol, balanceInTokens);

    return [
      {
        symbol: network.currency_symbol,
        amount: balanceInTokens,
        usd_value: await getPriceInUSD(network.currency_symbol, balanceInTokens)
      }
    ];
  } catch (error) {
    console.error('Error fetching wallet balance:', error);
    throw error;
  }
}

// ============================================================================
// SERVICE 2: Get Transaction History from Blockchain
// ============================================================================
async function getTransactionHistory(walletId, limit = 50, offset = 0) {
  try {
    const wallet = await getWalletData(walletId);
    const network = await getNetworkData(wallet.network_id);

    // Use Etherscan API for transaction history
    const apiUrl = `${network.block_explorer_url}/api`;
    const response = await axios.get(apiUrl, {
      params: {
        module: 'account',
        action: 'txlist',
        address: wallet.wallet_address,
        startblock: 0,
        endblock: 99999999,
        sort: 'desc',
        apikey: process.env.ETHERSCAN_API_KEY
      }
    });

    const transactions = response.data.result.slice(offset, offset + limit);

    // Parse and store transactions
    for (const tx of transactions) {
      await storeTransaction({
        wallet_id: walletId,
        transaction_hash: tx.hash,
        from_address: tx.from,
        to_address: tx.to,
        amount: Web3.utils.fromWei(tx.value, 'ether'),
        gas_fee: Web3.utils.fromWei(tx.gasPrice * tx.gas, 'ether'),
        transaction_type: wallet.wallet_address.toLowerCase() === tx.from.toLowerCase() ? 'send' : 'receive',
        status: tx.isError === '0' ? 'confirmed' : 'failed',
        block_number: tx.blockNumber,
        transaction_date: new Date(tx.timeStamp * 1000)
      });
    }

    return transactions;
  } catch (error) {
    console.error('Error fetching transaction history:', error);
    throw error;
  }
}

// ============================================================================
// SERVICE 3: Sync All User Wallets (Background Job)
// ============================================================================
async function syncUserWallets(userId) {
  try {
    const wallets = await getUserWallets(userId);

    for (const wallet of wallets) {
      // Update balance
      await getWalletBalance(wallet.wallet_id);

      // Update transactions
      await getTransactionHistory(wallet.wallet_id, 100, 0);

      // Calculate portfolio value
      await updatePortfolioSummary(userId);
    }

    console.log(`✅ Synced wallets for user ${userId}`);
  } catch (error) {
    console.error(`Error syncing wallets for user ${userId}:`, error);
  }
}

// ============================================================================
// SERVICE 4: Get Price in USD
// ============================================================================
async function getPriceInUSD(symbol, amount) {
  try {
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price', {
      params: {
        ids: getCoinGeckoId(symbol),
        vs_currencies: 'usd'
      }
    });

    const pricePerUnit = response.data[getCoinGeckoId(symbol)].usd;
    return pricePerUnit * amount;
  } catch (error) {
    console.error('Error fetching price:', error);
    return 0;
  }
}

// ============================================================================
// FILE: models/wallet.js
// ============================================================================

const db = require('../config/database');

async function getUserWallets(userId) {
  const query = `
    SELECT * FROM wallets 
    WHERE user_id = ? AND is_active = TRUE
  `;
  return db.query(query, [userId]);
}

async function addUserWallet(walletData) {
  const query = `
    INSERT INTO wallets (user_id, wallet_address, wallet_label, network_id, wallet_type)
    VALUES (?, ?, ?, ?, ?)
  `;
  const result = await db.query(query, [
    walletData.user_id,
    walletData.wallet_address,
    walletData.wallet_label,
    walletData.network_id,
    walletData.wallet_type
  ]);

  return { wallet_id: result.insertId, ...walletData };
}

async function updateWalletBalance(walletId, cryptoSymbol, amount) {
  const query = `
    UPDATE wallet_balances 
    SET balance_amount = ?, last_updated = NOW()
    WHERE wallet_id = ? AND crypto_id = (
      SELECT crypto_id FROM cryptocurrencies WHERE symbol = ?
    )
  `;
  return db.query(query, [amount, walletId, cryptoSymbol]);
}

async function getPortfolioSummary(userId) {
  const query = `
    SELECT 
      SUM(wb.balance_usd) as total_value_usd,
      COUNT(DISTINCT w.wallet_id) as total_wallets,
      COUNT(DISTINCT wb.crypto_id) as total_assets
    FROM wallets w
    LEFT JOIN wallet_balances wb ON w.wallet_id = wb.wallet_id
    WHERE w.user_id = ?
  `;
  return db.query(query, [userId]);
}

module.exports = {
  getUserWallets,
  addUserWallet,
  updateWalletBalance,
  getPortfolioSummary
};

// ============================================================================
// FILE: middleware/auth.js
// ============================================================================

const jwt = require('jsonwebtoken');

function authenticateUser(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: 'Invalid token' });
  }
}

module.exports = { authenticateUser };

// ============================================================================
// FILE: jobs/syncWallets.js (Background Job - Run Every 5 Minutes)
// ============================================================================

const cron = require('node-cron');
const { syncUserWallets } = require('../services/blockchainService');
const { getAllUsers } = require('../models/user');

// Run sync job every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  console.log('🔄 Starting wallet sync job...');
  
  try {
    const users = await getAllUsers();
    for (const user of users) {
      await syncUserWallets(user.user_id);
    }
    console.log('✅ Wallet sync completed');
  } catch (error) {
    console.error('❌ Wallet sync failed:', error);
  }
});

// ============================================================================
// API USAGE EXAMPLES
// ============================================================================

/*
1. GET USER WALLETS
   GET /api/wallets/user/wallets
   Headers: Authorization: Bearer <JWT_TOKEN>
   Response: { success: true, data: [...] }

2. ADD NEW WALLET
   POST /api/wallets/user/wallets
   Headers: Authorization: Bearer <JWT_TOKEN>
   Body: {
     "wallet_address": "0x742d35Cc6634C0532925a3b844Bc91e71c732E2D",
     "wallet_label": "My Ethereum Wallet",
     "network_id": 1,
     "wallet_type": "hot"
   }

3. GET WALLET BALANCE
   GET /api/wallets/wallet/123/balance
   Headers: Authorization: Bearer <JWT_TOKEN>
   Response: { success: true, data: { ETH: 5.25, USDC: 1000 } }

4. GET ALL BALANCES (AGGREGATED)
   GET /api/wallets/user/balances
   Headers: Authorization: Bearer <JWT_TOKEN>
   Response: { success: true, data: { ETH: 10.5, USDC: 5000, DAI: 2000 } }

5. GET TRANSACTION HISTORY
   GET /api/wallets/wallet/123/transactions?limit=50&offset=0
   Headers: Authorization: Bearer <JWT_TOKEN>

6. GET PORTFOLIO SUMMARY
   GET /api/wallets/user/portfolio
   Headers: Authorization: Bearer <JWT_TOKEN>
   Response: { success: true, data: { total_value_usd: 45000, total_wallets: 3 } }
*/

// ============================================================================
// ENVIRONMENT VARIABLES (.env)
// ============================================================================
/*
DATABASE_URL=mysql://user:password@localhost/crypto_db
JWT_SECRET=your_jwt_secret_key
ETHERSCAN_API_KEY=your_etherscan_api_key
ALCHEMY_KEY=your_alchemy_api_key
COINGECKO_API_KEY=your_coingecko_api_key
*/
