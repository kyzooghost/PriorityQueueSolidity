// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

library MinimumPriorityQueue_Uint40 {
    error EmptyPriorityQueue();
    error CannotInsert0();

    struct PriorityQueue {
        uint40[] _heap;
    }

    // External view functions
    function size(PriorityQueue storage self) internal view returns (uint256) {
        if (self._heap.length == 0) return 0;
        else return self._heap.length - 1;
    }

    function heap(PriorityQueue storage self) internal view returns (uint40[] memory) {
        uint256 currentSize = size(self);
        uint40[] memory heapIndexes = new uint40[](currentSize);
        for (uint256 i; i < currentSize;) {
            heapIndexes[i] = self._heap[i + 1];
            unchecked{++i;}
        }
        return heapIndexes;
    }    

    function isEmpty(PriorityQueue storage self) internal view returns (bool) {
        return self._heap.length == 0 || self._heap.length == 1;
    }

    function minimum(PriorityQueue storage self) internal view returns (uint40) {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        return self._heap[1];
    }

    // External mutator functions
    function insert(PriorityQueue storage self, uint40 _key) internal {
        if (_key == 0) revert CannotInsert0();
        if (self._heap.length == 0) self._heap.push(0); 
        self._heap.push(_key);
        _swim(self, self._heap.length - 1);
    }

    function deleteMinimum(PriorityQueue storage self) internal returns(uint40 min) {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        min = self._heap[1];
        self._heap[1] = self._heap[self._heap.length - 1];
        self._heap.pop();
        if (isEmpty(self)) return min;
        _sink(self, 1);
    }

    // Internal utility functions
    // Source material for swim and sink operations - https://algs4.cs.princeton.edu/24pq/

    function _swim(PriorityQueue storage self, uint256 heapIndex) private {
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
        uint40[] memory originalHeapContents = new uint40[](maxHeapIndexCount);
        uint40[] memory modifiedHeapContents = new uint40[](maxHeapIndexCount);

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

    function _sink(PriorityQueue storage self, uint256 heapIndex) private {
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
        uint40[] memory originalHeapContents = new uint40[](maxHeapIndexCount);
        uint40[] memory modifiedHeapContents = new uint40[](maxHeapIndexCount);

        {
            uint256 i = heapIndex;
            uint256 j;

            heapIndexes[j] = i;
            modifiedHeapContents[j] = self._heap[i]; // SLOAD here
            originalHeapContents[j] = modifiedHeapContents[j];

            while (i << 1 <= heapSize) {
                uint256 k = i << 1;
                uint40 heap_k = self._heap[k]; // SLOAD 1
                
                // If right child exists
                if (k < heapSize) {
                    uint40 heap_kPlus1 = self._heap[k + 1]; // SLOAD 2
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

    function _compare(uint40 a, uint40 b) private pure returns (bool) {
        if (a < b) return true;
        else return false;
    }
}