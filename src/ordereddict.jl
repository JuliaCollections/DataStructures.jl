# ordered dict

import Base: haskey, get, get!, getkey, delete!, push!, pop!, empty!,
             setindex!, getindex, length, isempty, start,
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
    OrderedDict(kv) = new(HashDict{K,V,Ordered}(kv))
    if VERSION >= v"0.4.0-dev+980"
        OrderedDict(ps::Pair{K,V}...) = new(HashDict{K,V,Ordered}(ps...))
    end
    #OrderedDict(ks,vs) = new(HashDict{K,V,Ordered}(ks,vs))
end

OrderedDict() = OrderedDict{Any,Any}()
OrderedDict(kv::Tuple{}) = OrderedDict()
OrderedDict(kv) = ordered_dict_with_eltype(kv, eltype(kv))

ordered_dict_with_eltype{K,V}(kv, ::Type{Tuple{K,V}}) = OrderedDict{K,V}(kv)
ordered_dict_with_eltype(kv, t) = OrderedDict{Any,Any}(kv)

if VERSION >= v"0.4.0-dev+980"
    OrderedDict{K,V}(ps::Pair{K,V}...)              = OrderedDict{K,V}(ps...)
    OrderedDict{K,V}(kv::Tuple{Vararg{Pair{K,V}}})         = OrderedDict{K,V}(kv)
    OrderedDict{K}(kv::Tuple{Vararg{Pair{K}}})             = OrderedDict{K,Any}(kv)
    OrderedDict{V}(kv::Tuple{Vararg{Pair{TypeVar(:K),V}}}) = OrderedDict{Any,V}(kv)
    OrderedDict(kv::Tuple{Vararg{Pair}})                   = OrderedDict{Any,Any}(kv)

    OrderedDict{K,V}(kv::AbstractArray{Pair{K,V}}) = OrderedDict{K,V}(kv)

    ordered_dict_with_eltype{K,V}(kv, ::Type{Pair{K,V}}) = OrderedDict{K,V}(kv)
end

copy(d::OrderedDict) = OrderedDict(d)

## Functions

## Most functions are simply delegated to the wrapped HashDict

@delegate OrderedDict.d [ haskey, get, get!, getkey, delete!, pop!,
                         empty!, setindex!, getindex,
                         length, isempty, start, next, done, keys,
                         values ]

sizehint(d::OrderedDict, sz::Integer) = (sizehint(d.d, sz); d)

if VERSION >= v"0.4.0-dev+980"
    push!(d::OrderedDict, kv::Pair) = (push!(d.d, kv); d)
    push!(d::OrderedDict, kv::Pair, kv2::Pair) = (push!(d.d, kv, kv2); d)
    push!(d::OrderedDict, kv::Pair, kv2::Pair, kv3::Pair...) = (push!(d.d, kv, kv2, kv3...); d)
end

push!(d::OrderedDict, kv) = (push!(d.d, kv); d)
push!(d::OrderedDict, kv, kv2...) = (push!(d.d, kv, kv2...); d)

function merge(d::OrderedDict, others::Associative...)
    K, V = keytype(d), valtype(d)
    for other in others
        (Ko, Vo) = keytype(other), valtype(other)
        K = promote_type(K, Ko)
        V = promote_type(V, Vo)
    end
    merge!(OrderedDict{K,V}(), d, others...)
end

similar{K,V}(d::OrderedDict{K,V}) = OrderedDict{K,V}()
in{T<:OrderedDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)
