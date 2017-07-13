if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end
using DataStructures
const IntSet = DataStructures.IntSet
import Compat: String
using Primes

if VERSION >= v"0.5.0" && VERSION < v"0.6.0-dev"
    @test isempty(detect_ambiguities(Base, Core, DataStructures))
end

tests = ["int_set",
         "deque",
         "circ_deque",
         "sorted_containers",
         "stack_and_queue",
         "accumulator",
         "classified_collections",
         "disjoint_set",
         "binheap",
         "mutable_binheap",
         "default_dict",
         "ordered_dict",
         "ordered_set",
         "trie",
         "list",
         "multi_dict",
         "circular_buffer",
         "sorting",
         "priorityqueue"
        ]

if length(ARGS) > 0
    tests = ARGS
end

for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    println("$fp ...")
    include(fp)
end
