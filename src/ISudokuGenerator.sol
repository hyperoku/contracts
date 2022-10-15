// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISudokuGenerator {
    function generateSudoku(uint64 seed, uint8 difficulty) external returns (string memory, bytes32);
    function getDifficultyRange() external view returns (uint8, uint8);
}