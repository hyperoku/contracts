// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RoundsManager.sol";
import "../src/SudokuGenerator.sol";
import "../src/RandomSudokuGenerator.sol";
import "../src/SeedsManager.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "chainlink/contracts/src/v0.8/VRFCoordinatorV2.sol";

contract RoundsManagerTest is Test {
    SudokuGenerator public sudokuGenerator;
    RoundsManager public roundsManager;
    RandomSudokuGenerator public randomSudokuGenerator;
    SeedsManager public seedsManager;

    address faucet = vm.envAddress("FAUCET_ADDRESS");
    address vrfWrapperAddress = vm.envAddress("VRF_WRAPPER_ADDRESS");
    address linkAddress = vm.envAddress("LINK_ADDRESS");

    IERC20 public link = IERC20(linkAddress);

    function setUp() public {
        sudokuGenerator = new SudokuGenerator();
        seedsManager = new SeedsManager();
        randomSudokuGenerator = new RandomSudokuGenerator(
            linkAddress,
            vrfWrapperAddress,
            address(seedsManager)
        );
        roundsManager = new RoundsManager(address(randomSudokuGenerator));
        vm.startPrank(faucet);
        link.transfer(address(randomSudokuGenerator), 1 * 10**18);
        vm.stopPrank();
    }

    function compareStrings(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    function testCreateGameAndCreateRound() public {
        string memory difficulty = "MEDIUM";
        uint64 game_id = roundsManager.createGame(difficulty);
        RoundsManager.Game memory game = roundsManager.getGame(game_id);
        RoundsManager.Round memory round = roundsManager.getRound(
            game.round_id
        );
        assertTrue(game.round_id == round.id, "Round id is not the same");
        assertTrue(
            compareStrings(round.difficulty, difficulty),
            "Difficulty should be MEDIUM"
        );
        assertTrue(round.id == 0, "round.id should be 0");
        assertTrue(
            round.game_ids[0] == game_id,
            "game_id should be added to round"
        );
        assertTrue(roundsManager.total_games() == 1, "total_games should be 1");
        assertTrue(
            roundsManager.total_rounds() == 1,
            "total_rounds should be 1"
        );
        assertTrue(
            roundsManager.last_active_round_ids("MEDIUM") == 0,
            "last_active_round_ids should be 0"
        );
    }

    function testCreateMultipleGamesAndRounds() public {
        string[] memory difficulties = roundsManager.getDifficultyNames();
        uint8 length = uint8(difficulties.length);
        uint8 cycles = 5;
        uint8 counter;
        for (uint8 i = 0; i < cycles; i++) {
            for (uint8 j = 0; j < length; j++) {
                uint64 game_id = roundsManager.createGame(difficulties[j]);
                RoundsManager.Game memory game = roundsManager.getGame(game_id);
                RoundsManager.Round memory round = roundsManager.getRound(
                    game.round_id
                );
                assertTrue(
                    game.round_id == round.id,
                    "Round id is not the same"
                );
                assertTrue(
                    compareStrings(round.difficulty, difficulties[j]),
                    "Difficulty should be the choose one"
                );
                assertTrue(game.id == counter, "game.id should be counter");
                assertTrue(
                    round.game_ids[round.game_ids.length - 1] == game_id,
                    "game_id should be added to round"
                );
                counter++;
            }
        }
        assertTrue(
            roundsManager.total_games() == difficulties.length * cycles,
            "total_games should be 30"
        );
        assertTrue(
            roundsManager.total_rounds() == length,
            "total_rounds should be 3"
        );
    }

    function testCreateGameFailsWithWrongDifficultyName() public {
        vm.expectRevert(DIFFICULTY_NAME_NOT_FOUND.selector);
        string memory name = "NAME";
        roundsManager.createGame(name);
    }

    function testCreateGameFailsIfRoundEndsSoon() public {
        uint32 round_duration_in_blocks = roundsManager.round_duration_in_blocks();
        roundsManager.createGame("MEDIUM");
        vm.roll(block.number + round_duration_in_blocks - 2);
        vm.expectRevert(ROUND_ENDS_SOON.selector);
        roundsManager.createGame("MEDIUM");
    }

    function testSolveGameAndItsFailures() public {
        uint64 game_id = roundsManager.createGame("MEDIUM");
        RoundsManager.Game memory game = roundsManager.getGame(game_id);
        // EMULATE CHAINLINK CALLBACK --> we are now the vrf wrapper :P
        vm.startPrank(vrfWrapperAddress);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0;
        randomSudokuGenerator.rawFulfillRandomWords(
            game.request_id,
            randomWords
        );
        vm.expectRevert(PLAYER_IS_NOT_THE_OWNER.selector);
        roundsManager.solveGame(game_id, "12378917283719");
        vm.stopPrank();
        vm.expectRevert(SOLUTION_IS_WRONG.selector); // solution too short
        roundsManager.solveGame(game_id, "123456789");
        vm.expectRevert(SOLUTION_IS_WRONG.selector); // solution wrong
        string memory solution = "123125698629487315185693274278346951931758462456219783514962837762831549893574126";
        roundsManager.solveGame(game_id, solution);
        solution = "689214357412357896735689124163495782257863941948172563871546239524931678396728415";
        roundsManager.solveGame(game_id, solution); // solution is correct
        vm.expectRevert(GAME_ALREADY_SOLVED.selector);
        roundsManager.solveGame(game_id, solution);
    }

    function testAddNewDifficulty() public {
        uint8 max_difficulty_value = roundsManager.MAX_DIFFICULTY_VALUE();
        roundsManager.addNewDifficulty("SUPERHARD", max_difficulty_value - 1);
        assertTrue(
            roundsManager
                .difficulty_values("SUPERHARD") == max_difficulty_value - 1,
            "difficulty_values should be 1 less than max_difficulty_value"
        );
        assertTrue(
            compareStrings(roundsManager.difficulty_names(3), "SUPERHARD"),
            "difficulty_names should be SUPERHARD"
        );
    }

    function testAddNewDifficultyFailsNameAlreadyExists() public {
        string memory name = "NAME";
        uint8 value = 50;
        roundsManager.addNewDifficulty(name, value);
        value = 51;
        vm.expectRevert(DIFFICULTY_NAME_ALREADY_EXISTS.selector);
        roundsManager.addNewDifficulty(name, value);
    }

    function testAddNewDifficultyFailsValueAlreadyExists() public {
        string memory name = "NAME";
        uint8 value = 50;
        roundsManager.addNewDifficulty(name, value);
        name = "NAME2";
        vm.expectRevert(DIFFICULTY_VALUE_ALREADY_EXISTS.selector);
        roundsManager.addNewDifficulty(name, value);
    }

    function testAddNewDifficultyFailsOutOfBounds() public {
        string memory name = "NAME";
        uint8 max_difficulty_value = roundsManager.MAX_DIFFICULTY_VALUE();
        uint8 min_difficulty_value = roundsManager.MIN_DIFFICULTY_VALUE();
        vm.expectRevert(DIFFICULTY_VALUE_OUT_OF_BOUNDS.selector);
        roundsManager.addNewDifficulty(name, max_difficulty_value + 1);
        vm.expectRevert(DIFFICULTY_VALUE_OUT_OF_BOUNDS.selector);
        roundsManager.addNewDifficulty(name, min_difficulty_value - 1);
    }

    function testGetLastActiveRound() public {
        string memory difficulty = "MEDIUM";
        uint64 game_id = roundsManager.createGame(difficulty);
        uint64 round_id = roundsManager.getGame(game_id).round_id;
        assertTrue(
            roundsManager.getLastActiveRound(difficulty).id == round_id,
            "getLastActiveRound should be the same as round_id"
        );
    }

    function testChangeRandomSudokuGenerator() public {
        RandomSudokuGenerator new_random_sudoku_generator = new RandomSudokuGenerator(
            linkAddress,
            vrfWrapperAddress,
            address(seedsManager)
        );
        roundsManager.changeRandomSudokuGenerator(
            address(new_random_sudoku_generator)
        );
        assertTrue(
            address(roundsManager.random_sudoku_generator()) == address(
                new_random_sudoku_generator
            ),
            "random_sudoku_generator should be the new one"
        );
    }
}
