using DataStructures
using BenchmarkTools
using Random






#The two can be interspersed as you like, but these could be separate too.
rng = Random.MersenneTwister(182936851)
Trials_count = 10000000
Tree_size = 3000000
Seg_tree = SegmentTree(UInt64, Tree_size, +)

function fill_array!(rng, Trials_count, Seg_tree, Tree_size)
    for i in 1:Trials_count
        a = rand(rng,1:Tree_size)
        b = rand(rng,a:Tree_size)
        c = rand(rng, UInt64)
        set_range!(Seg_tree,a,b,c)
    end
end

function use_array(rng, Trials_count, Seg_tree, Tree_size)
    ans = UInt64(0)
    for i in 1:Trials_count
        a = rand(rng,1:Tree_size)
        b = rand(rng,a:Tree_size)
        ans += get_range(Seg_tree,a,b)
    end
    return ans
end

function fill_use_array!(rng, Trials_count, Seg_tree, Tree_size)
    ans = UInt64(0)
    for i in 1:Trials_count
        a = rand(rng,1:Tree_size)
        b = rand(rng,a:Tree_size)
        c = rand(rng, UInt64)
        set_range!(Seg_tree,a,b,c)
        d = rand(rng,1:Tree_size)
        e = rand(rng,a:Tree_size)
        ans += get_range(Seg_tree,d,e)
    end
    return ans
end

function bench_rng_time(rng, Tree_size)
    for i in 1:Trials_count
        a = rand(rng,1:Tree_size)
        b = rand(rng,a:Tree_size)
        c = rand(rng, UInt64)
    end
end

function bench_rng_time_2(rng, Tree_size)
    for i in 1:Trials_count
        a = rand(rng,1:Tree_size)
        b = rand(rng,a:Tree_size)
    end
end

function bench_rng_time_3(rng, Tree_size)
    for i in 1:Trials_count
        a = rand(rng,1:Tree_size)
        b = rand(rng,a:Tree_size)
        c = rand(rng, UInt64)
        #set_range!(Seg_tree,a,b,c)
        d = rand(rng,1:Tree_size)
        e = rand(rng,a:Tree_size)
    end
end

println("Filling array:")
@time fill_array!(rng, Trials_count, Seg_tree, Tree_size)
println("rng use time:")
@time bench_rng_time(rng,Tree_size)
println("Using array:")
@time a1 = use_array(rng, Trials_count, Seg_tree, Tree_size)
println("rng use time:")
@time bench_rng_time_2(rng,Tree_size)
println("Filling and using array:")
@time a2 = fill_use_array!(rng, Trials_count, Seg_tree, Tree_size)
println("rng use time:")
@time bench_rng_time_3(rng,Tree_size)

println("To ensure things are correct. ", a1, " ", a2)


#=
Bench times
My old c++ code.
Time to fill array: 19.5439
Time to use array: 14.9069
Rng_time_usage: 1.33407
Test passed

My New Julia code.

Filling array:
    42.910419 seconds (938.36 M allocations: 27.966 GiB, 10.03% gc time, 0.05% compilation time)
rng use time:
    0.889469 seconds (30.02 M allocations: 611.754 MiB, 7.59% gc time, 3.92% compilation time)
Using array:
    1.517290 seconds (28.90 k allocations: 1.763 MiB, 0.99% compilation time)
rng use time:
    0.828135 seconds (30.02 M allocations: 611.670 MiB, 7.77% gc time, 1.66% compilation time)
Filling and using array:
    45.114268 seconds (938.49 M allocations: 27.970 GiB, 9.70% gc time, 0.11% compilation time)
rng use time:
    1.060329 seconds (30.03 M allocations: 611.882 MiB, 6.14% gc time, 2.44% compilation time)
To ensure things are correct. 3311231602528483331 15847214091098195660


The old c++ code was about twice as fast playing with set_range!, but Julia's get_range is much faster.

My Julia code.


=#

