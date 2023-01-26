// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../lib/MinimumPriorityQueueWithLinkedAddress.sol";

contract MockMinimumPriorityQueueWithLinkedAddress {
    using MinimumPriorityQueueWithLinkedAddress for MinimumPriorityQueueWithLinkedAddress.PriorityQueue;
    MinimumPriorityQueueWithLinkedAddress.PriorityQueue _queue;

    function insert(uint256 _key, address _address) external {
        _queue.insert(_key, _address);
    }

    function deleteMinimum() external returns(uint256 min) {
        return _queue.deleteMinimum();
    }

    function ensureNonPhantomMinimum() external {
        return _queue.ensureNonPhantomMinimum();
    }

    function deleteKey(uint256 _key) external returns (bool) {
        return _queue.deleteKey(_key);
    }

    function size() external view returns (uint256) {
        return _queue.size();
    }

    function heap() external view returns (uint256[] memory) {
        return _queue.heap();
    }

    function addresses() external view returns (address[] memory) {
        return _queue.addresses();
    }

    function isEmpty() external view returns (bool) {
        return _queue.isEmpty();
    }

    function minimum() external view returns (uint256, address) {
        return _queue.minimum();
    }
}