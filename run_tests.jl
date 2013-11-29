tests = ["deque", 
		 "stack_and_queue", 
		 "accumulator",
		 "disjoint_set", 
		 "binheap", 
		 "mutable_binheap",
		 "defaultdict"]

for t in tests
	fp = joinpath("test", "test_$t.jl")
	println("$fp ...")
	include(fp)
end

