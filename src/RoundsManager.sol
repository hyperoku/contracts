// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISudokuGenerator.sol";

error InvalidDifficulty();
error RoundEndsSoon();
error AnotherRoundAlreadyActive();

contract RoundsManager is Ownable {

    ISudokuGenerator public constant sudokuGenerator = ISudokuGenerator(0x5FbDB2315678afecb367f032d93F642f64180aa3);

    struct Game {
        uint64 id;
        uint32 round_id;
        address player;
        string sudoku;
        bytes32 solution;
        uint256 start_blockNumber;
        uint256 end_blockNumber;
    }

    struct Round {
        uint32 id;
        string difficulty;
        uint64[] game_ids;
        uint256 start_blockNumber;
        uint256 end_blockNumber;
    }

    mapping(uint32 => Round) public rounds;
    mapping(uint64 => Game) public games;
    mapping(string => uint8) difficulty_values;
    mapping(string => uint32) public last_active_round_ids; // DIFFICULTY -> ROUND ID
    string[] public difficulty_names = ["EASY", "MEDIUM", "HARD"];
    uint32 public total_rounds;
    uint64 public total_games;
    uint32 public round_duration_in_blocks = 4320; // in Mumbai testnet, 1 block ~= 5 seconds -> 4320*5=21600s=6h
    uint8 public min_game_duration_in_blocks = 12; // 12*5=60s=1min

    uint8 public constant MIN_DIFFICULTY_VALUE = 16;
    uint8 public constant MAX_DIFFICULTY_VALUE = 64;

    modifier difficultyExists(string calldata _difficulty) {
        if (difficulty_values[_difficulty] == 0) 
            revert InvalidDifficulty();
        _;
    }

    constructor() {
        difficulty_values["EASY"] = 37;
        difficulty_values["MEDIUM"] = 48;
        difficulty_values["HARD"] = 53;
    }

    function createRound(string calldata _difficulty)
        internal
        difficultyExists(_difficulty)
        returns (uint32 round_id)
    {
        if (rounds[last_active_round_ids[_difficulty]].end_blockNumber >= block.number)
            revert AnotherRoundAlreadyActive();
        uint64[] memory round_games;
        Round memory round = Round(
            total_rounds,
            _difficulty,
            round_games,
            block.number,
            block.number + round_duration_in_blocks
        );
        total_rounds++;
        rounds[round.id] = round;
        last_active_round_ids[_difficulty] = total_rounds;
        return round.id;
    }

    function createGame(string calldata _difficulty)
        public
        difficultyExists(_difficulty)
        returns (string memory sudoku)
    {
        uint32 round_id = last_active_round_ids[_difficulty];
        if (rounds[round_id].end_blockNumber < block.number || round_id == 0) {
            round_id = createRound(_difficulty);
        } 
        else {
            if (
                rounds[last_active_round_ids[_difficulty]].end_blockNumber 
                    <=
                block.number + min_game_duration_in_blocks
            )   
                revert RoundEndsSoon();
        }
        uint64 game_id = total_games;
        bytes32 solution;
        (sudoku, solution) = sudokuGenerator.generateSudoku(
            difficulty_values[_difficulty]
        );
        Game memory game = Game(
            game_id,
            round_id,
            msg.sender,
            sudoku,
            solution,
            block.number,
            0
        );
        games[game_id] = game;
        rounds[round_id].game_ids.push(game_id);
        total_games++;
        return sudoku;
    }

    function addNewDifficulty(string calldata name, uint8 value)
        public
        onlyOwner
    {
        if (difficulty_values[name] != 0)
            revert InvalidDifficulty();
        if (value < MIN_DIFFICULTY_VALUE || value > MAX_DIFFICULTY_VALUE)
            revert InvalidDifficulty();
        difficulty_names.push(name);
        difficulty_values[name] = value;
    }

}
