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


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract Lottary{
    address public manager;
    address payable[] public players;
    address payable public winner;
    constructor (){
        manager=msg.sender;
    }
    function participates()public payable{
        require(msg.value == 1 ether, "Please pay 1 ether");
        players.push(payable(msg.sender));
    }
    function getbalance() public view returns(uint){
        require(manager == msg.sender,"You are not a Manager");
        return address(this).balance;
    }
    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp,players.length)));
    }
    function pickwinner() public{
        require(manager == msg.sender, "You are not the winner");
        require(players.length>=3,"Players are less then 3");
        uint r=random();
        uint index = r%players.length;
        winner=players[index];
        (bool success, ) = payable(winner).call{value: address(this).balance}("");
        require(success, "Ether transfer failed");
        players=new address payable[](0);
    }
}
