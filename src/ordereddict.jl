# ordered dict

import Base: haskey, get, get!, getkey, delete!, push!, pop!, empty!,
             setindex!, getindex, sizehint, length, isempty, start,
             next, done, keys, values, setdiff, setdiff!,
             union, union!, intersect, filter, filter!,
             hash, eltype

# This is just a simple wrapper around a HashDict, which is a modified
# implementation of the Dict implementation in Base allowing ordering
# information to be maintained.

# In particular, the HashDict stored in an OrderedDict is a
# HashDict{K,V,Ordered}

# A HashDict{K,V,Unordered} would be equivalent to Base.Dict

immutable OrderedDict{K,V} <: Associative{K,V}
    d::HashDict{K,V,Ordered}

    OrderedDict() = new(HashDict{K,V,Ordered}())
    OrderedDict(kv::AbstractArray{(K,V)}) = new(HashDict{K,V,Ordered}(kv))
    if VERSION >= v"0.4.0-dev+980"
        OrderedDict(ps::Pair{K,V}...) = new(HashDict{K,V,Ordered}(ps...))
    end
    OrderedDict(ks,vs) = new(HashDict{K,V,Ordered}(ks,vs))
end

OrderedDict() = OrderedDict{Any,Any}()

OrderedDict{K,V}(ks::AbstractArray{K}, vs::AbstractArray{V}) = OrderedDict{K,V}(ks,vs)
OrderedDict{K,V}(::Type{K},::Type{V}) = OrderedDict{K,V}()
OrderedDict(ks,vs) = OrderedDict{eltype(ks),eltype(vs)}(ks, vs)
if VERSION >= v"0.4.0-dev+980"
    OrderedDict{K,V}(ps::Pair{K,V}...) = OrderedDict{K,V}(ps...)
end

OrderedDict{K,V}(kv::AbstractArray{(K,V)}) = OrderedDict{K,V}(kv)

## Functions

## Most functions are simply delegated to the wrapped HashDict

@delegate OrderedDict.d [ haskey, get, get!, getkey, delete!, pop!,
                          empty!, setindex!, getindex, sizehint,
                          length, isempty, start, next, done, keys,
                          values ]

similar{K,V}(d::OrderedDict{K,V}) = OrderedDict{K,V}()
in{T<:OrderedDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)
