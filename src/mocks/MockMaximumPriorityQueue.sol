// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../lib/MaximumPriorityQueue.sol";

contract MockMaximumPriorityQueue {
    using MaximumPriorityQueue for MaximumPriorityQueue.PriorityQueue;
    MaximumPriorityQueue.PriorityQueue _queue;

    function insert(uint256 _key) external {
        _queue.insert(_key);
    }

    function deleteMaximum() external returns(uint256 min) {
        return _queue.deleteMaximum();
    }

    function size() external view returns (uint256) {
        return _queue.size();
    }

    function heap() external view returns (uint256[] memory) {
        return _queue.heap();
    }

    function isEmpty() external view returns (bool) {
        return _queue.isEmpty();
    }

    function maximum() external view returns (uint256) {
        return _queue.maximum();
    }
}