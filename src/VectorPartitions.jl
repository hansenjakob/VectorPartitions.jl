module VectorPartitions
using StaticArrays

export VectorPartition, all_vector_partitions, increment_vector_partition_state!

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

#okay, apparently it is not recommended to have iterators actually mutate the
#state. so probably the way to go about this is to have two implementations, one
#mutational and one static

function initial_vector_partition_state(I::VectorPartition)
  upper_bound = cat(ones(Int, I.n_elements-I.n_partitions),collect(1:I.n_partitions),dims=1)
  first_index = cat(1, (I.n_elements-Int64(I.n_partitions)) .+ collect(2:I.n_partitions),dims=1)
  state = VectorPartitionState{I.n_elements,I.n_partitions}(MVector(upper_bound...),MVector(copy(upper_bound)...),MVector(first_index...),false)
  return state
end

function next_vector_partition_state(I::VectorPartition,state)
  if state.done
    return state
  end
  state_c = copy(state)
  increment_vector_partition_state!(I,state_c)
  return state_c
end

function increment_vector_partition_state!(I::VectorPartition,state)
  # increment the sequence subject to upper bound and carry
  if state.done
    return
  end
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

  # overflow condition: need to change the upper bound
  if state.partition[end] > state.upper_bound[end]
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

  return stop
end

end