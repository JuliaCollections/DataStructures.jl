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

SUITE["SparseIntSet"] = BenchmarkGroup()

rand_setup =  (
	Random.seed!(1234);
	ids1 = rand(1:30000, 1000);
	ids2 = rand(1:30000, 1000);
)

function create_fill_packed(ids1)
	y = SparseIntSet()
	for i in ids1
		push!(y, i)
	end
end

SUITE["SparseIntSet"]["create_fill"] =
	@benchmarkable create_fill_packed(ids1) setup=rand_setup

SUITE["SparseIntSet"]["in while not in"] =
	@benchmarkable in(23, y) evals=1000 setup=(y = SparseIntSet();)
SUITE["SparseIntSet"]["in while in"] =
	@benchmarkable in(5199, y) evals=1000 setup=(y=SparseIntSet(); push!(y, 5199))

function pop_push(y)
	pop!(y, 5199)
	push!(y, 5199)
end

SUITE["SparseIntSet"]["pop push worst case"] = @benchmarkable pop_push(y) setup=(y=SparseIntSet(); push!(y, 5199))
SUITE["SparseIntSet"]["pop push"] = @benchmarkable pop_push(y) setup=(y=SparseIntSet(); push!(y, 5199); push!(y, 5200))

function iterate_one_bench(x)
	t = 0
	for i in x
		t += i
	end
	return t
end
function iterate_two_bench(x,y)
	t = 0
	for (ix, iy) in zip(x, y)
		t += ix + iy
	end
	return t
end
function iterate_two_exclude_one_bench(x,y,z)
	t = 0
	for (ix, iy) in zip(x, y, exclude=(z,))
		t += ix + iy
	end
	return t
end

x_y_z_setup = (
	Random.seed!(1234);
	x = SparseIntSet(rand(1:30000, 1000));
	y = SparseIntSet(rand(1:30000, 1000));
	z = SparseIntSet(rand(1:30000, 1000));
)

SUITE["SparseIntSet"]["iterate one"] =
	@benchmarkable iterate_one_bench(x) setup=x_y_z_setup

SUITE["SparseIntSet"]["iterate two"] =
	@benchmarkable iterate_two_bench(x,y) setup=x_y_z_setup

SUITE["SparseIntSet"]["iterate two exclude one"] =
	@benchmarkable iterate_two_exclude_one_bench(x,y,z) setup=x_y_z_setup
