# OrderedDict

import Base: haskey, get, get!, getkey, delete!, push!, pop!, empty!,
             setindex!, getindex, length, isempty, start,
             next, done, keys, values, setdiff, setdiff!,
             union, union!, intersect, filter, filter!,
             hash, eltype, ValueIterator, convert, copy,
             merge

"""
    OrderedDict

`OrderedDict`s are  simply dictionaries  whose entries  have a  particular order.  The order
refers to insertion order, which allows deterministic iteration over the dictionary or set.
"""
mutable struct OrderedDict{K,V} <: AbstractDict{K,V}
    d1::Dict{K,Tuple{V,Int}}
    a1::Vector{Tuple{K,Bool}}

    function OrderedDict{K,V}() where {K,V}
        new{K,V}(Dict{K,Tuple{V,Int}}(), Vector{Tuple{K,Bool}}())
    end
    function OrderedDict{K,V}(kv) where {K,V}
        od = OrderedDict{K,V}()
        for (count, (k,v)) in enumerate(kv)
            push!(od.d1, (k => (v,count)))
            push!(od.a1, (k,true))
        end
        return od
    end

    OrderedDict{K,V}(p::Pair) where {K,V} = OrderedDict{K,V}((p[1],p[2]))

    OrderedDict{K,V}(ps::Pair...) where {K,V} = OrderedDict{K,V}(ps)
end
OrderedDict() = OrderedDict{Any,Any}()
OrderedDict(::Tuple{}) = OrderedDict()
copy(d::OrderedDict) = OrderedDict(d)


# TODO: this can probably be simplified using `eltype` as a THT (Tim Holy trait)
# OrderedDict{K,V}(kv::Tuple{Vararg{Tuple{K,V}}})          = OrderedDict{K,V}(kv)
# OrderedDict{K  }(kv::Tuple{Vararg{Tuple{K,Any}}})        = OrderedDict{K,Any}(kv)
# OrderedDict{V  }(kv::Tuple{Vararg{Tuple{Any,V}}})        = OrderedDict{Any,V}(kv)
OrderedDict(kv::Tuple{Vararg{Pair{K,V}}}) where {K,V}       = OrderedDict{K,V}(kv)
OrderedDict(kv::Tuple{Vararg{Pair{K}}}) where {K}           = OrderedDict{K,Any}(kv)
OrderedDict(kv::Tuple{Vararg{Pair{K,V} where K}}) where {V} = OrderedDict{Any,V}(kv)
OrderedDict(kv::Tuple{Vararg{Pair}})                        = OrderedDict{Any,Any}(kv)

OrderedDict(kv::AbstractArray{Tuple{K,V}}) where {K,V} = OrderedDict{K,V}(kv)
OrderedDict(kv::AbstractArray{Pair{K,V}}) where {K,V}  = OrderedDict{K,V}(kv)
OrderedDict(kv::AbstractDict{K,V}) where {K,V}          = OrderedDict{K,V}(kv)

OrderedDict(ps::Pair{K,V}...) where {K,V}          = OrderedDict{K,V}(ps)
OrderedDict(ps::Pair{K}...,) where {K}             = OrderedDict{K,Any}(ps)
OrderedDict(ps::(Pair{K,V} where K)...,) where {V} = OrderedDict{Any,V}(ps)
OrderedDict(ps::Pair...)                           = OrderedDict{Any,Any}(ps)

function OrderedDict(kv)
    dict_with_eltype(kv, eltype(kv))
end

dict_with_eltype(kv, ::Type{Tuple{K,V}}) where {K,V} = OrderedDict{K,V}(kv)
dict_with_eltype(kv, ::Type{Pair{K,V}}) where {K,V} = OrderedDict{K,V}(kv)
dict_with_eltype(kv, t) = OrderedDict{Any,Any}(kv)

similar(d::OrderedDict{K,V}) where {K,V} = OrderedDict{K,V}()

length(d::OrderedDict) = length(d.d1)
isempty(d::OrderedDict) = length(d.d1)==0

"""
    isordered(::Type)

Property of associative containers, that is `true` if the container type has a
defined order (such as `OrderedDict` and `SortedDict`), and `false` otherwise.
"""
isordered(::Type{T} where {T<:AbstractDict}) = false
isordered(::Type{T} where {T<:OrderedDict}) = true

# conversion between OrderedDict types
function convert(::Type{OrderedDict{K,V}}, d::AbstractDict) where {K,V}
    if !isordered(typeof(d))
        Base.depwarn("Conversion to OrderedDict is deprecated for unordered associative containers (in this case, $(typeof(d))). Use an ordered or sorted associative type, such as SortedDict and OrderedDict.", :convert)
    end
    od = OrderedDict{K,V}()
    for (k,v) in d
        ck = convert(K,k)
        if !haskey(od,ck)
            od[ck] = convert(V,v)
        else
            error("key collision during dictionary conversion")
        end
    end
    return od
end
convert(::Type{OrderedDict{K,V}}, od::OrderedDict{K,V}) where {K,V} = od

sizehint!(od::OrderedDict, newsz) = sizehint!(od.d1, newsz)
haskey(od::OrderedDict, k) = haskey(od.d1, k)

function empty!(od::OrderedDict)
    empty!(od.d1)
    empty!(od.a1)
    return od
end

function _setindex!(od::OrderedDict, v, key)
    count = length(od.a1)
    push!(od.d1, (key => (v, count + 1)))
    push!(od.a1, (key, true))
    nothing
end


function setindex!(od::OrderedDict{K,V}, v0, key0) where {K,V}
    key = convert(K,key0)
    if !isequal(key,key0)
        throw(ArgumentError("$key0 is not a valid key for type $K"))
    end
    v = convert(V,  v0)
    if !haskey(od, key)
        _setindex!(od, v, key)
    else
        vprev = od.d1[key]
        od.d1[key] = (v,vprev[2])
    end
    return od
end

function push!(od::OrderedDict{K,V} where {K,V}, t::Pair)
    od[t[1]] = t[2]
    return od
end



function get!(od::OrderedDict{K,V}, key0, default) where {K,V}
    v = convert(V,  default)
    if !haskey(od,key0)
        od[key0] = v
        return v
    else
        return od[key0]
    end
end
        

function get!(default::Base.Callable, od::OrderedDict{K,V}, key0) where {K,V}
    key = convert(K,key0)
    if !haskey(od,key0)
        v = convert(V,  default())
        od[key0] = v
        return v
    else
        return od[key0]
    end
end

getindex(od::OrderedDict, key) = (od.d1[key])[1]
get(od::OrderedDict, key, default) =
    haskey(od.d1, key) ? od.d1[key][1] : default
get(default::Base.Callable, od::OrderedDict, key) =
    haskey(od.d1, key) ? od.d1[key][1] : default()
getkey(od::OrderedDict, key, default)  = getkey(od.d1, key, default)

function pop!(od::OrderedDict, key)
    e = pop!(od.d1, key)
    # @assert od.a1[e[2]][1] == key  # for debugging
    od.a1[e[2]] = (key, false)
    e[1]
end


pop!(od::OrderedDict, key, default) = haskey(od, key) ? pop!(od, key) : default


function delete!(od::OrderedDict, key)
    if haskey(od, key)
        pop!(od, key)
    end
    od
end

eltype(::OrderedDict{K,V}) where {K,V} = Pair{K,V}
keytype(::OrderedDict{K,V}) where {K,V} = K
valtype(::OrderedDict{K,V}) where {K,V} = V

eltype(::Type{OrderedDict{K,V}}) where {K,V} = Pair{K,V}
keytype(::Type{OrderedDict{K,V}}) where {K,V} = K
valtype(::Type{OrderedDict{K,V}}) where {K,V} = V


struct ODKeyIteration{K,V}
    od::OrderedDict{K,V}
end

struct ODValIteration{K,V}
    od::OrderedDict{K,V}
end

length(odk::ODKeyIteration) = length(odk.od)
length(odv::ODValIteration) = length(odv.od)

getod(od::OrderedDict) = od
getod(odk::ODKeyIteration) = odk.od
getod(odv::ODValIteration) = odv.od

iteratereturnhelper(od::OrderedDict, key) = (key => od[key])
iteratereturnhelper(::ODKeyIteration, key) = key
iteratereturnhelper(odv::ODValIteration, key) = odv.od[key]

keys(od::OrderedDict) = ODKeyIteration(od)
values(od::OrderedDict) = ODValIteration(od)
in(x, odk::ODKeyIteration) = haskey(odk.od, x)

if VERSION >= v"0.7.0-DEV.5126"
    IteratorEltype(::Type{OrderedDict{K,V}} where {K,V}) = HasEltype()
    IteratorSize(::Type{OrderedDict{K,V}} where {K,V}) = HasLength()
    IteratorEltype(::Type{ODKeyIteration{K,V}} where {K,V}) = HasEltype()
    IteratorSize(::Type{ODKeyIteration{K,V}} where {K,V}) = HasLength()
    IteratorEltype(::Type{ODValIteration{K,V}} where {K,V}) = HasEltype()
    IteratorSize(::Type{ODValIteration{K,V}} where {K,V}) = HasLength()

    function iterate(odx::Union{OrderedDict,ODKeyIteration,ODValIteration}, pos = 1)
        od = getod(odx)
        while pos <= length(od.a1)
            if od.a1[pos][2]
                key = od.a1[pos][1]
                return (iteratereturnhelper(odx,key), pos + 1)
            end
            pos += 1
        end
        nothing
    end
else
    function advance(odx::Union{OrderedDict, ODKeyIteration,ODValIteration}, pos)
        od = getod(odx)
        while pos <= length(od.a1)
            if od.a1[pos][2]
                return pos
            end
            pos += 1
        end
        return 0
    end
    start(odx::Union{OrderedDict, ODKeyIteration, ODValIteration}) = advance(odx, 1)
    done(::Union{OrderedDict, ODKeyIteration, ODValIteration}, pos) = pos == 0
    next(odx::Union{OrderedDict, ODKeyIteration, ODValIteration}, pos) =
        (iteratereturnhelper(odx, getod(odx).a1[pos][1]), advance(odx, pos+1))
end

function merge(d::OrderedDict, others::AbstractDict...)
    K, V = keytype(d), valtype(d)
    for other in others
        K = promote_type(K, keytype(other))
        V = promote_type(V, valtype(other))
    end
    merge!(OrderedDict{K,V}(), d, others...)
end
