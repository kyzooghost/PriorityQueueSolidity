// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/mocks/MockMinimumPriorityQueue_Uint40.sol";
import "../src/lib/MinimumPriorityQueue_Uint40.sol";

contract MockMinimumPriorityQueue_Uint40Test is Test {
    MockMinimumPriorityQueue_Uint40 public queue;

    function setUp() public {
        queue = new MockMinimumPriorityQueue_Uint40();
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
        assertEq(queue.minimum(), 1);
    }

    function testUnit_deleteMinimum_ShouldRevertWhenHeapEmpty() public {
        vm.expectRevert(MinimumPriorityQueue_Uint40.EmptyPriorityQueue.selector);
        queue.deleteMinimum();
    }

    function testUnit_minimum_ShouldRevertWhenHeapEmpty() public {
        assertEq(queue.minimum(), 0);
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
        assertEq(queue.minimum(), 0);
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
        assertEq(queue.minimum(), 0);
    }

    function testIntegration_NItemsTest() public {
        uint40 n = 180;

        for (uint40 i = n; i > 0; i--) {
            queue.insert(i);
        }

        for (uint40 i = n; i > 0; i--) {
            assertEq(queue.deleteMinimum(), n + 1 - i);
        }
    }

    /*
     * FUZZING TESTS
     */

    function testFuzz_InsertAndDeleteFiveNumbers(uint40 a, uint40 b, uint40 c, uint40 d, uint40 e) public {
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
        assertEq(queue.minimum(), 0);

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
