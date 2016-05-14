# Benchmark on heaps

using DataStructures

# benchmark function

function benchmark_heap(title::String, h::AbstractHeap, xs::Vector{Float64})
    @assert isempty(h)

    # warming
    push!(h, 0.5)
    pop!(h)

    # bench
    n = length(xs)

    t1 = @elapsed for i = 1 : n
        push!(h, xs[i])
    end
    t2 = @elapsed for i = 1 : n
        pop!(h)
    end

    @printf("   On %-24s:  push.elapsed = %7.4fs  pop.elapsed = %7.4fs\n", title, t1, t2)
end


# Benchmark on push! and pop!

xs = rand(10^6)

h_bin  = binary_minheap(Float64)
h_mbin = mutable_binary_minheap(Float64)

benchmark_heap("BinaryHeap", h_bin, xs)
benchmark_heap("MutableBinaryHeap", h_mbin, xs)
