// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/mocks/MockPriorityQueue.sol";
import "../src/lib/PriorityQueue.sol";

contract MockPriorityQueueTest is Test {
    MockPriorityQueue public queue;

    function setUp() public {
        queue = new MockPriorityQueue(PriorityQueue.Orientation.Minimum);
    }

    /*
     * INTEGRATION TESTS
     */

    function testIntegration_SingleInsertAndDeleteMinimum() public {
        queue.insert(1);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        assertEq(queue.minimum(), 1);
        assertEq(queue.deleteMinimum(), 1);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(PriorityQueue.EmptyPriorityQueue.selector);
        queue.minimum();
    }

    function testIntegration_InsertAndDeleteFiveNumbers() public {
        queue.insert(5);
        queue.insert(3);
        queue.insert(2);
        queue.insert(1);
        queue.insert(4);

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        assertEq(queue.minimum(), 1);

        assertEq(queue.deleteMinimum(), 1);
        assertEq(queue.deleteMinimum(), 2);
        assertEq(queue.deleteMinimum(), 3);
        assertEq(queue.deleteMinimum(), 4);
        assertEq(queue.deleteMinimum(), 5);

        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(PriorityQueue.EmptyPriorityQueue.selector);
        queue.minimum();
    }

    function testIntegration_NItemsTest() public {

        uint256 n = 1000;

        for (uint256 i = n; i > 0; i--) {
            queue.insert(i);
        }

        for (uint256 i = n; i > 0; i--) {
            assertEq(queue.deleteMinimum(), n + 1 - i);
        }

    }

    /*
     * FUZZING TESTS
     */

    function testFuzz_InsertAndDeleteFiveNumbers(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) public {
        vm.assume(a > 0 && b > 0 && c > 0 && d > 0 && e > 0);
        vm.assume(e > d && d > c && c > b && b > a);

        queue.insert(a);
        queue.insert(b);
        queue.insert(c);
        queue.insert(d);
        queue.insert(e);

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);

        uint256 min1 = queue.deleteMinimum();
        uint256 min2 = queue.deleteMinimum();
        uint256 min3 = queue.deleteMinimum();
        uint256 min4 = queue.deleteMinimum();
        uint256 min5 = queue.deleteMinimum();
        
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(PriorityQueue.EmptyPriorityQueue.selector);
        queue.minimum();

        assertEq(min1 <= min2, true);
        assertEq(min2 <= min3, true);
        assertEq(min3 <= min4, true);
        assertEq(min4 <= min5, true);
        assertEq(min1, a);
        assertEq(min2, b);
        assertEq(min3, c);
        assertEq(min4, d);
        assertEq(min5, e);
    }
}
