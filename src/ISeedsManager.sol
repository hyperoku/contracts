// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISeedsManager {
    function getSeed(uint256) external view returns (uint16);
    function addSeeds(uint16[] calldata) external;
}