using Pkg
tempdir = mktempdir()
Pkg.activate(tempdir)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.add(["BenchmarkTools", "PkgBenchmark", "Random"])
Pkg.resolve()

using DataStructures
using BenchmarkTools

const SUITE = BenchmarkGroup()

SUITE["heap"] = include("bench_heap.jl")
SUITE["SparseIntSet"] = include("bench_sparse_int_set.jl")
