module VectorPartitions
using StaticArrays

export all_vector_partitions, increment_vector_partition_state!

struct VectorPartition
  n_elements::Int
  n_partitions::Int
end

# A partition of {1,...,n} into k subsets is equivalent to a function 
# f: {1,...,n} -> {1,...,k} such that
# g(i) = max_{j <= i} f(j) is surjective.
# So we can generate partitions by generating all such functions f. 
# here partition is f, upper_bound is g, and first_index keeps track of the points at which g changes value (which helps enforce surjectivity)
mutable struct VectorPartitionState{n,k}
  upper_bound::MVector{n,Int}
  partition::MVector{n,Int}
  first_index::MVector{k,Int}
  done::Bool
end

"""
    all_vector_partitions(n,k)

Create an iterator that produces all partitions of the set {1,...,`n`} into `k` nonempty subsets.

Partitions are represented as vectors of length `n` with values between 1 and `k`.
"""
function all_vector_partitions(n,k)
  if n <= 0 
    throw(DomainError(n, "Number of elements in the set must be positive."))
  end
  if k <= 0 
    throw(DomainError(k, "Number of sets in partition must be positive.")) 
  end 
  if n < k
    throw(DomainError((n,k),"Cannot produce partitions with more elements than the underlying set."))
  end
  return VectorPartition(n,k)
end

"""
    all_vector_partitions(n)

Create an iterator that produces all partitions of the set {1,...,'n'} into any number of nonempty subsets.

Partitions into k subsets are represented as vectors of length `n` with values between 1 and k.
"""
all_vector_partitions(n) = Iterators.flatten((all_vector_partitions(n,k) for k in 1:n))

function Base.iterate(I::VectorPartition)
  state = initial_vector_partition_state(I)
  return state.partition, state
end

function Base.iterate(I::VectorPartition,state)
  next_state = next_vector_partition_state(I,state)
  if next_state.done 
    return nothing
  end 
  return next_state.partition, next_state
end

function initial_vector_partition_state(I::VectorPartition)
  upper_bound = cat(ones(Int, I.n_elements-I.n_partitions),collect(1:I.n_partitions),dims=1)
  first_index = cat(1, (I.n_elements-Int64(I.n_partitions)) .+ collect(2:I.n_partitions),dims=1)
  state = VectorPartitionState{I.n_elements,I.n_partitions}(MVector(upper_bound...),MVector(copy(upper_bound)...),MVector(first_index...),false)
  return state
end

# because it is not recommended to have iterators mutate their state directly,
# this function copies before incrementing.
function next_vector_partition_state(I::VectorPartition,state)
  if state.done
    return state
  end
  state_c = VectorPartitionState{I.n_elements,I.n_partitions}(state.upper_bound,state.partition,state.first_index,false) 
  increment_vector_partition_state!(I,state_c)
  return state_c
end

"""
    increment_vector_partition_state!(I,state)

Update the state of a VectorPartition iterator. 
Useful to avoid copying the state unnecessarily at the cost of destructive mutations. 
This can result in significant speedups when you only need to look at each partition once. 

# Examples
```julia
iter = all_vector_partitions(5,3)
_, state = iterate(iter)
while !state.done
  do_stuff(state.partition)
  increment_vector_partition_state!(iter,state)
end
```
"""
function increment_vector_partition_state!(I::VectorPartition,state)
  # increment the sequence subject to upper bound and carry
  if state.done
    return
  end
  @inbounds begin
  state.partition[2] += 1
  for i in 2:I.n_elements-1
    if state.partition[i] > state.upper_bound[i]
      if state.upper_bound[i] > state.upper_bound[i-1]
        state.partition[i] = state.upper_bound[i]
      else
        state.partition[i] = 1
      end
      state.partition[i+1] += 1
    end
  end
  end

  # overflow condition: need to change the upper bound
  @inbounds if state.partition[I.n_elements] > state.upper_bound[I.n_elements]
    stop = increment_surjective_monotone_sequence!(state.upper_bound,I.n_partitions,state.first_index)
    if stop
      state.done = true 
    else
      # first partition for the new upper bound set
      state.partition[:] .= 1
      state.partition[state.first_index] = 1:I.n_partitions
    end
  end
end

function increment_surjective_monotone_sequence!(seq,maxval,step_locations)
  stop = true
  #update location of the increments 
  @inbounds begin
  for i in 2:length(step_locations)
    if step_locations[i] > step_locations[i-1] + 1
      step_locations[i] -= 1
      k = 1
      for j in i-1:-1:2
        step_locations[j] = step_locations[i] - k
        k += 1
      end
      stop = false
      break
    end
  end
  for i in 1:length(step_locations)-1
    seq[step_locations[i]:step_locations[i+1]-1] .= i
  end
  seq[step_locations[end]:end] .= maxval
  end
  return stop
end

end
