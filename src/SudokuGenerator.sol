// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/Strings.sol";

error VALUE_OUT_OF_BOUNDS();

contract SudokuGenerator {
    // random0 function values: https://en.wikipedia.org/wiki/Linear_congruential_generator
    uint16 constant a = 8121;
    uint16 constant c = 28411;
    uint32 constant m = 134456;

    uint8 public constant MIN_DIFFICULTY_VALUE = 16;
    uint8 public constant MAX_DIFFICULTY_VALUE = 64;

    function generateRandomValue(
        uint32 _current_random_number,
        uint8 mod,
        uint8 offset
    ) internal pure returns (uint32 new_random_number, uint8 value) {
        unchecked {
            new_random_number = uint32(a * _current_random_number + c) % m;
            value =
                uint8(
                    uint256(keccak256(abi.encodePacked(new_random_number))) %
                        mod
                ) +
                offset;
        }
    }

    function isSafe(
        uint8[9][9] memory _board,
        uint8 _row,
        uint8 _col,
        uint8 _num
    ) internal pure returns (bool) {
        unchecked {
            for (uint8 i = 0; i < 9; ++i) {
                if (_board[_row][i] == _num) {
                    return false;
                }
            }
            for (uint8 i = 0; i < 9; ++i) {
                if (_board[i][_col] == _num) {
                    return false;
                }
            }
            uint8 row_start = _row - (_row % 3);
            uint8 col_start = _col - (_col % 3);
            for (uint8 i = row_start; i < row_start + 3; ++i) {
                for (uint8 j = col_start; j < col_start + 3; ++j) {
                    if (_board[i][j] == _num) {
                        return false;
                    }
                }
            }
            return true;
        }
    }

    function fillRemaining(
        uint8[9][9] memory grid,
        uint8 i,
        uint8 j
    ) internal returns (bool) {
        unchecked {
            if (j >= 9 && i < 8) {
                i = i + 1;
                j = 0;
            }
            if (i >= 9 && j >= 9) {
                return true;
            }
            if (i < 3) {
                if (j < 3) {
                    j = 3;
                }
            } else if (i < 6) {
                if (j == uint8(int8(i / 3) * 3)) {
                    j = j + 3;
                }
            } else {
                if (j == 6) {
                    i = i + 1;
                    j = 0;
                    if (i >= 9) {
                        return true;
                    }
                }
            }
            for (uint8 num = 1; num <= 9; ++num) {
                if (isSafe(grid, i, j, num)) {
                    grid[i][j] = num;
                    if (fillRemaining(grid, i, j + 1)) {
                        return true;
                    }
                    grid[i][j] = 0;
                }
            }
            return false;
        }
    }

    function generateSudoku(uint32 seed, uint8 difficulty)
        external
        returns (string memory sudoku, bytes32 solution)
    {
        if (
            difficulty < MIN_DIFFICULTY_VALUE ||
            difficulty > MAX_DIFFICULTY_VALUE
        ) {
            revert VALUE_OUT_OF_BOUNDS();
        }
        unchecked {
            uint8[9][9] memory grid = [
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0]
            ];
            uint32 current_random_number = seed;

            // fill diagonal 3x3 boxes
            uint8[9][3] memory boxes = [
                [1, 2, 3, 4, 5, 6, 7, 8, 9],
                [1, 2, 3, 4, 5, 6, 7, 8, 9],
                [1, 2, 3, 4, 5, 6, 7, 8, 9]
            ];
            uint8 random_index;
            for (uint8 i = 0; i < 3; ++i) {
                // randomize boxes[i]
                for (uint8 j = 0; j < 9; ++j) {
                    (current_random_number, random_index) = generateRandomValue(
                        current_random_number,
                        9,
                        0
                    );
                    (
                        boxes[i][j], 
                        boxes[i][random_index]
                    ) = (
                        boxes[i][random_index],
                        boxes[i][j]
                    );
                }
                // fill the 3x3 box
                for (uint8 j = 0; j < 3; ++j) {
                    for (uint8 k = 0; k < 3; ++k) {
                        grid[i * 3 + j][i * 3 + k] = boxes[i][j * 3 + k];
                    }
                }
            }

            // generate full sudoku grid
            fillRemaining(grid, 0, 3);

            // encrypt solution
            string memory sol_string = "";
            for (uint8 i = 0; i < 9; ++i) {
                for (uint8 j = 0; j < 9; ++j) {
                    sol_string = string.concat(
                        sol_string,
                        Strings.toString(grid[i][j])
                    );
                }
            }
            solution = keccak256(abi.encodePacked(sol_string));

            // remove n=difficulty values
            uint8 size = 81;
            uint8 position;
            uint8[81] memory positions = [
                0,1,2,3,4,5,6,7,8,9,10,
                11,12,13,14,15,16,17,18,19,20,
                21,22,23,24,25,26,27,28,29,30,
                31,32,33,34,35,36,37,38,39,40,
                41,42,43,44,45,46,47,48,49,50,
                51,52,53,54,55,56,57,58,59,60,
                61,62,63,64,65,66,67,68,69,70,
                71,72,73,74,75,76,77,78,79,80
            ];
            for (uint8 i = 0; i < difficulty; ++i) {
                (current_random_number, position) = generateRandomValue(
                    current_random_number,
                    size,
                    0
                );
                grid[positions[position] / 9][positions[position] % 9] = 0;
                positions[position] = positions[size - 1];
                size--;
            }

            // transform grid to string
            sudoku = "";
            for (uint8 i = 0; i < 9; ++i) {
                for (uint8 j = 0; j < 9; ++j) {
                    sudoku = string.concat(
                        sudoku,
                        Strings.toString(grid[i][j])
                    );
                }
            }
        }
    }

    function getDifficultyRange()
        external
        pure
        returns (uint8 min, uint8 max)
    {
        return (MIN_DIFFICULTY_VALUE, MAX_DIFFICULTY_VALUE);
    }
}