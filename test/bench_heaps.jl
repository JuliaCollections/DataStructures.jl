# Benchmark on heaps

using DataStructures

# benchmark function

function benchmark_heap(title::ASCIIString, h::AbstractHeap, xs::Vector{Float64})
    @assert isempty(h)
    
    # warming
    add!(h, 0.5)
    pop!(h)
    
    # bench
    n = length(xs)
    
    tic()
    for i = 1 : n
        add!(h, xs[i])
    end
    for i = 1 : n
        pop!(h)
    end
    et = toc()
    
    @printf("   On %16s:  elapsed = %8.4fs\n", title, et)
end


# Benchmark on add! and pop!

xs = rand(10^6)

h_bin = binary_minheap(Float64)
benchmark_heap("BinaryHeap", h_bin, xs)
