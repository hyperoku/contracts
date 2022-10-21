# Hyperoku contracts
This repository contains the **contracts** for the Hyperoku project, with relative **tests** and **scripts**. 
Inside the `data` folder, there are two charts showing the gas usage of the function used for sudokus generation: this shows the reason why is needed to hardcode the seeds for the randomness.
## Contracts Structure
The contracts are four:
- **`SudokuGenerator.sol`**: generates a sudoku with a given pseudo-random seed and difficulty level.
- **`SeedsManager.sol`**: manages the seeds for the sudokus generation.
- **`RandomSudokuGenerator.sol`**: inherits from `SudokuGenerator.sol`; interacts with the Chainlink's VRF V2 Wrapper to get a random number. This number is used to choose randomly a seed from the `SeedsManager.sol`, used to generate the sudoku.
- **`RoundsManager.sol`**: the higher level contract, which manages the rounds and games of Hyperoku. It directly interacts with the `RandomSudokuGenerator.sol` to generate sudokus.

## Tests
For the testing, it has been used [Foundry](https://github.com/foundry-rs/foundry), forking Mumbai, the Polygon testnet. Here can be found Chainlinks contracts, which we use for the randomness (the fulfillment function is mocked, the request one is not).

To test the contracts, use the command:
```
forge test --fork-url https://rpc-mumbai.matic.today --fork-block-number 28669025
```
You can also use ```coverage``` instead of ```test``` to get the coverage report.