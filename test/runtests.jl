using DataStructures
using Test
using Random
using Serialization

import DataStructures: IntSet

@test isempty(detect_ambiguities(Base, Core, DataStructures))

tests = ["int_set",
         "deque",
         "circ_deque",
         "sorted_containers",
         "stack",
         "queue",
         "accumulator",
         "classified_collections",
         "disjoint_set",
         "binheap",
         "mutable_binheap",
         "minmax_heap",
         "default_dict",
         "trie",
         "list",
         "multi_dict",
         "circular_buffer",
         "sorting",
         "priority_queue"
        ]

if length(ARGS) > 0
    tests = ARGS
end

@testset "DataStructures" begin

for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    println("$fp ...")
    include(fp)
end

end # @testset
