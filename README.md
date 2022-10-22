# Hyperoku contracts
This repository contains the **contracts** for the Hyperoku project, with the related **tests** and **scripts**. 
Inside the [`data`](https://github.com/hyperoku/contracts/tree/main/data) folder, two charts show the gas usage of the function used for sudokus generation: this shows why it is needed to hardcode the (pseudo)randomness seeds.
## Contracts Structure
The contracts are four:
- [**`SudokuGenerator`**](https://github.com/hyperoku/contracts/blob/main/src/SudokuGenerator.sol): its main function generates a sudoku (with encrypted solution) given a pseudo-random seed and difficulty level.
- [**`SeedsManager`**](https://github.com/hyperoku/contracts/blob/main/src/SeedsManager.sol): manages the seeds for the sudokus generation.
- [**`RandomSudokuGenerator`**](https://github.com/hyperoku/contracts/blob/main/src/RandomSudokuGenerator.sol): inherits from `SudokuGenerator`; interacts with the Chainlink's VRF V2 Wrapper to get a random number. This number is used to choose randomly a seed from the `SeedsManager`, used to generate the sudoku.
- [**`RoundsManager`**](https://github.com/hyperoku/contracts/blob/main/src/RoundsManager.sol): the higher level contract, which manages the rounds and games of Hyperoku. It directly interacts with the `RandomSudokuGenerator` to generate sudokus.

## Tests
For the testing, it has been used [Foundry](https://github.com/foundry-rs/foundry), forking Mumbai, the Polygon testnet. Here can be found the Chainlinks contracts, which we use for the randomness (the fulfillment function is mocked, the request one is not).

To test the contracts, create a `.env` and run the `forge test` command in this way:
```
cp .env.example .env
source .env
forge test --fork-url $MUMBAI_RPC_URL --fork-block-number $FORK_BLOCK_NUMBER
```
You can also use ```coverage``` instead of ```test``` to get the coverage report.

## Deploy
To deploy the contracts, insert your private key inside the `.env` file, then run the following command:
```
forge script script/Deploy.s.sol:Deploy --rpc-url $MUMBAI_RPC_URL --broadcast --verify -vvvv
```
Probably this and `tests` script could fail because of the RPC, so in case change it or retry.