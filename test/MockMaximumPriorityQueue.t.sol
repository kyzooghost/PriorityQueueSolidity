// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/mocks/MockMaximumPriorityQueue.sol";
import "../src/lib/MaximumPriorityQueue.sol";

contract MockMaximumPriorityQueueTest is Test {
    MockMaximumPriorityQueue public queue;

    function setUp() public {
        queue = new MockMaximumPriorityQueue();
    }

    /*
     * UNIT TESTS
     */

    function testUnit_VariablesAtSetUp() public {
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
    }

    function testUnit_insert_SingleInsert() public {
        queue.insert(1);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        assertEq(queue.maximum(), 1);
    }

    function testUnit_deleteMaximum_ShouldRevertWhenHeapEmpty() public {
        vm.expectRevert(MaximumPriorityQueue.EmptyPriorityQueue.selector);
        queue.deleteMaximum();
    }

    function testUnit_maximum_ShouldRevertWhenHeapEmpty() public {
        vm.expectRevert(MaximumPriorityQueue.EmptyPriorityQueue.selector);
        queue.maximum();
    }

    /*
     * INTEGRATION TESTS
     */

    function testIntegration_SingleInsertAndDeleteMaximum() public {
        queue.insert(1);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        assertEq(queue.maximum(), 1);
        assertEq(queue.deleteMaximum(), 1);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MaximumPriorityQueue.EmptyPriorityQueue.selector);
        queue.maximum();
    }

    function testIntegration_InsertAndDeleteFiveNumbers() public {
        queue.insert(5);
        queue.insert(3);
        queue.insert(2);
        queue.insert(1);
        queue.insert(4);

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        assertEq(queue.maximum(), 5);

        assertEq(queue.deleteMaximum(), 5);
        assertEq(queue.deleteMaximum(), 4);
        assertEq(queue.deleteMaximum(), 3);
        assertEq(queue.deleteMaximum(), 2);
        assertEq(queue.deleteMaximum(), 1);

        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MaximumPriorityQueue.EmptyPriorityQueue.selector);
        queue.maximum();
    }

    function testIntegration_NItemsTest() public {

        uint256 n = 10000;

        for (uint256 i = 1; i < n + 1; i++) {
            queue.insert(i);
        }

        for (uint256 i = 0; i < n; i++) {
            assertEq(queue.deleteMaximum(), n - i);
        }

    }

    /*
     * FUZZING TESTS
     */

    function testFuzz_InsertAndDeleteFiveNumbers(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) public {
        vm.assume(a > 0 && b > 0 && c > 0 && d > 0 && e > 0);
        vm.assume(e < d && d < c && c < b && b < a);

        queue.insert(a);
        queue.insert(b);
        queue.insert(c);
        queue.insert(d);
        queue.insert(e);

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);

        uint256 max1 = queue.deleteMaximum();
        uint256 max2 = queue.deleteMaximum();
        uint256 max3 = queue.deleteMaximum();
        uint256 max4 = queue.deleteMaximum();
        uint256 max5 = queue.deleteMaximum();
        
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MaximumPriorityQueue.EmptyPriorityQueue.selector);
        queue.maximum();

        assertEq(max1 >= max2, true);
        assertEq(max2 >= max3, true);
        assertEq(max3 >= max4, true);
        assertEq(max4 >= max5, true);
        assertEq(max1, a);
        assertEq(max2, b);
        assertEq(max3, c);
        assertEq(max4, d);
        assertEq(max5, e);
    }
}
