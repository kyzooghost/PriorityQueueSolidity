// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

library PriorityQueue {
    error EmptyPriorityQueue();
    error CannotInsert0();
    error NotInitialized();
    error AlreadyInitialized();

    enum Orientation {
        Minimum,
        Maximum
    }

    struct Queue {
        Orientation _orientation;
        uint256[] _heap;
    }

    function initialize(Queue storage self, Orientation orientation_) external {
        if (_isInitialized(self) == true) {
            revert AlreadyInitialized();
        }

        self._heap.push(0);
        self._orientation = orientation_;
    }

    // External view functions
    function size(Queue storage self) external view returns (uint256) {
        _initializedCheck(self);
        return _size(self);
    }

    function heap(Queue storage self) external view returns (uint256[] memory) {
        _initializedCheck(self);
        return self._heap;
    }    

    function isEmpty(Queue storage self) external view returns (bool) {
        _initializedCheck(self);
        return _isEmpty(self);
    }

    function minimum(Queue storage self) external view returns (uint256) {
        _initializedCheck(self);
        if (_isEmpty(self)) revert EmptyPriorityQueue();
        return self._heap[1];
    }

    function orientation(Queue storage self) external view returns (Orientation) {
        _initializedCheck(self);
        return self._orientation;
    }

    // External mutator functions
    function insert(Queue storage self, uint256 _key) external {
        _initializedCheck(self);
        if (_key == 0) revert CannotInsert0();
        self._heap.push(_key);
        _swim(self, _size(self));
    }

    function deleteMinimum(Queue storage self) external returns(uint256 min) {
        _initializedCheck(self);
        if (_isEmpty(self)) revert EmptyPriorityQueue();
        // Is this copy by value into memory, or by reference from storage
        min = self._heap[1];
        self._heap[1] = self._heap[_size(self)];
        self._heap.pop();
        if (_isEmpty(self)) return min;
        _sink(self, 1);
    }

    // Internal view functions

    function _isInitialized(Queue storage self) internal view returns (bool) {
        return self._heap.length > 0;
    }

    function _isEmpty(Queue storage self) internal view returns (bool) {
        return _size(self) == 0;
    }

    function _size(Queue storage self) internal view returns (uint256) {
        return self._heap.length - 1;
    }

    function _compare(Queue storage self, uint256 a, uint256 b) internal view returns (bool) {
        if (self._orientation == Orientation.Minimum) {
            if (a < b) return true;
            else return false;
        } else {
            if (a > b) return true;
            else return false;
        }
    }

    // Internal functions

    function _initializedCheck(Queue storage self) internal view {
        if (_isInitialized(self) == false) {
            revert NotInitialized();
        }
    }

    function _swim(Queue storage self, uint256 heapIndex) internal {
        // Perform operations in memory (cheaper) before saving result in storage. Perform minimum operations in storage.

        // Obtain max # of heap indexes we will interact with in _swim operation
        uint256 maxHeapIndexCount = 1;
        {
            uint256 i = heapIndex;
            while (i > 1) {
                maxHeapIndexCount += 1;
                i >>= 1; // Bitwise operation for /= 2
            }
        }
        // Obtain relevant heap indexes
        uint256[] memory heapIndexes = new uint[](maxHeapIndexCount);
        uint256[] memory originalHeapContents = new uint[](maxHeapIndexCount);
        uint256[] memory modifiedHeapContents = new uint[](maxHeapIndexCount);

        // console.log("%s %i", "maxHeapIndexCount: ", maxHeapIndexCount);
        // console.log();
        {
            uint256 i = heapIndex;
            uint256 j;
            while (i >= 1) {
                heapIndexes[j] = i;
                // console.log("%s %i %s", "heapIndexes[", j, "]");
                // console.log("%s %i", "=", i);
                // console.log();
                modifiedHeapContents[j] = self._heap[i]; // SLOAD here
                originalHeapContents[j] = modifiedHeapContents[j];
                // console.log("%s %i %s", "modifiedHeapContents, originalHeapContents[", j, "]");
                // console.log("%s %i", "=", modifiedHeapContents[j]);
                // console.log();
                i >>= 1; // Bitwise operation for /= 2
                j += 1;
            }
        }
        // Perform swim on modifiedHeapContents
        {
            uint256 j;
            while (j + 1 < maxHeapIndexCount && _compare(self, modifiedHeapContents[j + 1], modifiedHeapContents[j]) == false) {
                // Does this work to swap the in-memory array indexes?
                (modifiedHeapContents[j + 1], modifiedHeapContents[j]) = (modifiedHeapContents[j], modifiedHeapContents[j + 1]);

                // console.log("%s %i %s", "modifiedHeapContents[", j, "]");
                // console.log("%s %i", "=", modifiedHeapContents[j]);
                // console.log();
                // console.log("%s %i %s", "modifiedHeapContents[", j + 1, "]");
                // console.log("%s %i", "=", modifiedHeapContents[j + 1]);
                // console.log();

                j++;
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
                maxHeapIndexCount += 1;
                i <<= 1;
            }
        }

        // console.log("%s %i", "sink maxHeapIndexCount: ", maxHeapIndexCount);
        // console.log();

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

            // console.log("%s %i %s", "heapIndexes[", j, "]");
            // console.log("%s %i", "=", i);
            // console.log();
            // console.log("%s %i %s", "modifiedHeapContents, originalHeapContents[", j, "]");
            // console.log("%s %i", "=", modifiedHeapContents[j]);
            // console.log();

            while (i << 1 <= heapSize) {
                uint256 k = i << 1;
                uint256 heap_k = self._heap[k]; // SLOAD 1
                
                // If right child exists
                if (k < heapSize) {
                    uint256 heap_kPlus1 = self._heap[k + 1]; // SLOAD 2
                    // If left child < right child, choose left child
                    if (_compare(self, heap_k, heap_kPlus1) == false) {
                        k++;
                        heap_k = heap_kPlus1;
                    }
                }

                // If current_node <= _child, no need to swim further.
                if (_compare(self, modifiedHeapContents[0], heap_k) == true) {
                    // console.log("%s", "BREAK");
                    // console.log("%s %i", "heap_k", heap_k);
                    break;
                }
    
                // Copy into memory arrays
                i = k;
                j += 1;
                heapIndexes[j] = i;
                modifiedHeapContents[j] = heap_k;
                originalHeapContents[j] = heap_k;

                // console.log("%s %i %s", "heapIndexes[", j, "]");
                // console.log("%s %i", "=", i);
                // console.log();
                // console.log("%s %i %s", "modifiedHeapContents, originalHeapContents[", j, "]");
                // console.log("%s %i", "=", modifiedHeapContents[j]);
                // console.log();
            }
        }

        // Perform sink on modifiedHeapContents
        {
            uint256 j;
            while (j + 1 < maxHeapIndexCount && modifiedHeapContents[j + 1] != 0 && _compare(self, modifiedHeapContents[j + 1], modifiedHeapContents[j]) == true) {
                // Does this work to swap the in-memory array indexes?
                (modifiedHeapContents[j + 1], modifiedHeapContents[j]) = (modifiedHeapContents[j], modifiedHeapContents[j + 1]);

                // console.log("%s %i %s", "modifiedHeapContents[", j, "]");
                // console.log("%s %i", "=", modifiedHeapContents[j]);
                // console.log();
                // console.log("%s %i %s", "modifiedHeapContents[", j + 1, "]");
                // console.log("%s %i", "=", modifiedHeapContents[j + 1]);
                // console.log();

                j++;
            }
        }

        // Copy in-memory modifiedHeapContents back into in-storage _heap. In theory we should be able to halve the number of SSTOREs with this _sink implementation.
        for (uint256 i = 0; i < maxHeapIndexCount; i++) {
            if (originalHeapContents[i] != modifiedHeapContents[i]) {
                self._heap[heapIndexes[i]] = modifiedHeapContents[i]; // SSTORE here
            }
        }
    }

}