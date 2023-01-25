// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../lib/MinimumPriorityQueue_Uint40.sol";

contract MockMinimumPriorityQueue_Uint40 {
    using MinimumPriorityQueue_Uint40 for MinimumPriorityQueue_Uint40.PriorityQueue;
    MinimumPriorityQueue_Uint40.PriorityQueue _queue;

    function insert(uint40 _key) external {
        _queue.insert(_key);
    }

    function deleteMinimum() external returns(uint40 min) {
        return _queue.deleteMinimum();
    }

    function size() external view returns (uint256) {
        return _queue.size();
    }

    function heap() external view returns (uint40[] memory) {
        return _queue.heap();
    }

    function isEmpty() external view returns (bool) {
        return _queue.isEmpty();
    }

    function minimum() external view returns (uint40) {
        return _queue.minimum();
    }
}