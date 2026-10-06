# Freelancer DApp

![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.x-363636?style=flat&logo=solidity)
![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-yellow)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

A decentralized freelancing marketplace where clients and freelancers connect, work, and get paid — no middleman fees, no frozen accounts, no company owning your reputation. Funds sit in a smart contract escrow and release automatically as milestones are approved.

## Table of Contents

- [Why Decentralized](#why-decentralized)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Smart Contract Functions](#smart-contract-functions)
- [Project Structure](#project-structure)
- [Full Setup](#full-setup)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Why Decentralized

Traditional platforms (Upwork, Fiverr) take 10–20% in fees and can freeze funds unilaterally. This fixes that:

- **Zero platform fees** — only network gas
- **Trustless escrow** — funds locked in a contract, not a company's bank account
- **Portable reputation** — ratings tied to your wallet, not a platform login
- **Transparent disputes** — resolution logic is public and auditable

## Features

| | |
|---|---|
| 🔐 Wallet login | Connect with MetaMask — no email/password |
| 📋 Job board | Post and browse jobs on-chain |
| 🤝 Escrow | Client's budget is locked until work is approved |
| 💰 Milestones | Large jobs split into independently-released payments |
| ⚖️ Disputes | Either party can trigger on-chain arbitration |
| ⭐ Reputation | Ratings are permanent and tied to a wallet address |

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Solidity ^0.8.x |
| Dev Environment | Hardhat |
| Frontend | React.js + Ethers.js |
| Wallet | MetaMask |
| Network | Ethereum (Sepolia) / Polygon (Amoy) testnet |
| Off-chain storage | IPFS (job descriptions, attachments) |

## Quick Start

```bash
git clone https://github.com/your-username/freelancer-dapp.git
cd freelancer-dapp && npm install
cp .env.example .env            # add your PRIVATE_KEY and RPC_URL
npx hardhat run scripts/deploy.js --network sepolia
cd frontend && npm install && npm start
```

App runs at `http://localhost:3000`. See [Full Setup](#full-setup) below if any step needs more detail.

## Smart Contract Functions

| Function | Description |
|---|---|
| `postJob(string description, uint256 budget)` | Client creates a job and deposits funds into escrow |
| `applyForJob(uint256 jobId)` | Freelancer applies to an open job |
| `hireFreelancer(uint256 jobId, address freelancer)` | Client selects a freelancer |
| `submitMilestone(uint256 jobId, uint256 milestoneId)` | Freelancer marks a milestone complete |
| `approveMilestone(uint256 jobId, uint256 milestoneId)` | Client approves and releases that milestone's payment |
| `raiseDispute(uint256 jobId)` | Either party flags the job for arbitration |
| `resolveDispute(uint256 jobId, address winner)` | Arbitrator releases escrowed funds |
| `leaveReview(address user, uint8 rating, string comment)` | Either party rates the other post-completion |

> Adjust signatures to match your actual contract — this reflects the standard structure this type of DApp needs.

## Project Structure

```
freelancer-dapp/
├── contracts/
│   ├── FreelancerEscrow.sol
│   ├── Reputation.sol
│   └── DisputeResolver.sol
├── scripts/deploy.js
├── test/FreelancerEscrow.test.js
├── frontend/
│   ├── src/{components,hooks,pages,utils}/
│   └── package.json
├── hardhat.config.js
├── .env.example
└── README.md
```

## Full Setup

**Prerequisites:** [Node.js](https://nodejs.org/) v18+, [MetaMask](https://metamask.io/), test ETH/MATIC from a faucet.

```bash
# 1. Install dependencies
npm install && (cd frontend && npm install)

# 2. Configure environment — create .env in root:
#    PRIVATE_KEY=your_wallet_private_key
#    RPC_URL=your_testnet_rpc_url
#    ETHERSCAN_API_KEY=your_etherscan_api_key

# 3. Compile & test
npx hardhat compile
npx hardhat test

# 4. Deploy
npx hardhat run scripts/deploy.js --network sepolia
# → copy the deployed address into frontend/src/utils/contractConfig.js

# 5. Run frontend
cd frontend && npm start
```

> Never commit `.env` or a private key to version control.

## Usage

1. Connect your MetaMask wallet
2. **Client:** post a job with description, budget, and milestones
3. **Freelancer:** browse open jobs and apply
4. Client reviews applicants and hires one
5. Freelancer submits work per milestone; client approves to release payment
6. Either party can raise a dispute if something goes wrong
7. Both leave a review once the job closes

## Roadmap

- [ ] Multi-token payments (USDC, DAI)
- [ ] IPFS file attachments for deliverables
- [ ] DAO-based community arbitration
- [ ] Mobile-responsive UI
- [ ] Subgraph (The Graph) for faster queries

## Contributing

Fork the repo, create a feature branch, and open a pull request with a clear description of your changes.

## License

MIT — see the `LICENSE` file for details.
