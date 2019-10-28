# A Classified Collection is a map which associates a collection to each key
#
# The collection can be either an array or a set, a counter, or other data structures
# that support the push! method
#

mutable struct ClassifiedCollections{K, Collection}
    map::Dict{K, Collection}

    function ClassifiedCollections{K, Collection}(map) where {K, Collection}
        @warn "ClassifiedCollections will be removed from DataStructures.jl in v0.18."
        return new(map)
    end
end

## constructors

ClassifiedCollections(K::Type, C::Type) = ClassifiedCollections{K, C}(Dict{K,C}())

classified_lists(K::Type, V::Type) = ClassifiedCollections(K, Vector{V})
classified_sets(K::Type, V::Type) = ClassifiedCollections(K, Set{V})
classified_counters(K::Type, T::Type) = ClassifiedCollections(K, Accumulator{T, Int})

_create_empty(::Type{Vector{T}}) where {T} = Vector{T}()
_create_empty(::Type{Set{T}}) where {T} = Set{T}()
_create_empty(::Type{Accumulator{T,V}}) where {T,V} = Accumulator{T, V}()

copy(cc::ClassifiedCollections{K, C}) where {K, C} = ClassifiedCollections{K, C}(copy(cc.map))

length(cc::ClassifiedCollections) = length(cc.map)

## retrieval

getindex(cc::ClassifiedCollections{T,C}, x::T) where {T,C} = cc.map[x]

haskey(cc::ClassifiedCollections{T,C}, x::T) where {T,C} = haskey(cc.map, x)

keys(cc::ClassifiedCollections) = keys(cc.map)

## iteration

iterate(cc::ClassifiedCollections, s...) = iterate(cc.map, s...)

# manipulation

function push!(cc::ClassifiedCollections{K, C}, key::K, e) where {K, C}
    c = get(cc.map, key, nothing)
    if c === nothing
        c = _create_empty(C)
        cc.map[key] = c
    end
    push!(c, e)
end

pop!(cc::ClassifiedCollections{K}, key::K) where {K} = pop!(cc.map, key)
