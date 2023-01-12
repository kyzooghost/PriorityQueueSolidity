// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MinimumPriorityQueue.sol";

contract MinimumPriorityQueueTest is Test {
    MinimumPriorityQueue public queue;

    function setUp() public {
        queue = new MinimumPriorityQueue();
    }

    function testVariablesAtSetUp() public {
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
    }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
