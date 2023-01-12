// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IMinimumPriorityQueue {
    // Errors
    error EmptyPriorityQueue();
    error CannotInsert0();

    // Public variables
    function size() external view returns (uint256);

    // View functions
    function isEmpty() external view returns (bool);

    function minimum() external view returns (uint256);

    function heap() external view returns (uint256[] memory);

    // Mutator functions
    function insert(uint256 _key) external;

    function deleteMinimum() external returns(uint256);
}