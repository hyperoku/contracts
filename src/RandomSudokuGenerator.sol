// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SudokuGenerator.sol";
import "./ISeedsManager.sol";
import "forge-std/console.sol";
import 'chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import 'chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';

contract RandomSudokuGenerator is SudokuGenerator, VRFV2WrapperConsumerBase, ConfirmedOwner {

    ISeedsManager public seedsManager;

    event RequestSent(uint256 indexed requestId);
    event RequestFulfilled(uint256 indexed requestId);

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
    uint32 callbackGasLimit = 2420000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;

    constructor(address _linkAddress, address _wrapperAddress, address _seedsManager)
        ConfirmedOwner(msg.sender) 
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
        seedsManager = ISeedsManager(_seedsManager);
    }

    function requestRandomSudoku(uint8 _difficulty) external returns (uint256 requestId) {
        unchecked {            
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
            emit RequestSent(requestId);
            return requestId;
        }
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, 'request not found');
        console.log(_randomWords[0]);
        string memory sudoku;
        bytes32 solution;
        uint64 seed = seedsManager.getSeed(uint32(_randomWords[0]));
        (sudoku, solution) = this.generateSudoku(seed, s_requests[_requestId].difficulty);
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].sudoku = sudoku;
        s_requests[_requestId].solution = solution;
        emit RequestFulfilled(_requestId);
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
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(address(LINK));
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

}