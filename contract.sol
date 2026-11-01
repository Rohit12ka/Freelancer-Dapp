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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract RockPaperScissors {
    enum Move {
        None,
        Rock,
        Paper,
        Scissors
    }

    enum Status {
        WaitingForPlayer,
        CommitPhase,
        RevealPhase,
        Finished,
        Cancelled
    }

    struct Game {
        address player1;
        address player2;
        uint256 betAmount;
        uint256 revealDeadline;
        bytes32 commit1;
        bytes32 commit2;
        Move move1;
        Move move2;
        Status status;
    }

    uint256 public gameCounter;
    uint256 public constant REVEAL_WINDOW = 10 minutes;

    mapping(uint256 => Game) public games;

    event GameCreated(uint256 indexed gameId, address player1, uint256 betAmount);
    event PlayerJoined(uint256 indexed gameId, address player2);
    event MoveCommitted(uint256 indexed gameId, address player);
    event MoveRevealed(uint256 indexed gameId, address player, Move move);
    event GameFinished(uint256 indexed gameId, address winner, uint256 prize);
    event GameDraw(uint256 indexed gameId, uint256 refundPerPlayer);
    event GameCancelled(uint256 indexed gameId, uint256 refund);

    error NotAPlayer();
    error WrongPhase();
    error AlreadyCommitted();
    error InvalidMove();
    error InvalidCommitment();
    error RevealPeriodOver();
    error WrongBetAmount();
    error CannotPlayYourself();

    modifier onlyPlayer(uint256 gameId) {
        Game storage game = games[gameId];
        if (msg.sender != game.player1 && msg.sender != game.player2) {
            revert NotAPlayer();
        }
        _;
    }

    // Step 1: Player 1 creates game and locks ETH
    function createGame() external payable returns (uint256 gameId) {
        if (msg.value == 0) revert WrongBetAmount();

        gameId = gameCounter++;
        Game storage game = games[gameId];

        game.player1 = msg.sender;
        game.betAmount = msg.value;
        game.status = Status.WaitingForPlayer;

        emit GameCreated(gameId, msg.sender, msg.value);
    }

    // Step 2: Player 2 joins with same ETH amount
    function joinGame(uint256 gameId) external payable {
        Game storage game = games[gameId];

        if (game.status != Status.WaitingForPlayer) revert WrongPhase();
        if (msg.sender == game.player1) revert CannotPlayYourself();
        if (msg.value != game.betAmount) revert WrongBetAmount();

        game.player2 = msg.sender;
        game.status = Status.CommitPhase;

        emit PlayerJoined(gameId, msg.sender);
    }

    // Step 3: Both players commit hash(move + secret)
    function commitMove(uint256 gameId, bytes32 commitment) external onlyPlayer(gameId) {
        Game storage game = games[gameId];

        if (game.status != Status.CommitPhase) revert WrongPhase();

        if (msg.sender == game.player1) {
            if (game.commit1 != bytes32(0)) revert AlreadyCommitted();
            game.commit1 = commitment;
        } else {
            if (game.commit2 != bytes32(0)) revert AlreadyCommitted();
            game.commit2 = commitment;
        }

        if (game.commit1 != bytes32(0) && game.commit2 != bytes32(0)) {
            game.status = Status.RevealPhase;
            game.revealDeadline = block.timestamp + REVEAL_WINDOW;
        }

        emit MoveCommitted(gameId, msg.sender);
    }

    // Step 4: Reveal move and secret salt
    function revealMove(
        uint256 gameId,
        Move move,
        bytes32 salt
    ) external onlyPlayer(gameId) {
        Game storage game = games[gameId];

        if (game.status != Status.RevealPhase) revert WrongPhase();
        if (block.timestamp > game.revealDeadline) revert RevealPeriodOver();
        if (move == Move.None) revert InvalidMove();

        bytes32 commitment = keccak256(abi.encodePacked(move, salt, msg.sender));

        if (msg.sender == game.player1) {
            if (commitment != game.commit1) revert InvalidCommitment();
            game.move1 = move;
        } else {
            if (commitment != game.commit2) revert InvalidCommitment();
            game.move2 = move;
        }

        emit MoveRevealed(gameId, msg.sender, move);

        if (game.move1 != Move.None && game.move2 != Move.None) {
            _finishGame(gameId);
        }
    }

    // Step 5: Decide winner and transfer ETH
    function _finishGame(uint256 gameId) private {
        Game storage game = games[gameId];
        game.status = Status.Finished;

        uint8 result = _getResult(game.move1, game.move2);

        if (result == 0) {
            // Draw: refund both players
            uint256 refund = game.betAmount;
            game.player1.call{value: refund}("");
            game.player2.call{value: refund}("");
            emit GameDraw(gameId, refund);
        } else {
            address winner = result == 1 ? game.player1 : game.player2;
            uint256 prize = game.betAmount * 2;

            (bool sent, ) = winner.call{value: prize}("");
            require(sent, "ETH transfer failed");

            emit GameFinished(gameId, winner, prize);
        }
    }

    // 0 = draw, 1 = player1 wins, 2 = player2 wins
    function _getResult(Move move1, Move move2) private pure returns (uint8) {
        if (move1 == move2) return 0;

        if (
            (move1 == Move.Rock && move2 == Move.Scissors) ||
            (move1 == Move.Paper && move2 == Move.Rock) ||
            (move1 == Move.Scissors && move2 == Move.Paper)
        ) {
            return 1;
        }

        return 2;
    }

    // Safety: if opponent never reveals, creator can cancel after deadline
    function cancelIfNoReveal(uint256 gameId) external onlyPlayer(gameId) {
        Game storage game = games[gameId];

        if (game.status != Status.RevealPhase) revert WrongPhase();
        if (block.timestamp <= game.revealDeadline) revert RevealPeriodOver();

        game.status = Status.Cancelled;

        uint256 refund = game.betAmount;
        game.player1.call{value: refund}("");
        game.player2.call{value: refund}("");

        emit GameCancelled(gameId, refund);
    }

    function getGame(uint256 gameId)
        external
        view
        returns (Game memory)
    {
        return games[gameId];
    }
}
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
