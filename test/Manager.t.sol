// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/RoundsManager.sol";
import "../src/SudokuGenerator.sol";
import "../src/RandomSudokuGenerator.sol";
import "../src/SeedsManager.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import 'chainlink/contracts/src/v0.8/VRFCoordinatorV2.sol';

contract ManagerTest is Test {
    SudokuGenerator public sudokuGenerator;
    RoundsManager public roundsManager;
    RandomSudokuGenerator public randomSudokuGenerator;
    SeedsManager public seedsManager;
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address vrfWrapperAddress = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;
    IERC20 public link;
    uint16 constant a = 8121;
    uint16 constant c = 28411;
    uint32 constant m = 134456;

    function setUp() public {
        sudokuGenerator = new SudokuGenerator();
        seedsManager = new SeedsManager();
        randomSudokuGenerator = new RandomSudokuGenerator(linkAddress, vrfWrapperAddress, address(seedsManager));
        roundsManager = new RoundsManager(address(randomSudokuGenerator));
        seedsManager = new SeedsManager();
        link = IERC20(linkAddress);
    }

    function compareStrings(string memory _a, string memory _b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint8 difficulty;
        string sudoku;
        bytes32 solution;
    }

    // function testSeeds() public {
    //     uint16[] memory seeds = new uint16[](2);
    //     seeds[0] = 1;
    //     seeds[1] = 2;
    //     seedsManager.addSeeds(seeds);
    //     uint16 seed = seedsManager.getSeed(123568126378);
    //     assertTrue(seed != 0, "Seed should not be 0");
    // }

    // function testSudokuGas() public {
    //     for (uint64 i = 0; i < 40000; i++) {
    //         sudokuGenerator.generateSudoku(i, 37);
    //     }
    // }

    function testAll() public {
        // Faucet address
        vm.startPrank(0xE84D601E5D945031129a83E5602be0CC7f182Cf3);
        link.transfer(address(randomSudokuGenerator), 1*10**18);
        vm.stopPrank();
        roundsManager.createGame("MEDIUM");
        RoundsManager.Round memory round = roundsManager.getRound(0);
        assertTrue(round.id == 0, "Round id should be 0");
    }

    // function testAddNewDifficulty(string memory name, uint8 value) public {
    //     uint8 min_difficulty_value = roundsManager.MIN_DIFFICULTY_VALUE();
    //     uint8 max_difficulty_value = roundsManager.MAX_DIFFICULTY_VALUE();
    //     vm.assume(value >= min_difficulty_value && value <= max_difficulty_value);
    //     vm.assume(value != 37 && value != 48 && value != 53);
    //     roundsManager.addNewDifficulty(name, value);
    // }

    // function testAddNewDifficultyNameAlreadyExists() public {
    //     string memory name = "NAME";
    //     uint8 value = 50;
    //     roundsManager.addNewDifficulty(name, value);
    //     value = 51;
    //     vm.expectRevert(DifficultyNameAlreadyExists.selector);
    //     roundsManager.addNewDifficulty(name, value);
    // }

    // function testAddNewDifficultyValueAlreadyExists() public {
    //     string memory name = "NAME";
    //     uint8 value = 50;
    //     roundsManager.addNewDifficulty(name, value);
    //     name = "NAME2";
    //     vm.expectRevert(DifficultyValueAlreadyExists.selector);
    //     roundsManager.addNewDifficulty(name, value);
    // }

    // function testCreateGameWithWrongDifficultyName() public {
    //     vm.expectRevert(DifficultyNameDoesNotExist.selector);
    //     string memory name = "NAME";
    //     roundsManager.createGame(name);
    // }

    // function testCreateGameSetsSudokuAndSolution() public {
    //     string memory name = "HARD";
    //     uint64 game = roundsManager.createGame(name);
    //     (,,,string memory sudoku, bytes32 solution,,) = roundsManager.games(game);
    //     console.log("Sudoku: %s", sudoku);
    //     console.log("Solution: %s", vm.toString(solution));
    // }

    // function testCreateMultipleGames() public {
    //     string[3] memory difficulties = ["EASY", "MEDIUM", "HARD"];
    //     for (uint8 i = 0; i < 3; i++) {
    //         for (uint8 j = 0; j < 10; j++) {
    //             roundsManager.createGame(difficulties[i]);
    //             roundsManager.createGame(difficulties[(i+1)%3]);
    //             roundsManager.createGame(difficulties[(i+2)%3]);
    //             roundsManager.createGame(difficulties[i]);
    //         }
    //     }
    //     RoundsManager.Round memory round = roundsManager.getLastActiveRound("EASY");
    //     for (uint i = 0; i < round.game_ids.length; i++) {
    //         console.log("game id: %d", round.game_ids[i]);
    //     }
    // }
}
