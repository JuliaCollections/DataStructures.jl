using Base.Test
using DataStructures
const IntSet = DataStructures.IntSet

tests = ["intset",
         "deque",
         "sortedcontainers",
         "stack_and_queue",
         "accumulator",
         "classifiedcollections",
         "disjoint_set",
         "binheap",
         "mutable_binheap",
         "defaultdict",
         "ordereddict",
         "orderedset",
         "trie",
         "list",
         "multidict",
         "circularbuffer"]

if length(ARGS) > 0
    tests = ARGS
end

for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    println("$fp ...")
    include(fp)
end
