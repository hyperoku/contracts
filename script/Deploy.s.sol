// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SeedsManager.sol";
import "../src/RandomSudokuGenerator.sol";
import "../src/RoundsManager.sol";

contract Deploy is Script {
    address linkAddress = vm.envAddress("LINK_ADDRESS");
    address vrfWrapperAddress = vm.envAddress("VRF_WRAPPER_ADDRESS");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        SeedsManager seedsManager = new SeedsManager();
        RandomSudokuGenerator randomSudokuGenerator = new RandomSudokuGenerator(
            linkAddress,
            vrfWrapperAddress,
            address(seedsManager)
        );
        new RoundsManager(address(randomSudokuGenerator));

        vm.stopBroadcast();
    }
}
