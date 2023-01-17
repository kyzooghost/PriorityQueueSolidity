// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

library MinimumPriorityQueue {
    error EmptyPriorityQueue();
    error CannotInsert0();
    error NotInitialized();
    error AlreadyInitialized();

    struct Queue {
        uint256[] _heap;
    }

    // External view functions
    function size(Queue storage self) internal view returns (uint256) {
        return _size(self);
    }

    function heap(Queue storage self) internal view returns (uint256[] memory) {
        return self._heap;
    }    

    function isEmpty(Queue storage self) internal view returns (bool) {
        return _isEmpty(self);
    }

    function minimum(Queue storage self) internal view returns (uint256) {
        if (_isEmpty(self)) revert EmptyPriorityQueue();
        return self._heap[1];
    }

    // External mutator functions
    function insert(Queue storage self, uint256 _key) internal {
        _checkInitialize(self);
        if (_key == 0) revert CannotInsert0();
        self._heap.push(_key);
        _swim(self, _size(self));
    }

    function deleteMinimum(Queue storage self) internal returns(uint256 min) {
        if (_isEmpty(self)) revert EmptyPriorityQueue();
        // Is this copy by value into memory, or by reference from storage
        min = self._heap[1];
        self._heap[1] = self._heap[_size(self)];
        self._heap.pop();
        if (_isEmpty(self)) return min;
        _sink(self, 1);
    }

    // Internal view functions

    function _isEmpty(Queue storage self) internal view returns (bool) {
        return _size(self) == 0;
    }

    function _size(Queue storage self) internal view returns (uint256) {
        uint256 length = self._heap.length;
        if (length == 0) return 0;
        else return self._heap.length - 1;
    }

    function _compare(uint256 a, uint256 b) internal pure returns (bool) {
        if (a < b) return true;
        else return false;
    }

    function _swim(Queue storage self, uint256 heapIndex) internal {
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
        for (uint256 i = 0; i < maxHeapIndexCount; i++) {
            if (originalHeapContents[i] != modifiedHeapContents[i]) {
                self._heap[heapIndexes[i]] = modifiedHeapContents[i]; // SSTORE here
            }
        }
    }

    function _sink(Queue storage self, uint256 heapIndex) internal {
        // Obtain max # of heap indexes we will interact with in _swim operation
        uint256 maxHeapIndexCount = 1;
        uint256 heapSize = _size(self); // Save _size to memory, to minimize SLOAD for _size

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
        for (uint256 i = 0; i < maxHeapIndexCount; i++) {
            if (originalHeapContents[i] != modifiedHeapContents[i]) {
                self._heap[heapIndexes[i]] = modifiedHeapContents[i]; // SSTORE here
            }
        }
    }

    function _checkInitialize(Queue storage self) internal {
        if (self._heap.length == 0) {
            self._heap.push(0);
        }
    }

}