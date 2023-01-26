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

## Gas results for MinimumPriorityQueue_Uint40 library

Profiled with `forge test -vvvv`

| n (number of items in queue) | `insert` gas cost | `deleteMinimum`  \  `deleteMaximum` gas cost |
|------------------------------|-------------------|----------------------------------------------|
| 1                            | 6019              | 2389                                         |
| 10                           | 10821             | 13395                                        |
| 100                          | 17825             | 23267                                        |
| 1000                         | 25229             | 33561                                        |
| 10000                        | 34535             | 46083                                        |
| 100000                       | 41540             | 56006                                        |

## Gas results for MinimumPriorityQueueWithLinkedAddress libraries

Profiled with `forge test -vvvv`

| n (number of items in queue) | `insert` gas cost | `deleteMinimum` gas cost |
|------------------------------|-------------------|--------------------------|
| 1                            | 48518             | 2691                     |
| 10                           | 52048             | 7498                     |
| 100                          | 57344             | 13434                    |
| 1000                         | 62640             | 19389                    |
| 10000                        | 69702             | 27282                    |
| 100000                       | 74999             | 32907                    |

We expect ~20000 increased gas cost for insert() operation due to one additional SSTORE - we store an address in MinimumPriorityQueueWithLinkedAddress.insert(), which we do not with MinimumPriorityQueue.insert()

## Gas results for MinimumPriorityQueue_Uint40 vs MinimumPriorityQueue library

Profiled with `forge test -vvvv`

| Number of items inserted and then deleted | MinimumPriorityQueue | MinimumPriorityQueue_Uint40 |
|-------------------------------------------|----------------------|-----------------------------|
| 1                                         | 38734                | 41068                       |
| 10                                        | 297504               | 218123                      |
| 100                                       | 3818971              | 3621187                     |
| 1000                                      | 48872660             | 54268334                    |
| 10000                                     | 603271512            | 736456181                   |
| 100000                                    | 7175282608           | 9291094734                  |


## Analysis of mapping(uint256 => uint256) vs dynamic uint40[] array implementation

**Observations:**

- Dynamic uint40[] array implementation has cheaper insert costs, but more expensive delete costs. 

- uint40[] has cheaper amortized operations for n <180, but has more expensive amortized operations for n > 180.

- Costs for uint40[] implementation grows more rapidly than for the mapping implementation


**Proposed explanations:**

- Cheaper inserts for uint40[] => Due to uint40 packing, only every 5-6 insertion operations requires a cold SSTORE operation (~20K gas cost)

- More expensive deletes for uint40[] and faster growth rate of costs => Unlike in insert, we do not avoid a cold SSTORE through uint40 packing in the delete operation. Furthermore the EVM operates with uint256 words and must cast/uncast to work with uint40 variables. The additional delete() cost can be explained by the additional cast/uncast operations.

## Caveats

`insert` when n = 0 involves ~20000 gas initialization cost due to SSTORE operation on a cold storage slot of value 0.