# A counter type

struct Accumulator{T, V<:Number} <: Associative{T,V}
    map::Dict{T,V}
end

## constructors

Accumulator(::Type{T}, ::Type{V}) where {T,V<:Number} = Accumulator{T,V}(Dict{T,V}())
counter(T::Type) = Accumulator(T,Int)

counter(dct::Dict{T,Int}) where {T} = Accumulator{T,Int}(copy(dct))

"""
    counter{T}(seq::AbstractArray)

Returns an `Accumulator` object containing the elements from `seq`.
"""
function counter(seq::AbstractArray{T}) where T
    ct = counter(T)
    for x in seq
        push!(ct, x)
    end
    return ct
end

copy(ct::Accumulator{T,V}) where {T,V<:Number} = Accumulator{T,V}(copy(ct.map))

length(a::Accumulator) = length(a.map)

## retrieval

get(ct::Accumulator, x, default) = get(ct.map, x, default)
# need to allow user specified default in order to
# correctly implement "informal" Associative interface

getindex(ct::Accumulator{T,V}, x) where {T,V} = get(ct.map, x, zero(V))

haskey(ct::Accumulator, x) = haskey(ct.map, x)

keys(ct::Accumulator) = keys(ct.map)

values(ct::Accumulator) = values(ct.map)

sum(ct::Accumulator) = sum(values(ct.map))

## iteration

start(ct::Accumulator) = start(ct.map)
next(ct::Accumulator, state) = next(ct.map, state)
done(ct::Accumulator, state) = done(ct.map, state)


# manipulation

push!(ct::Accumulator, x, a::Number) = (ct.map[x] = ct[x] + a)
push!(ct::Accumulator{T,V}, x) where {T,V} = push!(ct, x, one(V))

# To remove ambiguities related to Accumulator now being a subtype of Associative
push!(ct::Accumulator{T,V}, x::T) where T<:Pair where V = push!(ct, x, one(V))
push!(ct::Accumulator{T,V}, x::Pair) where {T,V} = push!(ct, convert(T, x))

function push!(ct::Accumulator, r::Accumulator)
    for (x, v) in r
        push!(ct, x, v)
    end
    ct
end

pop!(ct::Accumulator, x) = pop!(ct.map, x)

function merge!(ct1::Accumulator, others::Accumulator...)
    for ct in others
        push!(ct1,ct)
    end
    return ct1
end

merge(ct1::Accumulator) = ct1
function merge(ct1::Accumulator{T,V}, others::Accumulator{T,V}...) where {T,V<:Number}
    ct = copy(ct1)
    merge!(ct,others...)
    return ct
end
