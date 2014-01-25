# ordered dict

import Base: haskey, get, get!, getkey, delete!, push!, pop!, empty!,
             setindex!, getindex, sizehint, length, isempty, start,
             next, done, keys, values, setdiff, setdiff!,
             union, union!, intersect, isequal, filter, filter!,
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
    OrderedDict(kv) = new(HashDict{K,V,Ordered}(kv))
    OrderedDict(ks,vs) = new(HashDict{K,V,Ordered}(ks,vs))
end

OrderedDict() = OrderedDict{Any,Any}()

OrderedDict{K,V}(ks::AbstractArray{K}, vs::AbstractArray{V}) = OrderedDict{K,V}(ks,vs)
OrderedDict{K,V}(::Type{K},::Type{V}) = OrderedDict{K,V}()
OrderedDict(ks,vs) = OrderedDict{eltype(ks),eltype(vs)}(ks, vs)

OrderedDict{K,V}(kv::AbstractArray{(K,V)}) = OrderedDict{K,V}(kv)

## Functions

## Most functions are simply delegated to the wrapped HashDict

@delegate OrderedDict.d [ haskey, get, get!, getkey, delete!, pop!,
                          empty!, setindex!, getindex, sizehint,
                          length, isempty, start, next, done, keys,
                          values ]

similar{K,V}(d::OrderedDict{K,V}) = OrderedDict{K,V}()
in{T<:OrderedDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)