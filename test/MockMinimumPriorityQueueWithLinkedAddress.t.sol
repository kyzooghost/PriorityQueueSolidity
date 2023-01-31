// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/mocks/MockMinimumPriorityQueueWithLinkedAddress.sol";
import "../src/lib/MinimumPriorityQueueWithLinkedAddress.sol";

contract MockMinimumPriorityQueueWithLinkedAddressTest is Test {
    MockMinimumPriorityQueueWithLinkedAddress public queue;

    function setUp() public {
        queue = new MockMinimumPriorityQueueWithLinkedAddress();
    }

    /*
     * UNIT TESTS
     */

    function testUnit_VariablesAtSetUp() public {
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
    }

    function testUnit_insert_SingleInsert() public {
        queue.insert(1, address(1));
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        (uint256 min, address min_address) = queue.minimum();
        assertEq(min, 1);
        assertEq(min_address, address(1));
    }

    function testUnit_deleteMinimum_ShouldRevertWhenHeapEmpty() public {
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMinimum();
    }

    function testUnit_minimum_ShouldRevertWhenHeapEmpty() public {
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.minimum();
    }

    function testUnit_ensureNonPhantomMinimum_ShouldReturnTrueWhenHeapEmpty() public {
        assertEq(queue.ensureNonPhantomMinimum(), true);
    }

    /*
     * INTEGRATION TESTS
     */

    function testIntegration_SingleInsertAndDeleteMinimum() public {
        queue.insert(1, address(1));
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        (uint256 min, address min_address) = queue.minimum();
        assertEq(min, 1);
        assertEq(min_address, address(1));
        assertEq(queue.deleteMinimum(), 1);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.minimum();
    }

    function testIntegration_SingleInsertAndDeleteKey() public {
        queue.insert(1, address(1));
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(1));
        }

        queue.ensureNonPhantomMinimum();

        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(1));
            assertEq(queue.isEmpty(), false);
            assertEq(queue.size(), 1);
        }

        assertEq(queue.deleteKey(2), false);
        assertEq(queue.deleteKey(1), true);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);

        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(0));
        }

        queue.ensureNonPhantomMinimum();
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);

        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.minimum();
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMinimum();
    }

    function testIntegration_InsertAndDeleteFiveNumbers() public {
        queue.insert(5, address(5));
        queue.insert(3, address(3));
        queue.insert(2, address(2));
        queue.insert(1, address(1));
        queue.insert(4, address(4));

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        (uint256 min, address min_address) = queue.minimum();
        assertEq(min, 1);
        assertEq(min_address, address(1));

        uint[] memory heap_keys = new uint[](queue.size());
        address[] memory addresses_in_key = new address[](queue.size());
        heap_keys = queue.heap();

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
        }

        assertEq(queue.deleteMinimum(), 1);
        assertEq(queue.deleteMinimum(), 2);
        assertEq(queue.deleteMinimum(), 3);
        assertEq(queue.deleteMinimum(), 4);
        assertEq(queue.deleteMinimum(), 5);

        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.minimum();
    }

    function testIntegration_InsertFiveNumbersAndDeleteFirstTwoKeys() public {
        queue.insert(5, address(5));
        queue.insert(3, address(3));
        queue.insert(2, address(2));
        queue.insert(1, address(1));
        queue.insert(4, address(4));

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(1));
        }

        uint[] memory heap_keys = new uint[](queue.size());
        address[] memory addresses_in_key = new address[](queue.size());
        heap_keys = queue.heap();

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
        }

        // Delete two keys - 1 and 3

        assertEq(queue.deleteKey(1), true);
        assertEq(queue.deleteKey(2), true);
        assertEq(queue.deleteKey(2), false);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            uint256 heap_key = heap_keys[i];

            if (heap_key == 1 || heap_key == 2) {
                assertEq(addresses_in_key[i], address(0));
            } else {
                assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
            }
        }

        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(0));
        }

        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 3);
        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 3);
            assertEq(min_address, address(3));
        }

        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.deleteMinimum(), 3);
        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.deleteMinimum(), 4);
        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.deleteMinimum(), 5);

        assertEq(queue.ensureNonPhantomMinimum(), true);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.minimum();
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMinimum();
    }

    function testIntegration_InsertFiveNumbersAndDeleteLastTwoKeys() public {
        queue.insert(5, address(5));
        queue.insert(3, address(3));
        queue.insert(2, address(2));
        queue.insert(1, address(1));
        queue.insert(4, address(4));

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(1));
        }

        uint[] memory heap_keys = new uint[](queue.size());
        address[] memory addresses_in_key = new address[](queue.size());
        heap_keys = queue.heap();

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
        }

        // Delete two keys - 1 and 3

        assertEq(queue.deleteKey(4), true);
        assertEq(queue.deleteKey(5), true);
        assertEq(queue.deleteKey(5), false);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            uint256 heap_key = heap_keys[i];

            if (heap_key == 4 || heap_key == 5) {
                assertEq(addresses_in_key[i], address(0));
            } else {
                assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
            }
        }

        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(1));
        }

        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        {
            (uint256 min, address min_address) = queue.minimum();
            assertEq(min, 1);
            assertEq(min_address, address(1));
        }

        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.deleteMinimum(), 1);
        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.deleteMinimum(), 2);
        assertEq(queue.ensureNonPhantomMinimum(), false);
        assertEq(queue.deleteMinimum(), 3);

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 2);

        assertEq(queue.ensureNonPhantomMinimum(), true);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);

        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.minimum();
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMinimum();
    }

    function testIntegration_NItemsTest() public {

        uint256 n = 100;

        for (uint256 i = n; i > 0; i--) {
            queue.insert(i, address(uint160(i)));
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

        queue.insert(a, address(uint160(a)));
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.DuplicateKey.selector);
        queue.insert(a, address(0));
        queue.insert(b, address(uint160(b)));
        queue.insert(c, address(uint160(c)));
        queue.insert(d, address(uint160(d)));
        queue.insert(e, address(uint160(e)));

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);

        uint256 min1 = queue.deleteMinimum();
        uint256 min2 = queue.deleteMinimum();
        uint256 min3 = queue.deleteMinimum();
        uint256 min4 = queue.deleteMinimum();
        uint256 min5 = queue.deleteMinimum();
        
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        vm.expectRevert(MinimumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
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
