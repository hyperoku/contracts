// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISeedsManager {
    function getSeed(uint32) external view returns (uint32);
    function addSeeds(uint32[] calldata) external;
}