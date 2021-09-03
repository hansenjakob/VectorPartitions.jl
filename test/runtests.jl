using VectorPartitions
using Test

@testset "VectorPartitions.jl" begin
using Combinatorics

function count_partition_iterator(n,k)
  P = all_vector_partitions(n,k)
  x = zeros(Int,n)
  count = 0
  for partition in P 
    x .= partition
    count += 1
  end
  return count
end

function count_partitions_raw(n,k)
  P = all_vector_partitions(n,k)
  x = zeros(Int,n)
  next = iterate(P)
  count = 0
  while next !== nothing
      (x, state) = next
      next = iterate(P, state)
      count += 1
  end
  return count
end

function count_partitions_stateful(n,k)
  P = all_vector_partitions(n,k)
  next = iterate(P)
  if next !== nothing
    (_,state) = next
  else
    return nothing
  end
  count = 0
  while !state.done
    increment_vector_partition_state!(P,state)
    count += 1
  end
  return count
end

@test count_partition_iterator(5,2) == stirlings2(5,2)
@test count_partitions_raw(5,2) == stirlings2(5,2)
@test count_partitions_stateful(5,2) == stirlings2(5,2)


end
