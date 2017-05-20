# A counter type

immutable Accumulator{T, V<:Number} <: Associative{T,V}
    map::Dict{T,V}
end

## constructors

Accumulator{T,V<:Number}(::Type{T}, ::Type{V}) = Accumulator{T,V}(Dict{T,V}())
counter(T::Type) = Accumulator(T,Int)

counter{T}(dct::Dict{T,Int}) = Accumulator{T,Int}(copy(dct))

"""
    counter{T}(seq::AbstractArray)

Returns an `Accumulator` object containing the elements from `seq`.
"""
function counter{T}(seq::AbstractArray{T})
    ct = counter(T)
    for x in seq
        push!(ct, x)
    end
    return ct
end

copy{T,V<:Number}(ct::Accumulator{T,V}) = Accumulator{T,V}(copy(ct.map))

length(a::Accumulator) = length(a.map)

## retrieval

get(ct::Accumulator, x, default) = get(ct.map, x, default)
# need to allow user specified default in order to
# correctly implement "informal" Associative interface

getindex{T,V}(ct::Accumulator{T,V}, x) = get(ct.map, x, zero(V))

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
push!{T,V}(ct::Accumulator{T,V}, x) = push!(ct, x, one(V))

# To remove ambiguities related to Accumulator now being a subtype of Associative
if VERSION < v"0.6.0-dev.2123"
    push!{T,V}(ct::Accumulator{T,V}, x::Pair) = push!(ct, x, one(V))
else
    include_string("push!(ct::Accumulator{T,V}, x::T) where T<:Pair where V = push!(ct, x, one(V))")
end

function push!(ct::Accumulator, r::Accumulator)
    for (x, v) in r
        push!(ct, x, v)
    end
    ct
end

pop!(ct::Accumulator, x) = pop!(ct.map, x)

merge(ct1::Accumulator, ct2::Accumulator) = push!(copy(ct1), ct2)
