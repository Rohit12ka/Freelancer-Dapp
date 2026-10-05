# Freelancer-Dapp
Blockchain based decentralized application

A decentralized freelancing marketplace where clients and freelancers connect, work, and get paid — without a middleman taking a cut or holding the funds. Payments sit in a smart contract escrow and release automatically based on agreed milestones, and every rating lives permanently on-chain.

## Why Decentralized?

Traditional freelance platforms (Upwork, Fiverr) take 10–20% in fees, can freeze funds or accounts unilaterally, and own your reputation data. This DApp fixes that:

- **No platform fees** — only network gas costs
- **Trustless escrow** — funds are locked in a smart contract, not a company's bank account
- **Portable reputation** — your ratings are tied to your wallet, not a platform account
- **Transparent disputes** — resolution logic is public and auditable, not a hidden support-ticket process

## Features

- 🔐 **Wallet-based login** — connect with MetaMask, no email/password signup
- 📋 **Post & browse jobs** — clients list jobs with budget and description; freelancers browse and apply
- 🤝 **Smart contract escrow** — client deposits the budget upfront; funds are locked until work is approved
- 💰 **Milestone payments** — large jobs can be split into milestones, each released independently
- ⚖️ **Dispute resolution** — either party can raise a dispute, routed to on-chain arbitration
- ⭐ **On-chain reputation** — every completed job adds a permanent, tamper-proof rating to a freelancer's address
- 🔔 **Event-driven updates** — frontend listens to contract events for real-time job/payment status

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Solidity ^0.8.x |
| Dev Environment | Hardhat |
| Frontend | React.js + Ethers.js |
| Wallet Integration | MetaMask |
| Network | Ethereum (Sepolia testnet) / Polygon (Amoy testnet) |
| Storage (off-chain data) | IPFS (job descriptions, attachments) |

## Smart Contract Overview

| Function | Description |
|---|---|
| `postJob(string description, uint256 budget)` | Client creates a new job listing and deposits funds into escrow |
| `applyForJob(uint256 jobId)` | Freelancer applies to an open job |
| `hireFreelancer(uint256 jobId, address freelancer)` | Client selects a freelancer from applicants |
| `submitMilestone(uint256 jobId, uint256 milestoneId)` | Freelancer marks a milestone as complete |
| `approveMilestone(uint256 jobId, uint256 milestoneId)` | Client approves work and releases payment for that milestone |
| `raiseDispute(uint256 jobId)` | Either party flags a job for arbitration |
| `resolveDispute(uint256 jobId, address winner)` | Arbitrator releases escrowed funds based on resolution |
| `leaveReview(address user, uint8 rating, string comment)` | Either party rates the other after job completion |

> Adjust these signatures to match your actual contract — this reflects the standard structure this type of DApp typically needs.

## Project Structure

```
freelancer-dapp/
├── contracts/
│   ├── FreelancerEscrow.sol
│   ├── Reputation.sol
│   └── DisputeResolver.sol
├── scripts/
│   └── deploy.js
├── test/
│   └── FreelancerEscrow.test.js
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── pages/
│   │   └── utils/
│   └── package.json
├── hardhat.config.js
├── .env.example
└── README.md
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18+)
- [MetaMask](https://metamask.io/) browser extension
- Test ETH/MATIC from a faucet (for testnet deployment)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/freelancer-dapp.git
cd freelancer-dapp

# Install root (contracts) dependencies
npm install

# Install frontend dependencies
cd frontend
npm install
cd ..
```

### Configure Environment

Create a `.env` file in the root directory:

```env
PRIVATE_KEY=your_wallet_private_key
RPC_URL=your_testnet_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

> Never commit your `.env` file or private key to version control.

### Compile & Test Contracts

```bash
npx hardhat compile
npx hardhat test
```

### Deploy to Testnet

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

Copy the deployed contract address into `frontend/src/utils/contractConfig.js`.

### Run the Frontend

```bash
cd frontend
npm start
```

The app will be available at `http://localhost:3000`.

## Usage

1. Connect your MetaMask wallet
2. **As a client:** post a job with a description, budget, and milestones
3. **As a freelancer:** browse open jobs and apply
4. Client reviews applicants and hires one
5. Freelancer submits work per milestone; client approves to release payment
6. Either party can raise a dispute if something goes wrong
7. Both parties leave a review after the job closes

## Roadmap

- [ ] Multi-token payment support (USDC, DAI)
- [ ] IPFS-based file attachments for job deliverables
- [ ] DAO-based community arbitration instead of a single arbitrator
- [ ] Mobile-responsive UI
- [ ] Subgraph (The Graph) for faster job/history queries

## Contributing

Contributions are welcome. Please fork the repo, create a feature branch, and open a pull request with a clear description of your changes.

## License

This project is licensed under the MIT License — see the `LICENSE` file for details.
