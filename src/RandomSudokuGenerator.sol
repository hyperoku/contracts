// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ISudokuGenerator.sol";
import "forge-std/console.sol";
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';

contract RandomSudokuGenerator {
    ISudokuGenerator public immutable sudokuGenerator;

    constructor(address _sudokuGenerator) {
        sudokuGenerator = ISudokuGenerator(_sudokuGenerator);
    }
}