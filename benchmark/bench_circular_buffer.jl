module BenchCircularBuffer

using DataStructures
using BenchmarkTools
using Random

const SUITE = BenchmarkGroup()
const CAPS = [1024, 1024^2]

# Empirically, 1 second is sufficient for consistent timings here.
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1

function init_cb(a)
    len = length(a)
    cb = CircularBuffer{Int}(len)
    cb.first = 1 + div(len, 2)
    return append!(cb, a)
end

function perf_chained_getindex(cb)
    i = 1
    for k = 1:capacity(cb)
        i = cb[i]
    end
    return i
end

function perf_first(cb)
    total = 0
    for i = 1:capacity(cb)
        cb.first = i
        total += first(cb)
    end
    return total
end

function perf_last(cb)
    total = 0
    for i = 1:capacity(cb)
        cb.first = i
        total += last(cb)
    end
    return total
end

g = addgroup!(SUITE, "access")

# Creating a new copy for each sample seems to eliminate an unknown but substantial source
# of timing variation on some machines. This is why each benchmark has `setup=(cb = deepcopy($cb))`.
for cap in CAPS
    Random.seed!(0)
    cb = init_cb(randcycle(cap))

    g["chained_getindex", cap] = @benchmarkable perf_chained_getindex(cb) setup=(cb = deepcopy($cb))

    g["sum", cap] = @benchmarkable sum(cb) setup=(cb = deepcopy($cb))
    g["foldl", cap] = @benchmarkable foldl(+, cb) setup=(cb = deepcopy($cb))
    g["foldr", cap] = @benchmarkable foldr(+, cb) setup=(cb = deepcopy($cb))

    g["first", cap] = @benchmarkable perf_first(cb) setup=(cb = deepcopy($cb))
    g["last", cap] = @benchmarkable perf_last(cb) setup=(cb = deepcopy($cb); cb.length = div($cap, 2))

    g["convert", cap] = @benchmarkable convert(Array, cb) setup=(cb = deepcopy($cb))
end

function perf_setindex!(cb, indices)
    for i in indices
        cb[i] = i
    end
    return cb
end

function perf_push!(cb)
    for i = 1:capacity(cb)
        push!(cb, i)
    end
    return cb
end

function perf_pushfirst!(cb)
    for i = 1:capacity(cb)
        pushfirst!(cb, i)
    end
    return cb
end

g = addgroup!(SUITE, "mutate")

for cap in CAPS
    cb = init_cb(-1:-1:-cap)

    Random.seed!(0)
    g["random_setindex!", cap] = @benchmarkable perf_setindex!(cb, $(randperm(cap))) setup=(cb = deepcopy($cb))
    g["forward_setindex!", cap] = @benchmarkable perf_setindex!(cb, 1:$cap) setup=(cb = deepcopy($cb))
    g["reverse_setindex!", cap] = @benchmarkable perf_setindex!(cb, $cap:-1:1) setup=(cb = deepcopy($cb))

    g["full_push!", cap] = @benchmarkable perf_push!(cb) setup=(cb = deepcopy($cb))
    g["full_pushfirst!", cap] = @benchmarkable perf_pushfirst!(cb) setup=(cb = deepcopy($cb))
end

perf_empty_push!(cb) = (empty!(cb); perf_push!(cb))
perf_empty_pushfirst!(cb) = (empty!(cb); perf_pushfirst!(cb))

function perf_pop!(cb)
    cap = capacity(cb)
    cb.length = cap
    total = 0
    for i = 1:cap
        total += pop!(cb)
    end
    return total
end

function perf_popfirst!(cb)
    cap = capacity(cb)
    cb.length = cap
    total = 0
    for i = 1:cap
        total += popfirst!(cb)
    end
    return total
end

perf_fill!(cb) = (empty!(cb); fill!(cb, 1))

for cap in CAPS
    cb = init_cb(-1:-1:-cap)
    g["empty_push!", cap] = @benchmarkable perf_empty_push!(cb) setup=(cb = deepcopy($cb))
    g["empty_pushfirst!", cap] = @benchmarkable perf_empty_pushfirst!(cb) setup=(cb = deepcopy($cb))
    g["pop!", cap] = @benchmarkable perf_pop!(cb) setup=(cb = deepcopy($cb))
    g["popfirst!", cap] = @benchmarkable perf_popfirst!(cb) setup=(cb = deepcopy($cb))
    g["fill!", cap] = @benchmarkable perf_fill!(cb) setup=(cb = deepcopy($cb))
end

end  # module BenchCircularBuffer

if @isdefined(SUITE)
    BenchCircularBuffer.SUITE
else
    # This `else` branch allows this file to be called directly by PkgBenchmark via the
    # `script` keyword in `PkgBenchmark.benchmarkpkg`.
    using BenchmarkTools
    const SUITE = BenchmarkGroup()
    SUITE["CircularBuffer"] = BenchCircularBuffer.SUITE
end
