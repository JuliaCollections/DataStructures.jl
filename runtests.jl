tests = ["deque", 
         "sorteddict",
		 "stack_and_queue", 
		 "accumulator",
		 "classifiedcollections",
		 "disjoint_set", 
		 "binheap", 
		 "mutable_binheap",
		 "trie",
		 "list"]

for t in tests
	fp = joinpath("test", "test_$t.jl")
	println("$fp ...")
	include(fp)
end

