tests = ["deque",
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
         "multidict"]

for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    println("$fp ...")
    include(fp)
end
