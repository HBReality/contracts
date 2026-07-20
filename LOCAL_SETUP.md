// ============================================================================
// LOCAL DEVELOPMENT ENVIRONMENT SETUP GUIDE
// For Crypto Asset Management System
// ============================================================================

# 🚀 LOCAL DEVELOPMENT ENVIRONMENT SETUP

## Prerequisites
Before starting, ensure you have installed:
- **Node.js** (v16 or higher) - https://nodejs.org/
- **Git** - https://git-scm.com/
- **MySQL/PostgreSQL** - https://www.mysql.com/ or https://www.postgresql.org/
- **Hardhat** - For Solidity smart contract development
- **MetaMask** - Browser extension for Ethereum interaction

---

## PART 1: CLONE AND SETUP YOUR PROJECT

### Step 1.1: Clone Repository
```bash
# Navigate to your projects folder
cd ~/projects

# Clone your contracts repository
git clone https://github.com/HBReality/contracts.git
cd contracts

# Verify directory structure
ls -la
```

### Step 1.2: Initialize Node.js Project (if not already done)
```bash
# Initialize npm
npm init -y

# Install core dependencies
npm install express web3 ethers axios mysql2 dotenv jsonwebtoken cors nodemon

# Install development dependencies
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/hardhat-upgrades

# Verify installations
npm list
```

### Step 1.3: Create Project Structure
```bash
# Create necessary directories
mkdir -p backend/config
mkdir -p backend/models
mkdir -p backend/routes
mkdir -p backend/services
mkdir -p backend/middleware
mkdir -p backend/jobs
mkdir -p contracts/scripts
mkdir -p database
mkdir -p tests

# Create main backend file
touch backend/index.js
touch backend/config/database.js
touch backend/middleware/auth.js
touch backend/services/blockchainService.js
touch backend/models/wallet.js
touch backend/routes/wallets.js
touch backend/jobs/syncWallets.js

# Create environment file
touch .env
touch .env.example
```

---

## PART 2: DATABASE SETUP

### Step 2.1: Install MySQL (if not already installed)

**On macOS (using Homebrew):**
```bash
brew install mysql
brew services start mysql
```

**On Windows:**
- Download from https://dev.mysql.com/downloads/mysql/
- Follow installation wizard
- Run MySQL as service

**On Linux (Ubuntu/Debian):**
```bash
sudo apt-get install mysql-server
sudo service mysql start
```

### Step 2.2: Create Database and Import Schema
```bash
# Connect to MySQL
mysql -u root -p

# In MySQL CLI, create database
CREATE DATABASE crypto_portfolio;
USE crypto_portfolio;

# Exit MySQL
EXIT;

# Import schema from file
mysql -u root -p crypto_portfolio < database/schema.sql

# Verify tables were created
mysql -u root -p crypto_portfolio -e "SHOW TABLES;"
```

### Step 2.3: Create Database Configuration File
Create `backend/config/database.js`:
```javascript
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'crypto_portfolio',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;
```

---

## PART 3: ENVIRONMENT VARIABLES SETUP

### Step 3.1: Create .env File
Create `.env` file in project root:
```bash
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=crypto_portfolio

# API Configuration
PORT=3000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRE=24h

# Blockchain RPC URLs
ETHEREUM_RPC=https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
POLYGON_RPC=https://polygon-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
BSC_RPC=https://bsc-dataseed1.binance.org:8545

# External APIs
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
ALCHEMY_KEY=YOUR_ALCHEMY_API_KEY
COINGECKO_API_KEY=optional_coingecko_key

# Smart Contract Deployment
PRIVATE_KEY=your_wallet_private_key_for_testnet_only
SEPOLIA_RPC=https://sepolia.infura.io/v3/YOUR_INFURA_KEY

# Sync Job Interval (in minutes)
SYNC_INTERVAL=5
```

### Step 3.2: Create .env.example (for documentation)
```bash
cp .env .env.example
```

### Step 3.3: Add .env to .gitignore
```bash
# Create/update .gitignore
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
echo "node_modules/" >> .gitignore
echo "dist/" >> .gitignore
echo ".DS_Store" >> .gitignore
```

---

## PART 4: GET EXTERNAL API KEYS

### Step 4.1: Etherscan API Key
1. Go to https://etherscan.io/apis
2. Sign up / Login
3. Create new API key
4. Copy key to `.env` as `ETHERSCAN_API_KEY`

### Step 4.2: Alchemy API Key
1. Go to https://www.alchemy.com/
2. Sign up / Login
3. Create new app (select Ethereum Mainnet)
4. Copy API key to `.env` as `ALCHEMY_KEY`

### Step 4.3: Infura Key (for Sepolia Testnet)
1. Go to https://infura.io/
2. Sign up / Login
3. Create new project
4. Copy Project ID to `.env` as `INFURA_KEY`

### Step 4.4: CoinGecko API (Free)
1. Go to https://www.coingecko.com/en/api
2. Free API available, no key needed (optional)

---

## PART 5: BACKEND API SETUP

### Step 5.1: Create Main Backend File
Create `backend/index.js`:
```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'Backend is running ✅' });
});

// Routes
app.use('/api/wallets', require('./routes/wallets'));

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    error: err.message 
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Backend server running on http://localhost:${PORT}`);
});
```

### Step 5.2: Create Authentication Middleware
Create `backend/middleware/auth.js`:
```javascript
const jwt = require('jsonwebtoken');

function authenticateUser(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      error: 'No token provided' 
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ 
      success: false, 
      error: 'Invalid token' 
    });
  }
}

module.exports = { authenticateUser };
```

### Step 5.3: Create Wallet Routes
Create `backend/routes/wallets.js`:
```javascript
const express = require('express');
const router = express.Router();
const { authenticateUser } = require('../middleware/auth');

// Test endpoint
router.get('/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Wallets API is working ✅' 
  });
});

// Get all user wallets (requires auth)
router.get('/user/wallets', authenticateUser, (req, res) => {
  res.json({ 
    success: true, 
    message: 'User wallets endpoint',
    user_id: req.user.id 
  });
});

module.exports = router;
```

### Step 5.4: Update package.json Scripts
Update `package.json`:
```json
{
  "scripts": {
    "start": "node backend/index.js",
    "dev": "nodemon backend/index.js",
    "test": "echo \"Error: no test specified\" && exit 1",
    "hardhat:compile": "hardhat compile",
    "hardhat:deploy": "hardhat run scripts/deploy.js --network sepolia"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
```

---

## PART 6: SMART CONTRACT SETUP

### Step 6.1: Initialize Hardhat
```bash
# In project root
npx hardhat

# Select: Create a JavaScript project
# Choose defaults for other prompts
```

### Step 6.2: Update hardhat.config.js
Create `hardhat.config.js`:
```javascript
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require('dotenv').config();

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {},
    sepolia: {
      url: process.env.SEPOLIA_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  }
};
```

### Step 6.3: Copy Smart Contracts
```bash
# Copy the contracts from INTEGRATION_GUIDE.md to:
# contracts/PortfolioManager.sol
```

### Step 6.4: Compile Smart Contracts
```bash
# Compile contracts
npx hardhat compile

# Expected output:
# Compiled 1 Solidity file successfully
```

---

## PART 7: TESTING SETUP

### Step 7.1: Test Database Connection
Create `test-db.js`:
```javascript
require('dotenv').config();
const mysql = require('mysql2/promise');

async function testConnection() {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
    });

    console.log('✅ Database connection successful!');
    
    const [rows] = await connection.execute('SHOW TABLES');
    console.log('📊 Tables in database:', rows.length);
    rows.forEach(row => {
      console.log('  -', Object.values(row)[0]);
    });

    await connection.end();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
  }
}

testConnection();
```

Run test:
```bash
node test-db.js
```

### Step 7.2: Test Backend API
```bash
# Start backend in one terminal
npm run dev

# In another terminal, test the API
curl http://localhost:3000/health

# Expected response:
# {"status":"Backend is running ✅"}
```

### Step 7.3: Test API with Authentication
```bash
# First, generate a test JWT token
# Use an online JWT tool: https://jwt.io/
# Payload: { "id": 1, "email": "test@example.com" }
# Secret: your JWT_SECRET from .env

# Then test protected endpoint
curl -H "Authorization: Bearer YOUR_TEST_TOKEN" \
  http://localhost:3000/api/wallets/user/wallets
```

---

## PART 8: FULL LOCAL SETUP CHECKLIST

Run through this checklist to verify everything:

```bash
# 1. Check Node.js version
node --version
# Should be v16 or higher

# 2. Check npm version
npm --version

# 3. Verify MySQL is running
mysql -u root -p -e "SELECT 1"

# 4. Verify database exists
mysql -u root -p -e "USE crypto_portfolio; SHOW TABLES;"

# 5. Install all npm dependencies
npm install

# 6. Check .env file exists
cat .env | head -10

# 7. Compile smart contracts
npx hardhat compile

# 8. Test database connection
node test-db.js

# 9. Start backend
npm run dev

# 10. Test health endpoint (in another terminal)
curl http://localhost:3000/health
```

---

## PART 9: USEFUL DEVELOPMENT COMMANDS

```bash
# Start backend in development mode (with auto-reload)
npm run dev

# Compile Solidity contracts
npx hardhat compile

# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia

# Test Ethereum connection
npx hardhat run scripts/test-connection.js

# Start local Ethereum node (for testing)
npx hardhat node

# Create database backup
mysqldump -u root -p crypto_portfolio > backup.sql

# Restore database from backup
mysql -u root -p crypto_portfolio < backup.sql

# View real-time logs
tail -f logs/backend.log
```

---

## PART 10: TROUBLESHOOTING

### Issue: "Cannot find module 'express'"
**Solution:**
```bash
npm install
npm install express
```

### Issue: "ECONNREFUSED 127.0.0.1:3306"
**Solution:** MySQL is not running
```bash
# macOS
brew services start mysql

# Linux
sudo service mysql start

# Windows: Start MySQL from Services
```

### Issue: "ER_ACCESS_DENIED_FOR_USER"
**Solution:** Wrong MySQL password
```bash
# Update .env with correct password
# Or reset MySQL password
mysql -u root -p
# Then change password in .env
```

### Issue: "Port 3000 already in use"
**Solution:**
```bash
# Kill process on port 3000
lsof -i :3000
kill -9 <PID>

# Or use different port
PORT=3001 npm run dev
```

### Issue: ".env file not found"
**Solution:**
```bash
# Create .env from .env.example
cp .env.example .env

# Edit with your values
nano .env
```

---

## PART 11: NEXT STEPS

After completing setup:

1. ✅ **Test all endpoints** - Make sure API responds correctly
2. ✅ **Deploy contracts to Sepolia** - Test on testnet first
3. ✅ **Add test data** - Populate database with test wallets
4. ✅ **Connect MetaMask** - Link to your local/testnet setup
5. ✅ **Build Frontend** - Create React/Vue UI connected to API

---

## QUICK START SUMMARY

```bash
# 1. Clone repo
git clone https://github.com/HBReality/contracts.git
cd contracts

# 2. Install dependencies
npm install

# 3. Setup database
mysql -u root -p crypto_portfolio < database/schema.sql

# 4. Create .env
cp .env.example .env
# Edit .env with your API keys

# 5. Start backend
npm run dev

# 6. In another terminal, test
curl http://localhost:3000/health
```

---

**Status**: ✅ Ready to Start Development
**Created**: July 13, 2026

---
