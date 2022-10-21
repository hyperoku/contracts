// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SudokuGenerator.sol";

contract SudokuGeneratorTest is Test {

    SudokuGenerator public sudokuGenerator;

    function setUp() public {
        sudokuGenerator = new SudokuGenerator();
    }

    function testGetDifficultyRange() public view {
        (uint8 min, uint8 max) = sudokuGenerator.getDifficultyRange();
        assert(min != 0 && max != 0);
    }

    function testGenerateSudoku() public {
        (string memory sudoku, bytes32 solution) = sudokuGenerator.generateSudoku(0, 40);
        assert(bytes(sudoku).length == 81);
        assert(solution != 0);
    }

    function testGenerateSudokuShouldFail() public {
        vm.expectRevert(VALUE_OUT_OF_BOUNDS.selector);
        sudokuGenerator.generateSudoku(0, 0);
        vm.expectRevert(VALUE_OUT_OF_BOUNDS.selector);
        sudokuGenerator.generateSudoku(0, 100);
    }

}