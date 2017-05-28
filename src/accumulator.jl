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

get{T,V}(ct::Accumulator{T,V}, x::T, default) = get(ct.map, x, default)
# need to allow user specified default in order to
# correctly implement "informal" Associative interface

getindex{T,V}(ct::Accumulator{T,V}, x::T) = get(ct.map, x, zero(V))

haskey{T,V}(ct::Accumulator{T,V}, x::T) = haskey(ct.map, x)

keys(ct::Accumulator) = keys(ct.map)

values(ct::Accumulator) = values(ct.map)

sum(ct::Accumulator) = sum(values(ct.map))

## iteration

start(ct::Accumulator) = start(ct.map)
next(ct::Accumulator, state) = next(ct.map, state)
done(ct::Accumulator, state) = done(ct.map, state)


# manipulation

push!{T,V<:Number}(ct::Accumulator{T,V}, x::T, a::V) = (ct.map[x] = ct[x] + a)
push!{T,V<:Number,V2<:Number}(ct::Accumulator{T,V}, x::T, a::V2) = push!(ct, x, convert(V,a))
push!{T,V<:Number}(ct::Accumulator{T,V}, x::T) = push!(ct, x, one(V))

# To remove ambiguities related to Accumulator now being a subtype of Associative
if VERSION < v"0.6.0-dev.2123"
    push!{T,V<:Number}(ct::Accumulator{T,V}, x::Pair) = push!(ct, x, one(V))
else
    include_string("push!(ct::Accumulator{T,V}, x::T) where T<:Pair where V<:Number = push!(ct, x, one(V))")
end

function push!{T,V<:Number,V2<:Number}(ct::Accumulator{T,V}, r::Accumulator{T,V2})
    for (x::T, v::V2) in r
        push!(ct, x, v)
    end
    ct
end

pop!{T,V<:Number}(ct::Accumulator{T,V}, x::T) = pop!(ct.map, x)

function merge!{T,V<:Number}(ct1::Accumulator{T,V}, others::Accumulator{T,V}...)
    for ct in others
        push!(ct1,ct)
    end
    return ct1
end

merge{T,V<:Number}(ct1::Accumulator{T,V}) = ct1
function merge{T,V<:Number}(ct1::Accumulator{T,V}, others::Accumulator{T,V}...)
    ct = copy(ct1)
    merge!(ct,others...)
    return ct
end
