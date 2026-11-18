# Benchmark on disjoint set forests

using DataStructures, BenchmarkTools

# do 10^6 random unions over 10^6 element set

const n =  2 * (10^6)
const T0 = 10
const T = 10^6

function batch_union!(s::IntDisjointSet, x::Vector{Int}, y::Vector{Int})
    for i = 1 : length(x)
        @inbounds union!(s, x[i], y[i])
    end
end

s = IntDisjointSet(n)

# warming

x0 = rand(1:n, T0)
y0 = rand(1:n, T0)

batch_union!(s, x0, y0)

# measure

x = rand(1:n, T)
y = rand(1:n, T)

@time batch_union!(s, x, y)

#=
benchmark `find` operation
=#

function create_disjoint_set_struct(n::Int)
    parents = [1; collect(1:n-1)] # each element's parent is its predecessor
    ranks = zeros(Int, n) # ranks are all zero
    IntDisjointSet(parents, ranks, n)
end

# benchmarking function
function benchmark_find_root(n::Int)
    println("Benchmarking recursive path compression implementation (find_root_impl!):")
    if n >= 10^5
        println("Recursive may path compression may encounter stack-overflow; skipping")
    else
        s = create_disjoint_set_struct(n)
        @btime find_root!($s, $n, PCRecursive())
    end

    println("Benchmarking iterative path compression implementation (find_root_iterative!):")
    s = create_disjoint_set_struct(n) # reset parents
    @btime find_root!($s, $n, PCIterative())

    println("Benchmarking path-halving implementation (find_root_halving!):")
    s = create_disjoint_set_struct(n) # reset parents
    @btime find_root!($s, $n, PCHalving())

    println("Benchmarking path-splitting implementation (find_root_path_splitting!):")
    s = create_disjoint_set_struct(n) # reset parents
    @btime find_root!($s, $n, PCSplitting())
end

# run benchmark tests
benchmark_find_root(1_000)
benchmark_find_root(10_000)
benchmark_find_root(100_000)
benchmark_find_root(1_000_000)
benchmark_find_root(10_000_000)