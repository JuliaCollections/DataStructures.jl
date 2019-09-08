# Benchmark on heaps

using DataStructures
using BenchmarkTools

function push_heap(h::AbstractHeap, xs::Vector{Float64})
    n = length(xs)

    for i = 1 : n
        push!(h, xs[i])
    end
end

function pop_heap(h::AbstractHeap)
    n = length(h)

    for i = 1 : n
        pop!(h)
    end
end

xs = rand(10^6)

println("BinaryHeap Push: ",
    @belapsed push_heap(h, $xs) setup=(h=BinaryMinHeap{Float64}())
)
println("BinaryHeap Pop: ",
    @belapsed pop_heap(h) setup=(h=BinaryMinHeap{Float64}(); push_heap(h, $xs))
)
println("MutableBinaryHeap Push: ",
    @belapsed push_heap(h, $xs) setup=(h=MutableBinaryMinHeap{Float64}())
)
println("MutableBinaryHeap Pop: ",
    @belapsed pop_heap(h) setup=(h=MutableBinaryMinHeap{Float64}(); push_heap(h, $xs))
)
