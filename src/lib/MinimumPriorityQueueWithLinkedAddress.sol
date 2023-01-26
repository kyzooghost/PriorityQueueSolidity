// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

library MinimumPriorityQueueWithLinkedAddress {
    error EmptyPriorityQueue();
    error CannotInsert0();

    struct PriorityQueue {
        uint256 _size;
        mapping(uint256 => uint256) _heap;
        mapping(uint256 => address) _linked_address;
    }

    // External view functions
    function size(PriorityQueue storage self) internal view returns (uint256) {
        return self._size;
    }

    function heap(PriorityQueue storage self) internal view returns (uint256[] memory) {
        uint256 currentSize = size(self);
        uint256[] memory heapIndexes = new uint[](currentSize);
        for (uint256 i; i < currentSize;) {
            heapIndexes[i] = self._heap[i + 1];
            unchecked{++i;}
        }
        return heapIndexes;
    }

    function addresses(PriorityQueue storage self) internal view returns (address[] memory) {
        uint256 currentSize = size(self);
        address[] memory addresses_array = new address[](currentSize);
        for (uint256 i; i < currentSize;) {
            uint256 heapIndex = self._heap[i + 1];
            addresses_array[i] = self._linked_address[heapIndex];
            unchecked{++i;}
        }
        return addresses_array;
    }

    function isEmpty(PriorityQueue storage self) internal view returns (bool) {
        return self._size == 0;
    }

    function minimum(PriorityQueue storage self) internal view returns (uint256, address) {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        uint256 min_key = self._heap[1];
        return (min_key, self._linked_address[min_key]);
    }

    // External mutator functions
    function insert(PriorityQueue storage self, uint256 _key, address _address) internal {
        if (_key == 0) revert CannotInsert0();
        uint256 newSize = ++self._size;
        self._heap[newSize] = _key;
        _swim(self, newSize);
        self._linked_address[_key] = _address;
    }

    function deleteMinimum(PriorityQueue storage self) internal returns(uint256 min) {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        min = self._heap[1];
        unchecked{--self._size;}
        uint256 newSize = self._size;
        self._heap[1] = self._heap[newSize + 1];
        self._heap[newSize + 1] = 0;
        delete self._linked_address[min];
        if (newSize == 0) return min;
        _sink(self, 1);
    }

    // Deletes key from _address_of mapping, BUT not the heap => This leaves a 'phantom' key in the heap with no linked address.
    // We do not delete key from the heap here because it requires finding the key in the heap, and we do not want to perform an O(N lg N) sort and search procedure in Solidity to find the key.
    // Return true if deleted a key, return false if did not delete anything.
    function deleteKey(PriorityQueue storage self, uint256 _key) internal returns (bool result) {
        address linked_address_to_delete = self._linked_address[_key];
        delete self._linked_address[_key];
        return linked_address_to_delete != address(0);
    }

    // Because deleteKey() exists, minimum() can potentially return a phantom key and zero address. To return a non-phantom key with a real linked address, we must deleteMinimum() for any phantom key we find
    function ensureNonPhantomMinimum(PriorityQueue storage self) internal {
        if (isEmpty(self)) revert EmptyPriorityQueue();
        uint256 min = self._heap[1];
        address min_address = self._linked_address[min];
        while (min_address == address(0)) {
            deleteMinimum(self);
            if (self._size == 0) return;
            min = self._heap[1];
            min_address = self._linked_address[min];
        }
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

    function _compare(uint256 a, uint256 b) private pure returns (bool) {
        if (a < b) return true;
        else return false;
    }
}