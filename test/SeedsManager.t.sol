// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SeedsManager.sol";

contract SeedsManagerTest is Test {

    SeedsManager public seedsManager;

    function setUp() public {
        seedsManager = new SeedsManager();
    }

    function testGetterMethods() public {
        uint32 seed = seedsManager.getSeed(1);
        uint32 last = seedsManager.getLastSeed();
        assertTrue(seed == 3, "seed should be 3 (see seeds array)");
        assertTrue(last == 3145, "last seed should be 3145 (see seeds array)");
    }

    function testAddSeeds() public {
        uint32[] memory seeds = new uint32[](5);
        seeds[0] = 0;
        seeds[1] = 700;
        seeds[2] = 1600;
        seeds[3] = 3147;
        seeds[4] = 3148;
        seedsManager.addSeeds(seeds);
        uint32 last = seedsManager.getLastSeed();
        uint32 seed0 = seedsManager.getSeed(0);
        uint32 seed1 = seedsManager.getSeed(1);
        assertTrue(last == 3148, "last seed should be 3148");
        assertTrue(seed0 == 0, "seed 0 should be 0 (see seeds array)");
        assertTrue(seed1 == 3, "seed 1 should be 3 (see seeds array)");
    }

    function testRemoveLastNSeeds() public {
        seedsManager.removeLastNSeeds(3);
        uint32 last = seedsManager.getLastSeed();
        assertTrue(last == 3140, "last seed should be 3140 after removal (see seeds array)");
    }

    function testRemoveLastNSeedsEmptiesTheArray() public {
        seedsManager.removeLastNSeeds(2000);
        uint32 last = seedsManager.getLastSeed();
        assertTrue(last == 0, "seeds array should be empty");
    }

}