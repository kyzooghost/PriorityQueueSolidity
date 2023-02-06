// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/mocks/MockMaximumPriorityQueueWithLinkedAddress.sol";
import "../src/lib/MaximumPriorityQueueWithLinkedAddress.sol";

contract MockMaximumPriorityQueueWithLinkedAddressTest is Test {
    MockMaximumPriorityQueueWithLinkedAddress public queue;

    function setUp() public {
        queue = new MockMaximumPriorityQueueWithLinkedAddress();
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
        (uint256 max, address max_address) = queue.maximum();
        assertEq(max, 1);
        assertEq(max_address, address(1));
    }

    function testUnit_deleteMaximum_ShouldRevertWhenHeapEmpty() public {
        vm.expectRevert(MaximumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMaximum();
    }

    function testUnit_maximum_ShouldRevertWhenHeapEmpty() public {
        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));
    }

    function testUnit_ensureNonPhantomMaximum_ShouldReturnTrueWhenHeapEmpty() public {
        assertEq(queue.ensureNonPhantomMaximum(), true);
    }

    // /*
    //  * INTEGRATION TESTS
    //  */

    function testIntegration_SingleInsertAndDeleteMinimum() public {
        queue.insert(1, address(1));
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        (uint256 max, address max_address) = queue.maximum();
        assertEq(max, 1);
        assertEq(max_address, address(1));
        assertEq(queue.deleteMaximum(), 1);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));
    }

    function testIntegration_SingleInsertAndDeleteKey() public {
        queue.insert(1, address(1));
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);
        {
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 1);
            assertEq(max_address, address(1));
        }

        queue.ensureNonPhantomMaximum();

        {
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 1);
            assertEq(max_address, address(1));
            assertEq(queue.isEmpty(), false);
            assertEq(queue.size(), 1);
        }

        assertEq(queue.deleteKey(2), false);
        assertEq(queue.deleteKey(1), true);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 1);

        {
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 1);
            assertEq(max_address, address(0));
        }

        queue.ensureNonPhantomMaximum();
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);

        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));
        vm.expectRevert(MaximumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMaximum();
    }

    function testIntegration_InsertAndDeleteFiveNumbers() public {
        queue.insert(5, address(5));
        queue.insert(3, address(3));
        queue.insert(2, address(2));
        queue.insert(1, address(1));
        queue.insert(4, address(4));

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        (uint256 max, address max_address) = queue.maximum();
        assertEq(max, 5);
        assertEq(max_address, address(5));

        uint[] memory heap_keys = new uint[](queue.size());
        address[] memory addresses_in_key = new address[](queue.size());
        heap_keys = queue.heap();

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
        }

        assertEq(queue.deleteMaximum(), 5);
        assertEq(queue.deleteMaximum(), 4);
        assertEq(queue.deleteMaximum(), 3);
        assertEq(queue.deleteMaximum(), 2);
        assertEq(queue.deleteMaximum(), 1);

        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));
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
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 5);
            assertEq(max_address, address(5));
        }

        uint[] memory heap_keys = new uint[](queue.size());
        address[] memory addresses_in_key = new address[](queue.size());
        heap_keys = queue.heap();

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
        }

        // Delete two keys - 4 and 5

        assertEq(queue.deleteKey(5), true);
        assertEq(queue.deleteKey(4), true);
        assertEq(queue.deleteKey(4), false);
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
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 5);
            assertEq(max_address, address(0));
        }

        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 3);
        {
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 3);
            assertEq(max_address, address(3));
        }

        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.deleteMaximum(), 3);
        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.deleteMaximum(), 2);
        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.deleteMaximum(), 1);

        assertEq(queue.ensureNonPhantomMaximum(), true);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));
        vm.expectRevert(MaximumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMaximum();
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
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 5);
            assertEq(max_address, address(5));
        }

        uint[] memory heap_keys = new uint[](queue.size());
        address[] memory addresses_in_key = new address[](queue.size());
        heap_keys = queue.heap();

        for (uint i; i < queue.size(); i++) {
            addresses_in_key[i] = queue.addresses()[i];
            assertEq(addresses_in_key[i], address(uint160(heap_keys[i])));
        }

        // Delete two keys - 1 and 2

        assertEq(queue.deleteKey(2), true);
        assertEq(queue.deleteKey(1), true);
        assertEq(queue.deleteKey(1), false);
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
            (uint256 max, address max_address) = queue.maximum();
            assertEq(max, 5);
            assertEq(max_address, address(5));
        }

        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);
        {
            (uint256 min, address max_address) = queue.maximum();
            assertEq(min, 5);
            assertEq(max_address, address(5));
        }

        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.deleteMaximum(), 5);
        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.deleteMaximum(), 4);
        assertEq(queue.ensureNonPhantomMaximum(), false);
        assertEq(queue.deleteMaximum(), 3);

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 2);

        assertEq(queue.ensureNonPhantomMaximum(), true);
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);

        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));
        vm.expectRevert(MaximumPriorityQueueWithLinkedAddress.EmptyPriorityQueue.selector);
        queue.deleteMaximum();
    }

    function testIntegration_NItemsTest() public {
        uint256 n = 100;

        for (uint256 i = 1; i < n + 1; i++) {
            queue.insert(i, address(uint160(i)));
        }

        for (uint256 i = 0; i < n; i++) {
            assertEq(queue.deleteMaximum(), n - i);
        }
    }

    // /*
    //  * FUZZING TESTS
    //  */

    function testFuzz_InsertAndDeleteFiveNumbers(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) public {
        vm.assume(a > 0 && b > 0 && c > 0 && d > 0 && e > 0);
        vm.assume(e < d && d < c && c < b && b < a);

        queue.insert(a, address(uint160(a)));
        vm.expectRevert(MaximumPriorityQueueWithLinkedAddress.DuplicateKey.selector);
        queue.insert(a, address(0));
        queue.insert(b, address(uint160(b)));
        queue.insert(c, address(uint160(c)));
        queue.insert(d, address(uint160(d)));
        queue.insert(e, address(uint160(e)));

        assertEq(queue.isEmpty(), false);
        assertEq(queue.size(), 5);

        uint256 max1 = queue.deleteMaximum();
        uint256 max2 = queue.deleteMaximum();
        uint256 max3 = queue.deleteMaximum();
        uint256 max4 = queue.deleteMaximum();
        uint256 max5 = queue.deleteMaximum();
        
        assertEq(queue.isEmpty(), true);
        assertEq(queue.size(), 0);
        (uint256 max_, address max_address_) = queue.maximum();
        assertEq(max_, 0);
        assertEq(max_address_, address(0));

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
