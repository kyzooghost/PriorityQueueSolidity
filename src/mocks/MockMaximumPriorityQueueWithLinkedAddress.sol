// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../lib/MaximumPriorityQueueWithLinkedAddress.sol";

contract MockMaximumPriorityQueueWithLinkedAddress {
    using MaximumPriorityQueueWithLinkedAddress for MaximumPriorityQueueWithLinkedAddress.PriorityQueue;
    MaximumPriorityQueueWithLinkedAddress.PriorityQueue _queue;

    function insert(uint256 _key, address _address) external {
        _queue.insert(_key, _address);
    }

    function deleteMaximum() external returns(uint256 min) {
        return _queue.deleteMaximum();
    }

    function ensureNonPhantomMaximum() external returns (bool) {
        return _queue.ensureNonPhantomMaximum();
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

    function maximum() external view returns (uint256, address) {
        return _queue.maximum();
    }
}