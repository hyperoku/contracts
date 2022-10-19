// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./RandomSudokuGenerator.sol";
import "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "forge-std/console.sol";

error ROUND_ENDS_SOON();
error DIFFICULTY_NAME_NOT_FOUND();
error DIFFICULTY_VALUE_OUT_OF_BOUNDS();
error DIFFICULTY_NAME_ALREADY_EXISTS();
error DIFFICULTY_VALUE_ALREADY_EXISTS();

contract RoundsManager is ConfirmedOwner {

    RandomSudokuGenerator public immutable random_sudoku_generator;

    struct Game {
        uint256 request_id;
        uint64 id;
        uint32 round_id;
        address player;
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

    mapping(uint32 => Round) private rounds;
    mapping(uint64 => Game) private games;

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
            revert DIFFICULTY_NAME_NOT_FOUND();
        _;
    }

    event roundCreated(uint32 round_id);
    event gameCreated(uint64 game_id);

    constructor(address _random_sudoku_generator) ConfirmedOwner(msg.sender) {
        random_sudoku_generator = RandomSudokuGenerator(_random_sudoku_generator);
        (MIN_DIFFICULTY_VALUE, MAX_DIFFICULTY_VALUE) = 
            random_sudoku_generator.getDifficultyRange();
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
            emit roundCreated(round_id);
            return round_id;
        }
    }

    function createGame(string calldata _difficulty)
        external
        difficultyExists(_difficulty)
        returns (uint64 game_id)
    {
        unchecked {
            uint32 round_id = last_active_round_ids[_difficulty];
            Round memory last_active_round = rounds[round_id];
            if (
                last_active_round.end_blockNumber < block.number ||
                !stringsEqual(last_active_round.difficulty, _difficulty)
            ) {
                round_id = createRound(_difficulty);
            } else {
                if (
                    rounds[last_active_round_ids[_difficulty]]
                        .end_blockNumber <=
                    block.number + min_game_duration_in_blocks
                ) revert ROUND_ENDS_SOON();
            }
            uint256 request_id = random_sudoku_generator.requestRandomSudoku(
                difficulty_values[_difficulty]
            );
            game_id = total_games;
            total_games++;
            Game memory game = Game(
                request_id,
                game_id,
                round_id,
                msg.sender,
                block.number,
                0
            );
            games[game_id] = game;
            rounds[round_id].game_ids.push(game_id);
            emit gameCreated(game_id);
            return game_id;
        }
    }

    function addNewDifficulty(string calldata _name, uint8 _value)
        external
        onlyOwner
    {
        if (_value < MIN_DIFFICULTY_VALUE || _value > MAX_DIFFICULTY_VALUE) {
            revert DIFFICULTY_VALUE_OUT_OF_BOUNDS();
        }
        if (difficulty_values[_name] != 0) revert DIFFICULTY_NAME_ALREADY_EXISTS();
        for (uint8 i = 0; i < difficulty_names.length; i++) {
            if (difficulty_values[difficulty_names[i]] == _value)
                revert DIFFICULTY_VALUE_ALREADY_EXISTS();
        }
        difficulty_names.push(_name);
        difficulty_values[_name] = _value;
    }

    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return (
            keccak256(abi.encodePacked((_a))) ==
            keccak256(abi.encodePacked((_b)))
        );
    }

    function getLastActiveRound(string calldata _difficulty)
        external
        view
        returns (Round memory)
    {
        return rounds[last_active_round_ids[_difficulty]];
    }

    function getGame(uint64 _game_id) external view returns (Game memory) {
        return games[_game_id];
    }

    function getRound(uint32 _round_id) external view returns (Round memory) {
        return rounds[_round_id];
    }
}
