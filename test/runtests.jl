tests = ["deque", 
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
		 "list"]

for t in tests
	fp = joinpath(Pkg.dir("DataStructures"), "test", "test_$t.jl")
	println("$fp ...")
	include(fp)
end

