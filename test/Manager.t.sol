// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/RoundsManager.sol";
import "../src/SudokuGenerator.sol";

contract ManagerTest is Test {
    SudokuGenerator public sudokuGenerator;
    RoundsManager public roundsManager;

    function setUp() public {
        sudokuGenerator = new SudokuGenerator();
        roundsManager = new RoundsManager(address(sudokuGenerator));
    }

    function testCreateGame() public {
        // console.log("0");
        roundsManager.createGame("EASY");
        // console.log("1");
        roundsManager.createGame("EASY");
        // console.log("2");
        roundsManager.createGame("HARD");
        // console.log("3");
        roundsManager.createGame("EASY");
        // console.log("4");
        roundsManager.createGame("MEDIUM");
        // console.log("5");
        roundsManager.createGame("HARD");
        // console.log("6");
        roundsManager.createGame("EASY");
        RoundsManager.Round memory round = roundsManager.getLastActiveRound("MEDIUM");
        // print all game ids of a round
        for (uint i = 0; i < round.game_ids.length; i++) {
            console.log("game id: %d", round.game_ids[i]);
        }
    }
}
