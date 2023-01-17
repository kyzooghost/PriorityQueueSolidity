# Solidity implementation for priority queue data structure

## Rationale

Priority queue that supports O(lg N) `insert` and `deleteMinimum` \ `deleteMaximum` operations.

## Pre-requisites

 - [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Test

`forge test`

## Gas results

Profiled with `forge test -vvvv`

| n (number of items in queue) | `insert` gas cost | `deleteMinimum`  \  `deleteMaximum` gas cost |
|------------------------------|-------------------|----------------------------------------------|
| 1                            | 26165             | 2398                                         |
| 10                           | 29695             | 6893                                         |
| 100                          | 34991             | 12829                                        |
| 1000                         | 40287             | 18784                                        |
| 10000                        | 47349             | 26677                                        |
| 100000                       | 52646             | 32614                                        |

## To-do

- Further gas optimization
- Audit

