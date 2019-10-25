module BenchSparseIntSet

using DataStructures
using BenchmarkTools
using Random

suite = BenchmarkGroup()

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

suite["create_fill"] =
	@benchmarkable create_fill_packed(ids1) setup=rand_setup

suite["in while not in"] =
	@benchmarkable in(23, y) evals=1000 setup=(y = SparseIntSet();)
suite["in while in"] =
	@benchmarkable in(5199, y) evals=1000 setup=(y=SparseIntSet(); push!(y, 5199))

function pop_push(y)
	pop!(y, 5199)
	push!(y, 5199)
end

suite["pop push worst case"] = @benchmarkable pop_push(y) setup=(y=SparseIntSet(); push!(y, 5199))
suite["pop push"] = @benchmarkable pop_push(y) setup=(y=SparseIntSet(); push!(y, 5199); push!(y, 5200))

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

suite["iterate one"] =
	@benchmarkable iterate_one_bench(x) setup=x_y_z_setup

suite["iterate two"] =
	@benchmarkable iterate_two_bench(x,y) setup=x_y_z_setup

suite["iterate two exclude one"] =
	@benchmarkable iterate_two_exclude_one_bench(x,y,z) setup=x_y_z_setup

end  # module
BenchSparseIntSet.suite
