// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import ISudokuGenerator
import "./ISudokuGenerator.sol";

contract SudokuGenerator is ISudokuGenerator {

    // random0 function values: https://en.wikipedia.org/wiki/Linear_congruential_generator
    uint16 constant a = 8121;
    uint16 constant c = 28411;
    uint32 constant m = 134456;

    function generateRandom(uint64 _current_random_number)
        internal
        pure
        returns (uint64 new_random_number, uint8 value) 
    {
        new_random_number = uint64(a * _current_random_number + c) % m;
        value = uint8(uint256(keccak256(abi.encodePacked(new_random_number))) % 9);
    }

    function isValid(
        uint8[9][9] memory _grid,
        uint8 _row,
        uint8 _col,
        uint8 _num
    ) internal pure returns (bool) {
        for (uint8 x = 0; x < 9; x++) {
            if (_grid[_row][x] == _num) {
                return false;
            }
        }
        for (uint8 x = 0; x < 9; x++) {
            if (_grid[x][_col] == _num) {
                return false;
            }
        }
        uint8 _rowStart = _row - (_row % 3);
        uint8 _colStart = _col - (_col % 3);
        for (uint8 x = _rowStart; x < _rowStart + 3; x++) {
            for (uint8 y = _colStart; y < _colStart + 3; y++) {
                if (_grid[x][y] == _num) {
                    return false;
                }
            }
        }
        return true;
    }

    function generateSudoku(uint8 difficulty)
        external
        pure
        override
        returns (string memory sudoku, bytes32 solution)
    {
        uint8[9][9] memory grid;
        uint64 current_random_number = 123181231237;

        // reset grid
        for (uint8 i = 0; i < 9; i++) {
            for (uint8 j = 0; j < 9; j++) {
                grid[i][j] = 0;
            }
        }

        // generate full sudoku grid
        uint8 cell_value;
        for (uint8 i = 0; i < 9; i++) {
            for (uint8 j = 0; j < 9; j++) {
                (current_random_number, cell_value) = generateRandom(current_random_number);
                while (!isValid(grid, i, j, cell_value+1)) {
                    (current_random_number, cell_value) = generateRandom(current_random_number);
                }
                grid[i][j] = cell_value;
            }
        }
        delete cell_value;
        solution = keccak256(abi.encodePacked(grid));

        // remove random cells
        uint8 row;
        uint8 col;
        for (uint8 i = 0; i < difficulty; i++) {
            (current_random_number, row) = generateRandom(current_random_number);
            (current_random_number, col) = generateRandom(current_random_number);
            while (grid[row][col] == 0) {
                (current_random_number, row) = generateRandom(current_random_number);
                (current_random_number, col) = generateRandom(current_random_number);
            }
            grid[row][col] = 0;
        }
        delete row;
        delete col;

        // convert grid to string
        for (uint8 i = 0; i < 9; i++) {
            for (uint8 j = 0; j < 9; j++) {
                sudoku = string(abi.encodePacked(sudoku, grid[i][j]));
            }
        }
    }
}
