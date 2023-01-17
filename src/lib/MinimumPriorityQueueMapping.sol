// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/console.sol";

library MinimumPriorityQueueMapping {
    error EmptyPriorityQueue();
    error CannotInsert0();

    struct Queue {
        uint256 _size;
        mapping(uint256 => uint256) _heap;
    }

    // External view functions
    function size(Queue storage self) internal view returns (uint256) {
        return self._size;
    }

    function heap(Queue storage self) internal view returns (uint256[] memory) {
        uint256[] memory heapIndexes = new uint[](self._size);
        for (uint256 i; i < self._size;) {
            heapIndexes[i] = self._heap[i + 1];
            unchecked{++i;}
        }
        return heapIndexes;
    }    

    function isEmpty(Queue storage self) internal view returns (bool) {
        return self._size == 0;
    }

    function minimum(Queue storage self) internal view returns (uint256) {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        return self._heap[1];
    }

    // External mutator functions
    function insert(Queue storage self, uint256 _key) internal {
        if (_key == 0) revert CannotInsert0();
        uint256 newSize = ++self._size;
        self._heap[newSize] = _key;
        _swim(self, newSize);
    }

    function deleteMinimum(Queue storage self) internal returns(uint256 min) {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        // Is this copy by value into memory, or by reference from storage
        min = self._heap[1];
        uint256 newSize = --self._size;
        self._heap[1] = self._heap[newSize + 1];
        self._heap[newSize + 1] = 0;
        if (newSize == 0) return min;
        _sink(self, 1);
    }

    // Internal utility functions

    function _swim(Queue storage self, uint256 heapIndex) private {
        // Perform operations in memory (cheaper) before saving result in storage. Perform minimum operations in storage.

        // Obtain max # of heap indexes we will interact with in _swim operation
        uint256 maxHeapIndexCount = 1;
        {
            uint256 i = heapIndex;
            while (i > 1) {
                unchecked{++maxHeapIndexCount;}
                i >>= 1; // Bitwise operation for /= 2
            }
        }
        // Obtain relevant heap indexes
        uint256[] memory heapIndexes = new uint[](maxHeapIndexCount);
        uint256[] memory originalHeapContents = new uint[](maxHeapIndexCount);
        uint256[] memory modifiedHeapContents = new uint[](maxHeapIndexCount);

        {
            uint256 i = heapIndex;
            uint256 j;
            while (i >= 1) {
                heapIndexes[j] = i;
                modifiedHeapContents[j] = self._heap[i]; // SLOAD here
                originalHeapContents[j] = modifiedHeapContents[j];
                i >>= 1; // Bitwise operation for /= 2
                unchecked{++j;}
            }
        }
        // Perform swim on modifiedHeapContents
        {
            uint256 j;
            while (j + 1 < maxHeapIndexCount && _compare(modifiedHeapContents[j + 1], modifiedHeapContents[j]) == false) {
                // Does this work to swap the in-memory array indexes?
                (modifiedHeapContents[j + 1], modifiedHeapContents[j]) = (modifiedHeapContents[j], modifiedHeapContents[j + 1]);
                unchecked{++j;}
            }
        }

        // Copy in-memory modifiedHeapContents back into in-storage _heap. In theory we should be able to halve the number of SSTOREs with this _swim implementation.
        for (uint256 i = 0; i < maxHeapIndexCount;) {
            if (originalHeapContents[i] != modifiedHeapContents[i]) {
                self._heap[heapIndexes[i]] = modifiedHeapContents[i]; // SSTORE here
            }
            unchecked{++i;}
        }
    }

    function _sink(Queue storage self, uint256 heapIndex) private {
        // Obtain max # of heap indexes we will interact with in _swim operation
        uint256 maxHeapIndexCount = 1;
        uint256 heapSize = size(self); // Save _size to memory, to minimize SLOAD for _size

        {
            uint256 i = heapIndex;
            while (i << 1 <= heapSize) {
                unchecked{++maxHeapIndexCount;}
                i <<= 1;
            }
        }

        // Obtain relevant heap indexes
        uint256[] memory heapIndexes = new uint[](maxHeapIndexCount);
        uint256[] memory originalHeapContents = new uint[](maxHeapIndexCount);
        uint256[] memory modifiedHeapContents = new uint[](maxHeapIndexCount);

        {
            uint256 i = heapIndex;
            uint256 j;

            heapIndexes[j] = i;
            modifiedHeapContents[j] = self._heap[i]; // SLOAD here
            originalHeapContents[j] = modifiedHeapContents[j];

            while (i << 1 <= heapSize) {
                uint256 k = i << 1;
                uint256 heap_k = self._heap[k]; // SLOAD 1
                
                // If right child exists
                if (k < heapSize) {
                    uint256 heap_kPlus1 = self._heap[k + 1]; // SLOAD 2
                    // If left child < right child, choose left child
                    if (_compare(heap_k, heap_kPlus1) == false) {
                        unchecked{++k;}
                        heap_k = heap_kPlus1;
                    }
                }

                // If current_node <= _child, no need to swim further.
                if (_compare(modifiedHeapContents[0], heap_k) == true) {
                    break;
                }
    
                // Copy into memory arrays
                i = k;
                unchecked{++j;}
                heapIndexes[j] = i;
                modifiedHeapContents[j] = heap_k;
                originalHeapContents[j] = heap_k;

            }
        }

        // Perform sink on modifiedHeapContents
        {
            uint256 j;
            while (j + 1 < maxHeapIndexCount && modifiedHeapContents[j + 1] != 0 && _compare(modifiedHeapContents[j + 1], modifiedHeapContents[j]) == true) {
                // Does this work to swap the in-memory array indexes?
                (modifiedHeapContents[j + 1], modifiedHeapContents[j]) = (modifiedHeapContents[j], modifiedHeapContents[j + 1]);
                unchecked{++j;}
            }
        }

        // Copy in-memory modifiedHeapContents back into in-storage _heap. In theory we should be able to halve the number of SSTOREs with this _sink implementation.
        for (uint256 i = 0; i < maxHeapIndexCount;) {
            if (originalHeapContents[i] != modifiedHeapContents[i]) {
                self._heap[heapIndexes[i]] = modifiedHeapContents[i]; // SSTORE here
            }
            unchecked{++i;}
        }
    }

    function _compare(uint256 a, uint256 b) internal pure returns (bool) {
        if (a < b) return true;
        else return false;
    }
}