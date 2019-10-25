module BenchHeap

using DataStructures
using BenchmarkTools
using Random

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

Random.seed!(0)
xs = rand(10^6)

suite = BenchmarkGroup()

suite[["basic", "min", "push"]] =
    @benchmarkable push_heap(h, $xs) setup=(h=BinaryMinHeap{Float64}())
suite[["basic", "min", "pop"]] =
    @benchmarkable pop_heap(h) setup=(h=BinaryMinHeap{Float64}($xs))
suite[["mutable", "min", "push"]] =
    @benchmarkable push_heap(h, $xs) setup=(h=MutableBinaryMinHeap{Float64}())
suite[["mutable", "min", "pop"]] =
    @benchmarkable pop_heap(h) setup=(h=MutableBinaryMinHeap{Float64}($xs))

end  # module

BenchHeap.suite
