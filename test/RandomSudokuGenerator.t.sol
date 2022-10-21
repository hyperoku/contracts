// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SeedsManager.sol";
import "../src/RandomSudokuGenerator.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract RandomSudokuGeneratorTest is Test {

    ISeedsManager public seedsManager;
    RandomSudokuGenerator public randomSudokuGenerator;
    
    address constant linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant vrfWrapperAddress = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;
    address constant faucet = 0xE84D601E5D945031129a83E5602be0CC7f182Cf3;

    IERC20 public link = IERC20(linkAddress);

    function setUp() public {
        seedsManager = new SeedsManager();
        randomSudokuGenerator = new RandomSudokuGenerator(
            linkAddress, vrfWrapperAddress, address(seedsManager)
        );
        vm.startPrank(faucet);
        link.transfer(address(randomSudokuGenerator), 1*10**18);
        vm.stopPrank();
    }

    function testRequestRandomSudokuAndFulfill() public {
        uint256 requestId = randomSudokuGenerator.requestRandomSudoku(35);
        assertTrue(requestId != 0, "requestId should not be 0");

        // EMULATE CHAINLINK CALLBACK --> we are now the vrf wrapper :P
        vm.startPrank(vrfWrapperAddress);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456789;
        randomSudokuGenerator.rawFulfillRandomWords(requestId, randomWords);
        vm.stopPrank();
        RandomSudokuGenerator.RequestStatus memory request = randomSudokuGenerator.getRequestStatus(requestId);
        assertTrue(request.fulfilled, "request should be fulfilled");
        assertTrue(request.paid > 0, "request should be paid");
        assertTrue(bytes(request.sudoku).length == 81, "sudoku should be 81 chars long");
        assertTrue(request.solution != 0, "solution should not be 0");
    }

    function testRequestRandomSudokuFailsDifficultyOOB() public {
        vm.expectRevert(VALUE_OUT_OF_BOUNDS.selector);
        randomSudokuGenerator.requestRandomSudoku(0);
        vm.expectRevert(VALUE_OUT_OF_BOUNDS.selector);
        randomSudokuGenerator.requestRandomSudoku(100);
    }

    function testRawFulfillRandomWordsNotCallableByAnyone() public {
        vm.expectRevert("only VRF V2 wrapper can fulfill");
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456789;
        randomSudokuGenerator.rawFulfillRandomWords(1, randomWords);
    }

    function testRawFulfillRandomWordsFailsIfRequestDontExists() public {
        vm.expectRevert(REQUEST_NOT_FOUND.selector);
        vm.startPrank(vrfWrapperAddress);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456789;
        randomSudokuGenerator.rawFulfillRandomWords(123456, randomWords);
    }

    function testWithdrawLink() public {
        uint256 balanceBefore = link.balanceOf(address(this));
        randomSudokuGenerator.withdrawLink();
        uint256 balanceAfter = link.balanceOf(address(this));
        assert(balanceAfter == balanceBefore + 1*10**18);
    }

    function testWithdrawLinkFailsIfNoOwner() public {
        vm.expectRevert("Only callable by owner");
        vm.startPrank(faucet);
        randomSudokuGenerator.withdrawLink();
    }

    function testGetterShouldFailIfRequestDoesNotExist() public {
        vm.expectRevert(REQUEST_NOT_FOUND.selector);
        randomSudokuGenerator.getRequestStatus(123456);
    }

}