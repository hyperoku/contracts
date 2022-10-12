// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISudokuGenerator {
    function generateSudoku(uint8 difficulty) external returns (string memory, bytes32);
}