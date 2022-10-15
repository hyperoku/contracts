// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SudokuGenerator.sol";
import "forge-std/console.sol";
import 'chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import 'chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';

contract RandomSudokuGenerator is SudokuGenerator, VRFV2WrapperConsumerBase, ConfirmedOwner {

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint8 difficulty;
        string sudoku;
        bytes32 solution;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 100000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;

    address immutable linkAddress;

    constructor(address _linkAddress, address _wrapperAddress)
        ConfirmedOwner(msg.sender) 
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress) 
    {
        linkAddress = _linkAddress;
    }

    function requestRandomSudoku(uint8 _difficulty) external returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            fulfilled: false,
            difficulty: _difficulty,
            sudoku: "",
            solution: ""
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, 'request not found');
        console.log(_randomWords[0]);
        string memory sudoku;
        bytes32 solution;
        (sudoku, solution) = this.generateSudoku(uint64(_randomWords[0]), s_requests[_requestId].difficulty);
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].sudoku = sudoku;
        s_requests[_requestId].solution = solution;
        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            string memory sudoku,
            bytes32 solution
        )
    {
        require(s_requests[_requestId].paid > 0, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.sudoku, request.solution);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

}