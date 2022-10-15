// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "./ISudokuGenerator.sol";
import "forge-std/console.sol";

error RoundEndsSoon();
error DifficultyNameDoesNotExist();
error DifficultyValueOutOfBounds();
error DifficultyNameAlreadyExists();
error DifficultyValueAlreadyExists();

contract RoundsManager is Ownable {

    ISudokuGenerator public immutable sudokuGenerator;

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
    mapping(string => uint8) public difficulty_values;
    mapping(string => uint32) public last_active_round_ids; // DIFFICULTY -> ROUND ID
    string[] public difficulty_names = ["EASY", "MEDIUM", "HARD"];
    uint32 public total_rounds;
    uint64 public total_games;
    uint32 public round_duration_in_blocks = 4320; // in Mumbai testnet, 1 block ~= 5 seconds -> 4320*5=21600s=6h
    uint8 public min_game_duration_in_blocks = 12; // 12*5=60s=1min

    uint8 public immutable MIN_DIFFICULTY_VALUE;
    uint8 public immutable MAX_DIFFICULTY_VALUE;

    modifier difficultyExists(string calldata _difficulty) {
        if (difficulty_values[_difficulty] == 0) 
            revert DifficultyNameDoesNotExist();
        _;
    }

    constructor(address _sudokuGenerator) {
        sudokuGenerator = ISudokuGenerator(_sudokuGenerator);
        (MIN_DIFFICULTY_VALUE, MAX_DIFFICULTY_VALUE) = sudokuGenerator.getDifficultyRange();
        difficulty_values["EASY"] = 37;
        difficulty_values["MEDIUM"] = 48;
        difficulty_values["HARD"] = 53;
    }

    function createRound(string calldata _difficulty)
        internal
        difficultyExists(_difficulty)
        returns (uint32 round_id)
    {
        unchecked {
            uint64[] memory round_games;
            round_id = total_rounds;
            total_rounds++;
            Round memory round = Round(
                round_id,
                _difficulty,
                round_games,
                block.number,
                block.number + round_duration_in_blocks
            );
            rounds[round_id] = round;
            last_active_round_ids[_difficulty] = round_id;
            return round_id;
        }
    }

    function createGame(string calldata _difficulty)
        public
        difficultyExists(_difficulty)
        returns (uint64 game_id)
    {
        unchecked {
            uint32 round_id = last_active_round_ids[_difficulty];
            Round memory last_active_round = rounds[round_id];
            if (
                last_active_round.end_blockNumber < block.number || 
                !stringsEqual(last_active_round.difficulty,_difficulty)
            ) {
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
            string memory sudoku;
            bytes32 solution;
            (sudoku, solution) = sudokuGenerator.generateSudoku(
                difficulty_values[_difficulty]
            );
            game_id = total_games;
            total_games++;
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
            return game_id;
        }
    }

    function addNewDifficulty(string calldata name, uint8 value)
        public
        onlyOwner
    {
        if (value < MIN_DIFFICULTY_VALUE || value > MAX_DIFFICULTY_VALUE) {
            revert DifficultyValueOutOfBounds();
        }
        if (difficulty_values[name] != 0)
            revert DifficultyNameAlreadyExists();
        for (uint8 i = 0; i < difficulty_names.length; i++) {
            if (difficulty_values[difficulty_names[i]] == value)
                revert DifficultyValueAlreadyExists();
        }
        difficulty_names.push(name);
        difficulty_values[name] = value;
    }

    function stringsEqual(string memory a, string memory b) 
        internal 
        pure 
        returns (bool) 
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
    }

    function getLastActiveRound(string calldata _difficulty)
        public
        view
        returns (Round memory)
    {
        return rounds[last_active_round_ids[_difficulty]];
    }
}
