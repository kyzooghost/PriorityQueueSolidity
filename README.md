# Solidity implementation for priority queue data structure

## Deprecation Note

This was built in a time when the [OpenZeppelin Heap library](https://docs.openzeppelin.com/contracts/5.x/api/utils#Heap) was not available. Prefer using OpenZeppelin implementation for audited + maintained library.

## Rationale

Priority queue that supports O(lg N) `insert` and `deleteMinimum` \ `deleteMaximum` operations.

## Pre-requisites

 - [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Test

`forge test`

## Gas results for MinimumPriorityQueue and MaximumPriorityQueue libraries

Profiled with `forge test -vvvv`

| n (number of items in queue) | `insert` gas cost | `deleteMinimum`  \  `deleteMaximum` gas cost |
|------------------------------|-------------------|----------------------------------------------|
| 1                            | 26239             | 1208                                         |
| 10                           | 29769             | 6893                                         |
| 100                          | 35065             | 12829                                        |
| 1000                         | 40361             | 18784                                        |
| 10000                        | 47423             | 26677                                        |
| 100000                       | 52720             | 32614                                        |

## To-do

- Further gas optimization
- Audit

