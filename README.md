# VectorPartitions

Combinatorics.jl provides an iterator to produce partitions of a given set, which it produces as an array of arrays. This is not a convenient format for some applications, and due to varying lengths of arrays involves a lot of memory allocation. Another possible representation for partitions of the set `{1,...,n}` is as a vector `p` of length `n`, with the partitioning sets being `P_j = {i : p[i] = j}`. This small package provides iterators for producing partitions in this format. It typically runs several times faster than the iterator from Combinatorics.jl. 

## Usage
```julia
for partition in all_vector_partitions(n,k)
  do_stuff(partition)
end
```

For convenience, `all_vector_partitions(n)` provides an iterator over partitions into any number of sets, beginning with the trivial partition into one set. This is produced by concatenating the iterators for fixed numbers of sets.

The Julia iterator interface often results in copying the output and intermediate state of the iterator at each step. For iterations over large sets of partitions where you do not need copies, it can be considerably more efficient to mutate the iterator state directly. The package exposes a function to enable this.

```julia
iter = all_vector_partitions(n,k)
_, state = iterate(iter)
while !state.done
  do_stuff(state.partition)
  increment_vector_partition_state!(iter,state)
end
```

It may also improve performance to use a for loop instead of a while loop. Since the number of partitions of an n-element set into k subsets is the Stirling number of the second kind, this can be written (using the Combinatorics.jl function `stirlings2`) as follows:
```julia
using Combinatorics
iter = all_vector_partitions(n,k)
_, state = iterate(iter)
for _ in 1:stirlings2(n,k)
  do_stuff(state.partition)
  increment_vector_partition_state!(iter,state)
end
```

