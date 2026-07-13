-- ============================================================================
-- CRYPTO ASSET MANAGEMENT DATABASE SCHEMA - NORMALIZED (3NF)
-- For: Wallet Management, Transaction History, and Digital Asset Tracking
-- ============================================================================

-- TABLE 1: Users (Core Identity)
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- TABLE 2: Blockchain Networks (Independent Reference)
CREATE TABLE blockchain_networks (
    network_id INT PRIMARY KEY AUTO_INCREMENT,
    network_name VARCHAR(100) UNIQUE NOT NULL,
    chain_id INT UNIQUE,
    currency_symbol VARCHAR(10),
    rpc_url VARCHAR(500),
    block_explorer_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 3: Cryptocurrencies (Independent Reference)
CREATE TABLE cryptocurrencies (
    crypto_id INT PRIMARY KEY AUTO_INCREMENT,
    symbol VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    contract_address VARCHAR(255),
    network_id INT NOT NULL,
    decimals INT DEFAULT 18,
    logo_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (network_id) REFERENCES blockchain_networks(network_id)
);

-- TABLE 4: Wallets (User's Crypto Addresses)
CREATE TABLE wallets (
    wallet_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    wallet_address VARCHAR(255) UNIQUE NOT NULL,
    wallet_label VARCHAR(100),
    network_id INT NOT NULL,
    wallet_type ENUM('hot', 'cold', 'hardware', 'exchange') DEFAULT 'hot',
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (network_id) REFERENCES blockchain_networks(network_id),
    UNIQUE KEY unique_user_wallet (user_id, wallet_address)
);

-- TABLE 5: Wallet Balances (Current Holdings)
CREATE TABLE wallet_balances (
    balance_id INT PRIMARY KEY AUTO_INCREMENT,
    wallet_id INT NOT NULL,
    crypto_id INT NOT NULL,
    balance_amount DECIMAL(30, 18) DEFAULT 0,
    balance_usd DECIMAL(20, 2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    FOREIGN KEY (crypto_id) REFERENCES cryptocurrencies(crypto_id),
    UNIQUE KEY unique_wallet_crypto (wallet_id, crypto_id)
);

-- TABLE 6: Transactions (All Asset Movements)
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    wallet_id INT NOT NULL,
    crypto_id INT NOT NULL,
    transaction_hash VARCHAR(255) UNIQUE,
    transaction_type ENUM('send', 'receive', 'swap', 'stake', 'unstake', 'mint', 'burn') NOT NULL,
    from_address VARCHAR(255),
    to_address VARCHAR(255),
    amount DECIMAL(30, 18) NOT NULL,
    gas_fee DECIMAL(30, 18),
    usd_value DECIMAL(20, 2),
    status ENUM('pending', 'confirmed', 'failed') DEFAULT 'pending',
    block_number INT,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    FOREIGN KEY (crypto_id) REFERENCES cryptocurrencies(crypto_id),
    INDEX idx_wallet_date (wallet_id, transaction_date),
    INDEX idx_transaction_hash (transaction_hash)
);

-- TABLE 7: Crypto Prices (Historical Price Tracking)
CREATE TABLE crypto_prices (
    price_id INT PRIMARY KEY AUTO_INCREMENT,
    crypto_id INT NOT NULL,
    price_usd DECIMAL(20, 2) NOT NULL,
    price_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    market_cap DECIMAL(25, 2),
    trading_volume DECIMAL(25, 2),
    price_change_24h DECIMAL(10, 2),
    FOREIGN KEY (crypto_id) REFERENCES cryptocurrencies(crypto_id),
    INDEX idx_crypto_date (crypto_id, price_date)
);

-- TABLE 8: Portfolio (User's Overall Asset Summary)
CREATE TABLE portfolio_summary (
    portfolio_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,
    total_value_usd DECIMAL(20, 2),
    total_gain_loss_usd DECIMAL(20, 2),
    total_gain_loss_percent DECIMAL(10, 4),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- TABLE 9: Alerts/Notifications (Price & Balance Alerts)
CREATE TABLE alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    alert_type ENUM('price_above', 'price_below', 'balance_change', 'transaction') NOT NULL,
    crypto_id INT,
    threshold_value DECIMAL(20, 2),
    is_triggered BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    triggered_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (crypto_id) REFERENCES cryptocurrencies(crypto_id)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_wallets_user ON wallets(user_id);
CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_balances_wallet ON wallet_balances(wallet_id);
CREATE INDEX idx_alerts_user ON alerts(user_id);

-- ============================================================================
-- NORMALIZATION NOTES:
-- ✅ 1NF: All fields contain atomic values (no repeating groups)
-- ✅ 2NF: All non-key attributes depend on the entire primary key
-- ✅ 3NF: No transitive dependencies (e.g., crypto prices separate from holdings)
-- ✅ Proper foreign keys prevent data redundancy
-- ✅ Indexed columns for fast queries on common searches
-- ============================================================================
