// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const FreelanceEscrow = await hre.ethers.getContractFactory("FreelanceEscrow");
  const escrow = await FreelanceEscrow.deploy();
  await escrow.waitForDeployment();

  console.log("FreelanceEscrow deployed to:", await escrow.getAddress());
  console.log("Arbiter (owner):", deployer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
import { useState, useEffect, useCallback } from "react";
import { BrowserProvider } from "ethers";
import { REQUIRED_CHAIN_ID, REQUIRED_CHAIN_HEX } from "../utils/config";

/**
 * MetaMask wallet connection hook (ethers v6).
 * Returns: account, signer, provider, chainId, isConnecting, error,
 *          connect(), disconnect(), wrongNetwork
 */
export default function useWallet() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState("");

  const setup = useCallback(async (accounts) => {
    if (!accounts || accounts.length === 0) {
      setAccount(null);
      setSigner(null);
      return;
    }
    const browserProvider = new BrowserProvider(window.ethereum);
    const network = await browserProvider.getNetwork();
    setProvider(browserProvider);
    setSigner(await browserProvider.getSigner());
    setAccount(accounts[0]);
    setChainId(Number(network.chainId));
  }, []);

  const switchNetwork = async () => {
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: REQUIRED_CHAIN_HEX }],
      });
    } catch (err) {
      // 4902 = chain wallet mein added nahi hai
      if (err.code === 4902) {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: REQUIRED_CHAIN_HEX,
              chainName: "Sepolia Testnet",
              nativeCurrency: { name: "Sepolia ETH", symbol: "ETH", decimals: 18 },
              rpcUrls: ["https://rpc.sepolia.org"],
              blockExplorerUrls: ["https://sepolia.etherscan.io"],
            },
          ],
        });
      } else {
        throw err;
      }
    }
  };

  const connect = async () => {
    setError("");
    if (!window.ethereum) {
      setError("MetaMask not found. Please install it from metamask.io");
      return;
    }
    try {
      setIsConnecting(true);
      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
      await setup(accounts);

      const current = Number(await window.ethereum.request({ method: "eth_chainId" }));
      if (current !== REQUIRED_CHAIN_ID) {
        await switchNetwork();
        await setup(accounts); // switch ke baad signer refresh
      }
    } catch (err) {
      setError(err.code === 4001 ? "Connection request rejected." : err.message);
    } finally {
      setIsConnecting(false);
    }
  };

  // MetaMask me asli "disconnect" nahi hota, bas app state clear karte hain
  const disconnect = () => {
    setAccount(null);
    setSigner(null);
    setProvider(null);
    setChainId(null);
  };

  // Auto-reconnect + account/network change listeners
  useEffect(() => {
    if (!window.ethereum) return;

    window.ethereum
      .request({ method: "eth_accounts" })
      .then(setup)
      .catch(() => {});

    const onAccountsChanged = (accounts) => setup(accounts);
    const onChainChanged = () => window.location.reload();

    window.ethereum.on("accountsChanged", onAccountsChanged);
    window.ethereum.on("chainChanged", onChainChanged);
    return () => {
      window.ethereum.removeListener("accountsChanged", onAccountsChanged);
      window.ethereum.removeListener("chainChanged", onChainChanged);
    };
  }, [setup]);

  return {
    account,
    provider,
    signer,
    chainId,
    isConnecting,
    error,
    connect,
    disconnect,
    wrongNetwork: account !== null && chainId !== REQUIRED_CHAIN_ID,
  };
}
import { Contract } from "ethers";

// 👉 Deploy ke baad yahan apna contract address paste karo
export const CONTRACT_ADDRESS = "0xYourDeployedContractAddress";

// Sepolia testnet
export const REQUIRED_CHAIN_ID = 11155111;
export const REQUIRED_CHAIN_HEX = "0xaa36a7";

// Hardhat compile ke baad artifacts/contracts/FreelanceEscrow.sol/FreelanceEscrow.json
// se "abi" copy karke yahan import karo, ya neeche wala human-readable ABI use karo.
export const CONTRACT_ABI = [
  "function jobCount() view returns (uint256)",
  "function jobs(uint256) view returns (uint256 id, address client, address freelancer, string descriptionHash, uint256 totalAmount, uint256 releasedAmount, uint256 deadline, uint8 status, bool rated)",
  "function getMilestones(uint256 jobId) view returns (tuple(uint256 amount, string deliverableHash, uint8 status)[])",
  "function getAverageRating(address freelancer) view returns (uint256)",
  "function createJob(string descriptionHash, uint256[] amounts, uint256 deadline) payable returns (uint256)",
  "function cancelJob(uint256 jobId)",
  "function acceptJob(uint256 jobId)",
  "function submitMilestone(uint256 jobId, uint256 index, string deliverableHash)",
  "function approveMilestone(uint256 jobId, uint256 index)",
  "function raiseDispute(uint256 jobId)",
  "function resolveDispute(uint256 jobId, bool payFreelancer)",
  "function claimRefund(uint256 jobId)",
  "function rateFreelancer(uint256 jobId, uint8 rating)",
  "event JobCreated(uint256 indexed jobId, address indexed client, uint256 totalAmount, uint256 deadline)",
];

// signer se contract instance banao (transactions ke liye)
export const getContract = (signerOrProvider) =>
  new Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signerOrProvider);
