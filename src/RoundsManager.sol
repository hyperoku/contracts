// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "./ISudokuGenerator.sol";
import "forge-std/console.sol";

error InvalidDifficulty();
error RoundEndsSoon();

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

    modifier difficultyExists(string calldata _difficulty) {
        if (difficulty_values[_difficulty] == 0) 
            revert InvalidDifficulty();
        _;
    }

    constructor(address _sudokuGenerator) {
        sudokuGenerator = ISudokuGenerator(_sudokuGenerator);
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
            Round memory round = Round(
                total_rounds,
                _difficulty,
                round_games,
                block.number,
                block.number + round_duration_in_blocks
            );
            rounds[total_rounds] = round;
            last_active_round_ids[_difficulty] = total_rounds;
            total_rounds++;
            return round.id;
        }
    }

    function createGame(string calldata _difficulty)
        public
        difficultyExists(_difficulty)
        returns (string memory sudoku)
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
    }

    // function addNewDifficulty(string calldata name, uint8 value)
    //     public
    //     onlyOwner
    // {
    //     if (value < sudokuGenerator.MIN_DIFFICULTY_VALUE || value > sudokuGenerator.MAX_DIFFICULTY_VALUE) {
    //         revert InvalidDifficulty();
    //     }
    //     if (difficulty_values[name] != 0)
    //         revert InvalidDifficulty();
    //     difficulty_names.push(name);
    //     difficulty_values[name] = value;
    // }

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
