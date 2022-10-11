pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RoundsManager {

    struct Game {
        uint64 id;
        uint32 round_id;
        address player;
        uint64 start_blockNumber;
        uint64 end_blockNumber;
        string sudoku;
        bytes32 solution;
    }
    
    struct Round {
        uint32 id;
        mapping (uint64 => Game) games;
        string difficulty;
        uint64 start_blockNumber;
        uint64 end_blockNumber;
    }

    mapping (uint32 => Round) public rounds;
    mapping (uint64 => Game) public games;
    mapping (string => uint8) difficulty_values;
    mapping (string => uint32) public last_active_round_ids; // DIFFICULTY -> ROUND ID
    string[] public difficulty_names = ["EASY", "MEDIUM", "HARD"];
    uint32 public total_rounds;
    uint64 public total_games;
    uint32 public round_duration_in_blocks = 4320; // in Mumbai testnet, 1 block ~= 5 seconds -> 4320*5=21600s=6h
    uint8 public min_game_duration_in_blocks = 12; // 12*5=60s=1min

    modifier difficultyExists(string memory _difficulty) {
        require(
            difficulty_values[_difficulty] != 0,
            "Invalid difficulty."
        ),
        _;
    }

    constructor () public {
        difficulty_values["EASY"] = 37;
        difficulty_values["MEDIUM"] = 48;
        difficulty_values["HARD"] = 53;
    }

    function createRound(string memory _difficulty) 
        internal 
        difficultyExists(_difficulty) 
        returns (uint32 round_id) 
    {
        require(
            rounds[last_active_rounds_ids[_difficulty]].end_blockNumber < block.number,
            "There is already an active round for this difficulty."
        );
        Round memory round = Round(
            total_rounds, 
            _difficulty, 
            uint64(block.number), 
            uint64(block.number + round_duration_in_blocks)
        );
        total_rounds++;
        rounds[round.id] = round;
        last_active_rounds_ids[_difficulty] = total_rounds;
        return round.id;
    }

    function createGame(string memory _difficulty) 
        public 
        difficultyExists(_difficulty) 
        returns (string memory sudoku) 
    {
        uint32 round_id = last_active_rounds_ids[_difficulty];
        if (rounds[round_id].end_blockNumber < block.number || round_id == 0) {
            round_id = create_round(_difficulty);
        } else {
            require(
                rounds[last_active_rounds_ids[_difficulty]].end_blockNumber > block.number + min_game_duration_in_blocks, 
                "The round is ending soon."
            );
        }
        uint64 game_id = total_games;
        string memory sudoku;
        bytes32 solution;
        (sudoku, solution) = generate_sudoku(_difficulty);
        Game memory game = Game(game_id, round_id, msg.sender, block.number, 0, sudoku, solution);
        games[game_id] = game;
        rounds[round_id].games[game_id] = game;
        total_games++;
        return sudoku;
    }

    function addNewDifficulty(string name, uint8 value) public onlyOwner {
        require(
            difficulty_values[name] == 0, 
            "Difficulty already exists."
        );
        require(
            value > 16 && value < 64, 
            "Difficulty value must be between 16 and 64."
        );
        difficulty.push(name);
        difficulty_values[name] = value;
    }

}