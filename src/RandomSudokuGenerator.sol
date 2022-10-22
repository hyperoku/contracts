// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SudokuGenerator.sol";
import "./SeedsManager.sol";
import "chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

error UNABLE_TO_TRANSFER();
error REQUEST_NOT_FOUND();

contract RandomSudokuGenerator is
    SudokuGenerator,
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{
    SeedsManager public seedsManager;

    event RequestSent(uint256 indexed requestId);
    event RequestFulfilled(uint256 indexed requestId);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled;
        uint8 difficulty;
        string sudoku;
        bytes32 solution;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 2420000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;

    constructor(
        address _linkAddress,
        address _wrapperAddress,
        address _seedsManager
    )
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
        seedsManager = SeedsManager(_seedsManager);
    }

    function requestRandomSudoku(uint8 _difficulty)
        external
        returns (uint256 requestId)
    {
        if (
            _difficulty < MIN_DIFFICULTY_VALUE ||
            _difficulty > MAX_DIFFICULTY_VALUE
        ) {
            revert VALUE_OUT_OF_BOUNDS();
        }
        unchecked {
            requestId = requestRandomness(
                callbackGasLimit,
                requestConfirmations,
                numWords
            );
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
        }
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) 
        internal 
        override 
    {
        if (s_requests[_requestId].paid == 0) {
            revert REQUEST_NOT_FOUND();
        }
        string memory sudoku;
        bytes32 solution;
        uint32 seed = seedsManager.getSeed(uint32(_randomWords[0]));
        (sudoku, solution) = this.generateSudoku(
            seed,
            s_requests[_requestId].difficulty
        );
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].sudoku = sudoku;
        s_requests[_requestId].solution = solution;
        emit RequestFulfilled(_requestId);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (RequestStatus memory request)
    {
        if (s_requests[_requestId].paid == 0) {
            revert REQUEST_NOT_FOUND();
        }
        request = s_requests[_requestId];
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(address(LINK));
        if (!link.transfer(msg.sender, link.balanceOf(address(this)))) {
            revert UNABLE_TO_TRANSFER();
        }
    }
}
