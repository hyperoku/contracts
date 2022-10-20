// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SeedsManager.sol";

contract SeedsManagerTest is Test {

    SeedsManager public seedsManager;

    function setUp() public {
        seedsManager = new SeedsManager();
    }

    function testGetterMethods() public view {
        uint32 seed = seedsManager.getSeed(1);
        assert(seed == 3);
        uint32 last = seedsManager.getLastSeed();
        assert(last == 3145);
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
        assert(last == 3148);
        uint32 seed0 = seedsManager.getSeed(0);
        uint32 seed1 = seedsManager.getSeed(1);
        assert(seed0 == 0);
        assert(seed1 == 3);
    }

    function testRemoveLastNSeeds() public {
        seedsManager.removeLastNSeeds(3);
        uint32 last = seedsManager.getLastSeed();
        assert(last == 3140);
    }

    function testRemoveLastNSeedsEmptiesTheArray() public {
        seedsManager.removeLastNSeeds(2000);
        uint32 last = seedsManager.getLastSeed();
        assert(last == 0);
    }

}