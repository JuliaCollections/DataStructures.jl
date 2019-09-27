using Pkg
tempdir = mktempdir()
Pkg.activate(tempdir)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.add(["BenchmarkTools", "PkgBenchmark", "Random"])
Pkg.resolve()

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

const SUITE = BenchmarkGroup()

SUITE["heap"] = BenchmarkGroup(["binaryheap"])
SUITE[["heap","basic", "min", "push"]] =
    @benchmarkable push_heap(h, $xs) setup=(h=BinaryMinHeap{Float64}())
SUITE[["heap","basic", "min", "pop"]] =
    @benchmarkable pop_heap(h) setup=(h=BinaryMinHeap{Float64}($xs))
SUITE[["heap","mutable", "min", "push"]] =
    @benchmarkable push_heap(h, $xs) setup=(h=MutableBinaryMinHeap{Float64}())
SUITE[["heap","mutable", "min", "pop"]] =
    @benchmarkable pop_heap(h) setup=(h=MutableBinaryMinHeap{Float64}($xs))
