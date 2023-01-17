// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../lib/MinimumPriorityQueueMapping.sol";

contract MockMinimumPriorityQueueMapping {
    using MinimumPriorityQueueMapping for MinimumPriorityQueueMapping.Queue;
    MinimumPriorityQueueMapping.Queue _queue;

    function insert(uint256 _key) external {
        _queue.insert(_key);
    }

    function deleteMinimum() external returns(uint256 min) {
        return _queue.deleteMinimum();
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

    function minimum() external view returns (uint256) {
        return _queue.minimum();
    }
}