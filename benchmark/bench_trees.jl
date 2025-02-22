module BenchTrees

using DataStructures
using BenchmarkTools
using Random

suite = BenchmarkGroup()

rand_setup =  (
	Random.seed!(1234);
	idx1 = rand(1:30000, 1000);
	didx1 = rand(1:1000, 500);
)

# insert a bunch of keys, search for all of them, delete half of them randomly,
# then search for all of them again.
function test_rand(T)
    t = T{Int}()
    for i in idx1
        push!(t, i)
    end
    for i in idx1
        haskey(t, i)
    end
    for i in didx1
        delete!(t, idx1[i])
    end
    for i in idx1
        haskey(t, i)
    end
end

# insert 1, ..., N, then push 1 many times. tests a regression from an older
# splay tree implementation where splays didn't happen on redundant pushes.
function test_redundant(T, N=100000)
    t = T{Int}()
    for i in 1:N
        push!(t, i)
    end
    for i in 1:N
        push!(t, 1)
    end
end

# insert 1, ..., N, then access element 1 for N iterations. splay trees should
# perform best here.
function test_biased(T, N=100000)
    t = T{Int}()
    for i in 1:N
        push!(t, i)
    end
    for _ in 1:N
        haskey(t, 1)
    end
end

trees = Dict("splay" => SplayTree, "avl" => AVLTree, "rb" => RBTree)
for (T_name, T) in trees
    suite[T_name]["rand"] =
        @benchmarkable test_rand($(T)) setup=rand_setup
    suite[T_name]["redundant"] =
        @benchmarkable test_redundant($(T))
    suite[T_name]["biased"] =
        @benchmarkable test_biased($T)
end

end  # module

BenchTrees.suite
