# Bitcoin Price Oracle - Decentralized Prediction Market

A trustless, decentralized prediction market built on the Stacks blockchain that enables users to stake STX tokens on Bitcoin price movements within defined time windows.

## 🚀 Features

- **Trustless Predictions**: Oracle-based price resolution ensures fair outcomes
- **Proportional Rewards**: Winners share the losing side's stakes proportionally
- **Minimum Viable Staking**: 1 STX minimum stake requirement
- **Low Platform Fees**: Only 2% fee on winnings
- **Administrative Controls**: Market management and parameter adjustment
- **Transparent Operations**: All transactions and outcomes are on-chain

## 📋 System Overview

The Bitcoin Price Oracle operates as a prediction market where users can:

1. **Create Markets**: Authorized operators create time-bound prediction markets
2. **Make Predictions**: Users stake STX on Bitcoin price direction ("up" or "down")
3. **Oracle Resolution**: Trusted oracle provides final Bitcoin price data
4. **Claim Rewards**: Winners claim proportional shares of the total stake pool

### Key Components

- **Market Management**: Time-bound markets with start/end blocks
- **Stake Escrow**: Contract holds all stakes until resolution
- **Oracle Integration**: External price feed for trustless resolution
- **Fee Distribution**: Platform sustainability through winner fees

## 🏗️ Contract Architecture

### Data Structures

```clarity
;; Market Information
markets: {
  start-price: uint,      // Initial Bitcoin price
  end-price: uint,        // Final Bitcoin price (post-resolution)
  total-up-stake: uint,   // Total stakes on price increase
  total-down-stake: uint, // Total stakes on price decrease
  start-block: uint,      // Prediction window start
  end-block: uint,        // Prediction window end
  resolved: bool          // Resolution status
}

;; User Predictions
user-predictions: {
  prediction: string,     // "up" or "down"
  stake: uint,           // Staked amount in microSTX
  claimed: bool          // Reward claim status
}
```

### Core Functions

#### Administrative Functions

- `create-market`: Initialize new prediction markets
- `resolve-market`: Oracle-based market resolution
- `set-oracle-address`: Update authorized oracle
- `withdraw-fees`: Platform fee collection

#### User Functions

- `make-prediction`: Stake STX on price direction
- `claim-winnings`: Withdraw proportional rewards

#### Query Functions

- `get-market`: Retrieve market details
- `get-user-prediction`: Check user's prediction status
- `get-contract-balance`: View total contract holdings

## 🔄 Data Flow

### 1. Market Creation Flow

```
Contract Owner → create-market() → Market Storage
                                ↓
                           Market ID Generated
```

### 2. Prediction Flow

```
User → make-prediction() → Stake Validation → STX Transfer
                              ↓                    ↓
                        Update Market Totals → Record Prediction
```

### 3. Resolution Flow

```
Oracle → resolve-market() → Price Validation → Market Update
                               ↓                    ↓
                        Determine Winners → Enable Claims
```

### 4. Reward Distribution Flow

```
Winner → claim-winnings() → Validation → Calculate Payout
                               ↓              ↓
                        Deduct Platform Fee → Transfer Rewards
```

## 💰 Economic Model

### Stake Distribution

- **Total Pool**: Sum of all "up" and "down" stakes
- **Winner Share**: Proportional to individual stake vs. total winning side
- **Platform Fee**: 2% deducted from winnings
- **Payout Formula**: `(user_stake / winning_total) * total_pool * 0.98`

### Example Scenario

```
Market: Bitcoin $50,000 → $55,000 (Price Increased)
Total Up Stakes: 100 STX (Winners)
Total Down Stakes: 200 STX (Losers)
User A Stake: 10 STX (Up)

User A Payout = (10/100) * 300 * 0.98 = 29.4 STX
```

## 🛠️ Technical Specifications

### Blockchain Requirements

- **Network**: Stacks Blockchain
- **Language**: Clarity Smart Contract
- **Token**: STX (Native Stacks Token)

### Configuration Parameters

- **Minimum Stake**: 1,000,000 microSTX (1 STX)
- **Platform Fee**: 2% of winnings
- **Oracle Address**: Configurable trusted price feed
- **Block-based Timing**: Stacks block height for market windows

### Error Handling

- `ERR-OWNER-ONLY (u100)`: Unauthorized administrative access
- `ERR-NOT-FOUND (u101)`: Market or prediction not found
- `ERR-INVALID-PREDICTION (u102)`: Invalid prediction parameters
- `ERR-MARKET-CLOSED (u103)`: Market not active
- `ERR-ALREADY-CLAIMED (u104)`: Rewards already claimed
- `ERR-INSUFFICIENT-BALANCE (u105)`: Insufficient STX balance

## 🔒 Security Features

### Access Controls

- **Owner-only Functions**: Market creation, oracle updates, fee withdrawal
- **Oracle Authority**: Only designated oracle can resolve markets
- **Time-locked Markets**: Block-height based prediction windows

### Validation Layers

- **Stake Verification**: Balance and minimum stake checks
- **Timing Validation**: Active market window enforcement
- **Double-spend Protection**: Claim status tracking
- **Parameter Validation**: Input sanitization and bounds checking

## 📊 Usage Examples

### Creating a Market

```clarity
(contract-call? .bitcoin-oracle create-market 
  u5000000000    ;; Start price: $50,000 (in microunits)
  u1000          ;; Start block
  u1100)         ;; End block (100 blocks ~ 16.7 hours)
```

### Making a Prediction

```clarity
(contract-call? .bitcoin-oracle make-prediction 
  u0             ;; Market ID
  "up"           ;; Prediction direction
  u5000000)      ;; Stake: 5 STX
```

### Claiming Winnings

```clarity
(contract-call? .bitcoin-oracle claim-winnings u0)
```

## 🚦 Deployment Checklist

- [ ] Deploy contract to Stacks testnet
- [ ] Configure oracle address
- [ ] Set appropriate minimum stake
- [ ] Test market creation and resolution
- [ ] Verify fee calculations
- [ ] Conduct security audit
- [ ] Deploy to mainnet

## 📈 Future Enhancements

- **Multi-asset Support**: Extend beyond Bitcoin
- **Advanced Market Types**: Time-series and conditional markets
- **Governance Token**: Decentralized parameter management
- **Automated Market Making**: Dynamic odds adjustment
- **Mobile Integration**: User-friendly prediction interface

## 📄 License

This smart contract is released under the MIT License. See LICENSE file for details.
