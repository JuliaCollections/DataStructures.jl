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
    if VERSION >= v"0.4.0-dev+980"
        OrderedDict(ps::Pair{K,V}...) = new(HashDict{K,V,Ordered}(ps...))
    end
    #OrderedDict(ks,vs) = new(HashDict{K,V,Ordered}(ks,vs))
end

OrderedDict() = OrderedDict{Any,Any}()
OrderedDict(kv::()) = OrderedDict()
OrderedDict(kv) = ordered_dict_with_eltype(kv, eltype(kv))

ordered_dict_with_eltype{K,V}(kv, ::Type{(K,V)}) = OrderedDict{K,V}(kv)
ordered_dict_with_eltype(kv, t) = OrderedDict{Any,Any}(kv)

if VERSION >= v"0.4.0-dev+980"
    OrderedDict{K,V}(ps::Pair{K,V}...)              = OrderedDict{K,V}(ps...)
    OrderedDict{K,V}(kv::(Pair{K,V}...,))           = OrderedDict{K,V}(kv)
    OrderedDict{K}  (kv::(Pair{K}...,))             = OrderedDict{K,Any}(kv)
    OrderedDict{V}  (kv::(Pair{TypeVar(:K),V}...,)) = OrderedDict{Any,V}(kv)
    OrderedDict     (kv::(Pair...,))                = OrderedDict{Any,Any}(kv)

    OrderedDict{K,V}(kv::AbstractArray{Pair{K,V}})  = OrderedDict{K,V}(kv)

    ordered_dict_with_eltype{K,V}(kv, ::Type{Pair{K,V}})    = OrderedDict{K,V}(kv)
end

copy(d::OrderedDict) = OrderedDict(d)

## Functions

## Most functions are simply delegated to the wrapped HashDict

@compat @delegate OrderedDict.d [ haskey, get, get!, getkey, delete!, pop!,
                                 empty!, setindex!, getindex, sizehint,
                                 length, isempty, start, next, done, keys,
                                 values ]

similar{K,V}(d::OrderedDict{K,V}) = OrderedDict{K,V}()
in{T<:OrderedDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)
