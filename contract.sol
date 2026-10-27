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
