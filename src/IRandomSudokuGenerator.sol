// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRandomSudokuGenerator {
    function requestRandomSudoku(uint8) external returns (uint256);
    function getDifficultyRange() external view returns (uint8, uint8);
}