// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./RandomSudokuGenerator.sol";
import "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

error ROUND_ENDS_SOON();
error DIFFICULTY_NAME_NOT_FOUND();
error DIFFICULTY_VALUE_OUT_OF_BOUNDS();
error DIFFICULTY_NAME_ALREADY_EXISTS();
error DIFFICULTY_VALUE_ALREADY_EXISTS();
error PLAYER_IS_NOT_THE_OWNER();
error SOLUTION_IS_WRONG();
error GAME_ALREADY_SOLVED();

contract RoundsManager is ConfirmedOwner {
    RandomSudokuGenerator public random_sudoku_generator;

    struct Game {
        uint256 request_id;
        uint64 id;
        uint32 round_id;
        address player;
        uint256 start_blockTimestamp;
        uint256 end_blockTimestamp;
    }

    struct Round {
        uint32 id;
        string difficulty;
        uint64[] game_ids;
        uint256 start_blockTimestamp;
        uint256 end_blockTimestamp;
    }

    mapping(uint32 => Round) private rounds;
    mapping(uint64 => Game) private games;
    mapping(string => uint8) public difficulty_values;
    mapping(string => uint32) public last_active_round_ids; // DIFFICULTY -> ROUND ID

    string[] public difficulty_names = ["EASY", "MEDIUM", "HARD"];
    uint32 public total_rounds;
    uint64 public total_games;
    uint32 public round_duration = 21600; // 6h
    uint8 public min_game_duration = 60; // 1min

    uint8 public immutable MIN_DIFFICULTY_VALUE;
    uint8 public immutable MAX_DIFFICULTY_VALUE;

    modifier difficultyExists(string calldata _difficulty) {
        if (difficulty_values[_difficulty] == 0)
            revert DIFFICULTY_NAME_NOT_FOUND();
        _;
    }

    event roundCreated(uint32 indexed round_id);
    event gameCreated(uint64 indexed game_id);
    event gameSolved(uint64 indexed game_id);

    constructor(address _random_sudoku_generator) 
        ConfirmedOwner(msg.sender) 
    {
        random_sudoku_generator = RandomSudokuGenerator(
            _random_sudoku_generator
        );
        (MIN_DIFFICULTY_VALUE, MAX_DIFFICULTY_VALUE) = random_sudoku_generator
            .getDifficultyRange();
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
                block.timestamp,
                block.timestamp + round_duration
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
                last_active_round.end_blockTimestamp < block.timestamp ||
                !(stringsEqual(last_active_round.difficulty, _difficulty))
            ) {
                round_id = createRound(_difficulty);
            } else {
                if (
                    rounds[last_active_round_ids[_difficulty]]
                        .end_blockTimestamp <=
                    block.timestamp + min_game_duration
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
                block.timestamp,
                0
            );
            games[game_id] = game;
            rounds[round_id].game_ids.push(game_id);
            emit gameCreated(game_id);
            return game_id;
        }
    }

    function solveGame(uint64 _game_id, string calldata _player_solution)
        external
    {
        Game memory game = games[_game_id];
        if (game.player != msg.sender) {
            revert PLAYER_IS_NOT_THE_OWNER();
        }
        if (game.end_blockTimestamp != 0) {
            revert GAME_ALREADY_SOLVED();
        }
        if (bytes(_player_solution).length != 81) {
            revert SOLUTION_IS_WRONG();
        }
        bytes32 player_solution_hash = keccak256(
            abi.encodePacked(_player_solution)
        );
        bytes32 real_solution = random_sudoku_generator
            .getRequestStatus(game.request_id)
            .solution;
        if (player_solution_hash == real_solution) {
            games[_game_id].end_blockTimestamp = block.timestamp;
        } else {
            revert SOLUTION_IS_WRONG();
        }
        emit gameSolved(_game_id);
    }

    function addNewDifficulty(string calldata _name, uint8 _value)
        external
        onlyOwner
    {
        if (_value < MIN_DIFFICULTY_VALUE || _value > MAX_DIFFICULTY_VALUE) {
            revert DIFFICULTY_VALUE_OUT_OF_BOUNDS();
        }
        if (difficulty_values[_name] != 0) {
            revert DIFFICULTY_NAME_ALREADY_EXISTS();
        }
        for (uint8 i = 0; i < difficulty_names.length; i++) {
            if (difficulty_values[difficulty_names[i]] == _value)
                revert DIFFICULTY_VALUE_ALREADY_EXISTS();
        }
        difficulty_names.push(_name);
        difficulty_values[_name] = _value;
    }

    function changeRandomSudokuGenerator(address _new_random_sudoku_generator)
        external
        onlyOwner
    {
        random_sudoku_generator = RandomSudokuGenerator(
            _new_random_sudoku_generator
        );
    }

    function getDifficultyNames() external view returns (string[] memory) {
        return difficulty_names;
    }

    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        if (bytes(_a).length != bytes(_b).length) return false;
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
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
