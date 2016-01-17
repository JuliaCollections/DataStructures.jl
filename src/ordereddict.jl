
# OrderedDict

import Base: haskey, get, get!, getkey, delete!, push!, pop!, empty!,
             setindex!, getindex, length, isempty, start,
             next, done, keys, values, setdiff, setdiff!,
             union, union!, intersect, filter, filter!,
             hash, eltype, KeyIterator, ValueIterator, convert, copy,
             merge


type OrderedDict{K,V} <: Associative{K,V}
    slots::Array{Int32,1}
    keys::Array{K,1}
    vals::Array{V,1}
    ndel::Int
    dirty::Bool

    function OrderedDict()
        new(zeros(Int32,16), Array(K,0), Array(V,0), 0, false)
    end
    function OrderedDict(kv)
        h = OrderedDict{K,V}()
        for (k,v) in kv
            h[k] = v
        end
        return h
    end
    OrderedDict(p::Pair) = setindex!(OrderedDict{K,V}(), p.second, p.first)
    function OrderedDict(ps::Pair...)
        h = OrderedDict{K,V}()
        sizehint!(h, length(ps))
        for p in ps
            h[p.first] = p.second
        end
        return h
    end
    function OrderedDict(d::OrderedDict{K,V})
        if d.ndel > 0
            rehash!(d)
        end
        @assert d.ndel == 0
        new(copy(d.slots), copy(d.keys), copy(d.vals), 0)
    end
end
OrderedDict() = OrderedDict{Any,Any}()
OrderedDict(kv::Tuple{}) = OrderedDict()
copy(d::OrderedDict) = OrderedDict(d)


# TODO: this can probably be simplified using `eltype` as a THT (Tim Holy trait)
# OrderedDict{K,V}(kv::Tuple{Vararg{Tuple{K,V}}})          = OrderedDict{K,V}(kv)
# OrderedDict{K  }(kv::Tuple{Vararg{Tuple{K,Any}}})        = OrderedDict{K,Any}(kv)
# OrderedDict{V  }(kv::Tuple{Vararg{Tuple{Any,V}}})        = OrderedDict{Any,V}(kv)
OrderedDict{K,V}(kv::Tuple{Vararg{Pair{K,V}}})           = OrderedDict{K,V}(kv)
OrderedDict{K}  (kv::Tuple{Vararg{Pair{K}}})             = OrderedDict{K,Any}(kv)
OrderedDict{V}  (kv::Tuple{Vararg{Pair{TypeVar(:K),V}}}) = OrderedDict{Any,V}(kv)
OrderedDict     (kv::Tuple{Vararg{Pair}})                = OrderedDict{Any,Any}(kv)

OrderedDict{K,V}(kv::AbstractArray{Tuple{K,V}}) = OrderedDict{K,V}(kv)
OrderedDict{K,V}(kv::AbstractArray{Pair{K,V}})  = OrderedDict{K,V}(kv)
OrderedDict{K,V}(kv::Associative{K,V})          = OrderedDict{K,V}(kv)

OrderedDict{K,V}(ps::Pair{K,V}...)            = OrderedDict{K,V}(ps)
OrderedDict{K}  (ps::Pair{K}...,)             = OrderedDict{K,Any}(ps)
OrderedDict{V}  (ps::Pair{TypeVar(:K),V}...,) = OrderedDict{Any,V}(ps)
OrderedDict     (ps::Pair...)                 = OrderedDict{Any,Any}(ps)

function OrderedDict(kv)
    try
        dict_with_eltype(kv, eltype(kv))
    catch e
        if any(x->isempty(methods(x, (typeof(kv),))), [start, next, done]) ||
            !all(x->isa(x,Union{Tuple,Pair}),kv)
            throw(ArgumentError("Dict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

dict_with_eltype{K,V}(kv, ::Type{Tuple{K,V}}) = OrderedDict{K,V}(kv)
dict_with_eltype{K,V}(kv, ::Type{Pair{K,V}}) = OrderedDict{K,V}(kv)
dict_with_eltype(kv, t) = OrderedDict{Any,Any}(kv)

similar{K,V}(d::OrderedDict{K,V}) = OrderedDict{K,V}()

length(d::OrderedDict) = length(d.keys) - d.ndel
isempty(d::OrderedDict) = (length(d)==0)

# conversion between OrderedDict types
function convert{K,V}(::Type{OrderedDict{K,V}},d::Associative)
    h = OrderedDict{K,V}()
    for (k,v) in d
        ck = convert(K,k)
        if !haskey(h,ck)
            h[ck] = convert(V,v)
        else
            error("key collision during dictionary conversion")
        end
    end
    return h
end
convert{K,V}(::Type{OrderedDict{K,V}},d::OrderedDict{K,V}) = d

hashindex(key, sz) = ((hash(key)%Int) & (sz-1)) + 1

function rehash!{K,V}(h::OrderedDict{K,V}, newsz = length(h.slots))
    olds = h.slots
    keys = h.keys
    vals = h.vals
    sz = length(olds)
    newsz = _tablesz(newsz)
    h.dirty = true
    count0 = length(h)
    if count0 == 0
        resize!(h.slots, newsz)
        fill!(h.slots, 0)
        resize!(h.keys, 0)
        resize!(h.vals, 0)
        h.ndel = 0
        return h
    end

    slots = zeros(Int32,newsz)

    if h.ndel > 0
        ndel0 = h.ndel
        ptrs = !isbits(K)
        to = 1
        # TODO: to get the best performance we need to avoid reallocating these.
        # This algorithm actually works in place, unless the dict is modified
        # due to GC during this process.
        newkeys = similar(keys, count0)
        newvals = similar(vals, count0)
        @inbounds for from = 1:length(keys)
            if !ptrs || isdefined(keys, from)
                k = keys[from]
                hashk = hash(k)%Int
                isdeleted = false
                if !ptrs
                    iter = 0
                    maxprobe = max(16, sz>>6)
                    index = (hashk & (sz-1)) + 1
                    while iter <= maxprobe
                        si = olds[index]
                        #si == 0 && break  # shouldn't happen
                        si == from && break
                        si == -from && (isdeleted=true; break)
                        index = (index & (sz-1)) + 1
                        iter += 1
                    end
                end
                if !isdeleted
                    index = (hashk & (newsz-1)) + 1
                    while slots[index] != 0
                        index = (index & (newsz-1)) + 1
                    end
                    slots[index] = to
                    newkeys[to] = k
                    newvals[to] = vals[from]
                    to += 1
                end
                if h.ndel != ndel0
                    # if items are removed by finalizers, retry
                    return rehash!(h, newsz)
                end
            end
        end
        h.keys = newkeys
        h.vals = newvals
        h.ndel = 0
    else
        @inbounds for i = 1:count0
            k = keys[i]
            index = hashindex(k, newsz)
            while slots[index] != 0
                index = (index & (newsz-1)) + 1
            end
            slots[index] = i
            if h.ndel > 0
                # if items are removed by finalizers, retry
                return rehash!(h, newsz)
            end
        end
    end

    h.slots = slots
    return h
end

function sizehint!(d::OrderedDict, newsz)
    slotsz = (newsz*3)>>1
    oldsz = length(d.slots)
    if slotsz <= oldsz
        # todo: shrink
        # be careful: rehash!() assumes everything fits. it was only designed
        # for growing.
        return d
    end
    # grow at least 25%
    slotsz = max(slotsz, (oldsz*5)>>2)
    rehash!(d, slotsz)
end

function empty!{K,V}(h::OrderedDict{K,V})
    fill!(h.slots, 0)
    empty!(h.keys)
    empty!(h.vals)
    h.ndel = 0
    h.dirty = true
    return h
end

# get the index where a key is stored, or -1 if not present
function ht_keyindex{K,V}(h::OrderedDict{K,V}, key, direct)
    slots = h.slots
    sz = length(slots)
    iter = 0
    maxprobe = max(16, sz>>6)
    index = hashindex(key, sz)
    keys = h.keys

    @inbounds while iter <= maxprobe
        si = slots[index]
        si == 0 && break
        if si > 0 && isequal(key, keys[si])
            return ifelse(direct, oftype(index, si), index)
        end

        index = (index & (sz-1)) + 1
        iter+=1
    end

    return -1
end

# get the index where a key is stored, or -pos if not present
# and the key would be inserted at pos
# This version is for use by setindex! and get!
function ht_keyindex2{K,V}(h::OrderedDict{K,V}, key)
    slots = h.slots
    sz = length(slots)
    iter = 0
    maxprobe = max(16, sz>>6)
    index = hashindex(key, sz)
    keys = h.keys

    @inbounds while iter <= maxprobe
        si = slots[index]
        if si == 0
            return -index
        elseif si > 0 && isequal(key, keys[si])
            return oftype(index, si)
        end

        index = (index & (sz-1)) + 1
        iter+=1
    end

    rehash!(h, length(h) > 64000 ? sz*2 : sz*4)

    return ht_keyindex2(h, key)
end

function _setindex!(h::OrderedDict, v, key, index)
    hk, hv = h.keys, h.vals
    #push!(h.keys, key)
    ccall(:jl_array_grow_end, Void, (Any, UInt), hk, 1)
    nk = length(hk)
    @inbounds hk[nk] = key
    #push!(h.vals, v)
    ccall(:jl_array_grow_end, Void, (Any, UInt), hv, 1)
    @inbounds hv[nk] = v
    @inbounds h.slots[index] = nk
    h.dirty = true

    sz = length(h.slots)
    cnt = nk - h.ndel
    # Rehash now if necessary
    if h.ndel >= ((3*nk)>>2) || cnt*3 > sz*2
        # > 3/4 deleted or > 2/3 full
        rehash!(h, cnt > 64000 ? cnt*2 : cnt*4)
    end
end

function setindex!{K,V}(h::OrderedDict{K,V}, v0, key0)
    key = convert(K,key0)
    if !isequal(key,key0)
        throw(ArgumentError("$key0 is not a valid key for type $K"))
    end
    v = convert(V,  v0)

    index = ht_keyindex2(h, key)

    if index > 0
        @inbounds h.keys[index] = key
        @inbounds h.vals[index] = v
    else
        _setindex!(h, v, key, -index)
    end

    return h
end

function get!{K,V}(h::OrderedDict{K,V}, key0, default)
    key = convert(K,key0)
    if !isequal(key,key0)
        throw(ArgumentError("$key0 is not a valid key for type $K"))
    end

    index = ht_keyindex2(h, key)

    index > 0 && return h.vals[index]

    v = convert(V,  default)
    _setindex!(h, v, key, -index)
    return v
end

function get!{K,V}(default::Base.Callable, h::OrderedDict{K,V}, key0)
    key = convert(K,key0)
    if !isequal(key,key0)
        throw(ArgumentError("$key0 is not a valid key for type $K"))
    end

    index = ht_keyindex2(h, key)

    index > 0 && return h.vals[index]

    h.dirty = false
    v = convert(V,  default())
    if h.dirty
        index = ht_keyindex2(h, key)
    end
    if index > 0
        h.keys[index] = key
        h.vals[index] = v
    else
        _setindex!(h, v, key, -index)
    end
    return v
end

function getindex{K,V}(h::OrderedDict{K,V}, key)
    index = ht_keyindex(h, key, true)
    return (index<0) ? throw(KeyError(key)) : h.vals[index]::V
end

function get{K,V}(h::OrderedDict{K,V}, key, default)
    index = ht_keyindex(h, key, true)
    return (index<0) ? default : h.vals[index]::V
end

function get{K,V}(default::Base.Callable, h::OrderedDict{K,V}, key)
    index = ht_keyindex(h, key, true)
    return (index<0) ? default() : h.vals[index]::V
end

haskey(h::OrderedDict, key) = (ht_keyindex(h, key, true) >= 0)
in{T<:OrderedDict}(key, v::KeyIterator{T}) = (ht_keyindex(v.dict, key, true) >= 0)

function getkey{K,V}(h::OrderedDict{K,V}, key, default)
    index = ht_keyindex(h, key, true)
    return (index<0) ? default : h.keys[index]::K
end

function _pop!(h::OrderedDict, index)
    @inbounds val = h.vals[h.slots[index]]
    _delete!(h, index)
    return val
end

function pop!(h::OrderedDict)
    h.ndel > 0 && rehash!(h)
    key = h.keys[end]
    index = ht_keyindex(h, key, false)
    key => _pop!(h, index)
end

function pop!(h::OrderedDict, key)
    index = ht_keyindex(h, key, false)
    index > 0 ? _pop!(h, index) : throw(KeyError(key))
end

function pop!(h::OrderedDict, key, default)
    index = ht_keyindex(h, key, false)
    index > 0 ? _pop!(h, index) : default
end

function _delete!(h::OrderedDict, index)
    @inbounds ki = h.slots[index]
    @inbounds h.slots[index] = -ki
    ccall(:jl_arrayunset, Void, (Any, UInt), h.keys, ki-1)
    ccall(:jl_arrayunset, Void, (Any, UInt), h.vals, ki-1)
    h.ndel += 1
    h.dirty = true
    h
end

function delete!(h::OrderedDict, key)
    index = ht_keyindex(h, key, false)
    if index > 0; _delete!(h, index); end
    h
end

function start(t::OrderedDict)
    t.ndel > 0 && rehash!(t)
    1
end
done(t::OrderedDict, i) = done(t.keys, i)
next(t::OrderedDict, i) = (Pair(t.keys[i],t.vals[i]), i+1)

next{T<:OrderedDict}(v::KeyIterator{T}, i) = (v.dict.keys[i], i+1)
next{T<:OrderedDict}(v::ValueIterator{T}, i) = (v.dict.vals[i], i+1)

function merge(d::OrderedDict, others::Associative...)
    K, V = keytype(d), valtype(d)
    for other in others
        K = promote_type(K, keytype(other))
        V = promote_type(V, valtype(other))
    end
    merge!(OrderedDict{K,V}(), d, others...)
end
