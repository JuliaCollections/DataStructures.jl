module BenchHeap

using DataStructures
using BenchmarkTools
using Random

function push_heap(h::AbstractHeap, xs::Vector)
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

suite = BenchmarkGroup()

heaptypes = [BinaryHeap, MutableBinaryHeap]
aexps = [1,3]
datatypes = [Int, Float64]
baseorderings = Dict(
    "Min" => Base.ForwardOrdering,
    #"Max" => Base.ReverseOrdering,
    )
fastfloatorderings = Dict(
    "Min" => DataStructures.FasterForward,
    "Max" => DataStructures.FasterReverse,
    )

for heap in heaptypes
    for aexp in aexps
        for dt in datatypes
            Random.seed!(0)
            a = rand(dt, 10^aexp)

            # Dict types to force use of abstract type if containing single value
            orderings = Dict{String, DataType}(baseorderings)
            if dt == Float64
                # swap to faster ordering operation
                for (k,v) in orderings
                    if haskey(fastfloatorderings, k)
                        orderings["Slow"*k] = v
                        orderings[k] = fastfloatorderings[k]
                    end
                end
            end

            for (ord_str, ord) in orderings
                prepath = [string(heap)]
                postpath = [string(dt), "10^"*string(aexp), ord_str]
                suite[vcat(prepath, ["make"], postpath)] =
                    @benchmarkable $(heap){$dt,$ord}($a)
                suite[vcat(prepath, ["push"], postpath)] =
                    @benchmarkable push_heap(h, $a) setup=(h=$(heap){$dt,$ord}())
                suite[vcat(prepath, ["pop"], postpath)] =
                    @benchmarkable pop_heap(h) setup=(h=$(heap){$dt,$ord}($a))
            end
        end
    end
end

fast_extreme_orderings = Dict(
    nsmallest => DataStructures.FasterForward(),
    nlargest => DataStructures.FasterReverse(),
    )

for func in [nlargest, nsmallest]
    fastord = fast_extreme_orderings[func]
    for aexp in [4]
        Random.seed!(0);
        a = rand(10^aexp);
        for nexp in [2]
            n = 10^nexp
            suite[["Slow " * string(func), "a=rand(10^"*string(aexp)*")", "n=10^"*string(nexp)]] =
                @benchmarkable $(func)($n, $a)
            suite[[string(func), "a=rand(10^"*string(aexp)*")", "n=10^"*string(nexp)]] =
                @benchmarkable DataStructures.nextreme($fastord, $n, $a)
        end
    end
end

end  # module

BenchHeap.suite
