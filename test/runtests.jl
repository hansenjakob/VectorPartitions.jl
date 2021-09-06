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

# some spot checks that we get the right number of partitions
@test count_partition_iterator(5,2) == stirlings2(5,2)
@test count_partitions_raw(5,2) == stirlings2(5,2)
@test count_partitions_stateful(5,2) == stirlings2(5,2)

@test count_partition_iterator(5,3) == stirlings2(5,3)
@test count_partitions_raw(5,3) == stirlings2(5,3)
@test count_partitions_stateful(5,3) == stirlings2(5,3)

# do we produce the right list of partitions in this case?
three_two_partitions = [[1,1,2],[1,2,1],[1,2,2]]
for (p1, p2) in zip(all_vector_partitions(3,2),three_two_partitions)
  @test all(p1 .== p2)
end


# test increment_vector_partition_state!
I = all_vector_partitions(7,3)
_, state = iterate(I)
state.partition .= [1, 1, 2, 3, 3, 3, 3]
state.upper_bound .= [1, 1, 2, 3, 3, 3, 3] 
state.first_index .= [1, 3, 4]
increment_vector_partition_state!(I,state)
@test all(state.partition .== [1,2,1,3,1,1,1])
@test all(state.upper_bound .== [1,2,2,3,3,3,3])
@test all(state.first_index .== [1,2,4])

increment_vector_partition_state!(I,state)
@test all(state.partition .== [1,2,2,3,1,1,1])
@test all(state.upper_bound .== [1,2,2,3,3,3,3])
@test all(state.first_index .== [1,2,4])


# test increment_surjective_monotone_sequence!
seq = [1, 2, 2, 3, 4]
step_locations = [1,2,4,5]
stop = VectorPartitions.increment_surjective_monotone_sequence!(seq,4,step_locations)
@test all(seq .== [1, 2, 3, 3, 4])
@test all(step_locations .== [1,2,3,5])
@test stop == false

seq = [1,2,3,4,4]
step_locations = [1,2,3,4]
stop = VectorPartitions.increment_surjective_monotone_sequence!(seq,4,step_locations)
@test all(seq .== [1, 2, 3, 4, 4])
@test all(step_locations .== [1,2,3,4])
@test stop == true


end
