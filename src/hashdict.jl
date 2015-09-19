# HashDict

import Base: KeyIterator, ValueIterator, haskey, get, getkey, delete!,
             pop!, empty!, filter!, setindex!, getindex, similar,
             sizehint, length, filter, isempty, start, next, done,
             keys, values, _tablesz, skip_deleted, serialize, deserialize

if VERSION < v"0.4.0-dev+5152"
    import Base: serialize_type
    const SerState = IO
else
    import Base.Serializer: serialize_type
    const SerState =  Base.Serializer.SerializationState
end

@compat typealias Unordered Void
typealias Ordered   Int

@compat type HashDict{K,V,O<:Union{Ordered,Unordered}} <: Associative{K,V}
    slots::Array{UInt8,1}
    keys::Array{K,1}
    vals::Array{V,1}
    idxs::Array{O,1}
    order::Array{O,1}
    ndel::Int
    count::Int
    deleter::Function

    function HashDict()
        n = 16
        new(zeros(UInt8,n), Array(K,n), Array(V,n), Array(O,n), Array(O,0), 0, 0, identity)
    end
    if VERSION >= v"0.4.0-dev+980"
        HashDict(p::Pair) = setindex!(HashDict{K,V,O}(), p.second, p.first)
        function HashDict(ps::Pair{K,V}...)
            h = HashDict{K,V,O}()
            sizehint(h, length(ps))
            for p in ps
                h[p.first] = p.second
            end
            return h
        end
        HashDict(p::Pair{K,V}) = invoke(HashDict, (Pair{K,V}...), p)
    end
    function HashDict(ks, vs)
        if VERSION >= v"0.4.0-dev+980"
            Base.warn_once("HashDict(kv,vs) is deprecated, use HashDict(zip(ks,vs)) instead")
        end
        n = length(ks)
        h = HashDict{K,V,O}()
        for i=1:n
            h[ks[i]] = vs[i]
        end
        return h
    end
    function HashDict(kv)
        h = HashDict{K,V,O}()
        sizehint(h, length(kv))
        for (k,v) in kv
            h[k] = v
        end
        return h
    end
end

HashDict() = HashDict{Any,Any,Unordered}()
HashDict(kv::@compat Tuple{}) = HashDict()
HashDict(kv) = hash_dict_with_eltype(kv, eltype(kv))

hash_dict_with_eltype{K,V}(kv, ::Type{@compat Tuple{K,V}}) = HashDict{K,V}(kv)
hash_dict_with_eltype(kv, t) = HashDict{Any,Any}(kv)

HashDict{K,V}(kv::AbstractArray{@compat Tuple{K,V}}) = HashDict{K,V,Unordered}(kv)
if VERSION >= v"0.4.0-dev+980"
    HashDict{K,V}(ps::Pair{K,V}...) = HashDict{K,V,Unordered}(ps...)
    HashDict{K,V}(kv::@compat Tuple{Vararg{Pair{K,V}}})         = HashDict{K,V}(kv)
    HashDict{K}(kv::@compat Tuple{Vararg{Pair{K}}})             = HashDict{K,Any}(kv)
    HashDict{V}(kv::@compat Tuple{Vararg{Pair{TypeVar(:K),V}}}) = HashDict{Any,V}(kv)
    HashDict(kv::@compat Tuple{Vararg{Pair}})                   = HashDict{Any,Any}(kv)

    HashDict{K,V}(kv::AbstractArray{Pair{K,V}}) = HashDict{K,V}(kv)

    hash_dict_with_eltype{K,V}(kv, ::Type{Pair{K,V}}) = HashDict{K,V}(kv)
end

# TODO: these could be more efficient
HashDict{K,V,O}(d::HashDict{K,V,O}) = HashDict{K,V,O}(collect(d))
HashDict{K,V}(d::Associative{K,V}) = HashDict{K,V,Unordered}(collect(d))

similar{K,V,O}(d::HashDict{K,V,O}) = HashDict{K,V,O}()

function serialize(s::SerState, t::HashDict)
    serialize_type(s, typeof(t))
    write(s, int32(length(t)))
    for (k,v) in t
        serialize(s, k)
        serialize(s, v)
    end
end

function deserialize{K,V,O}(s::SerState, T::Type{HashDict{K,V,O}})
    n = read(s, Int32)
    t = T(); sizehint(t, n)
    for i = 1:n
        k = deserialize(s)
        v = deserialize(s)
        t[k] = v
    end
    return t
end

hashindex(key, sz) = (reinterpret(Int,(hash(key))) & (sz-1)) + 1

isslotempty(h::HashDict, i::Int) = h.slots[i] == 0x0
isslotfilled(h::HashDict, i::Int) = h.slots[i] == 0x1
isslotmissing(h::HashDict, i::Int) = h.slots[i] == 0x2

function rehash{K,V}(h::HashDict{K,V,Unordered}, newsz)
    newsz = _tablesz(newsz)

    if h.count == 0
        resize!(h.slots, newsz)
        fill!(h.slots, 0)
        resize!(h.keys, newsz)
        resize!(h.vals, newsz)
        h.ndel = 0
        return h
    end

    olds = h.slots
    oldk = h.keys
    oldv = h.vals
    sz = length(olds)

    slots = zeros(UInt8,newsz)
    keys = Array(K, newsz)
    vals = Array(V, newsz)
    count0 = h.count
    count = 0

    for i = 1:sz
        if olds[i] == 0x1
            k = oldk[i]
            v = oldv[i]
            index = hashindex(k, newsz)
            while slots[index] != 0
                index = (index & (newsz-1)) + 1
            end
            slots[index] = 0x1
            keys[index] = k
            vals[index] = v
            count += 1

            if h.count != count0
                # if items are removed by finalizers, retry
                return rehash(h, newsz)
            end
        end
    end

    h.slots = slots
    h.keys = keys
    h.vals = vals
    h.count = count
    h.ndel = 0

    return h
end

function rehash{K,V}(h::HashDict{K,V,Ordered}, newsz)
    newsz = _tablesz(newsz)

    if h.count == 0
        resize!(h.slots, newsz)
        fill!(h.slots, 0)
        resize!(h.keys, newsz)
        resize!(h.vals, newsz)
        resize!(h.idxs, newsz)
        resize!(h.order, 0)
        h.ndel = 0
        return h
    end

    _compact_order(h)

    olds = h.slots
    oldk = h.keys
    oldv = h.vals
    oldi = h.idxs
    oldo = h.order
    sz = length(olds)

    slots = zeros(UInt8,newsz)
    keys = Array(K, newsz)
    vals = Array(V, newsz)
    idxs = Array(Int, newsz)
    order = Array(Int, h.count)
    count0 = h.count
    count = 0

    for i = 1:sz
        if olds[i] == 0x1
            k = oldk[i]
            v = oldv[i]
            idx = oldi[i]
            index = hashindex(k, newsz)
            while slots[index] != 0
                index = (index & (newsz-1)) + 1
            end
            slots[index] = 0x1
            keys[index] = k
            vals[index] = v
            idxs[index] = idx
            order[idx] = index
            count += 1

            if h.count != count0
                # if items are removed by finalizers, retry
                return rehash(h, newsz)
            end
        end
    end

    h.slots = slots
    h.keys = keys
    h.vals = vals
    h.idxs = idxs
    h.order = order
    h.count = count
    h.ndel = 0

    return h
end


function _compact_order{K,V}(h::HashDict{K,V,Ordered})
    h.count == length(h.order) && return

    local i,j

    for i = 1:length(h.order)-1
        h.order[i] == 0 && break
    end

    for j = i+1:length(h.order)
        h.order[j] != 0 && break
    end

    for k = j:length(h.order)
        idx = h.order[k]
        if idx > 0
            h.order[i] = idx
            h.idxs[idx] = i
            i += 1
        end
    end

    resize!(h.order, h.count)

    nothing
end

function sizehint(d::HashDict, newsz)
    oldsz = length(d.slots)
    if newsz <= oldsz
        # todo: shrink
        # be careful: rehash() assumes everything fits. it was only designed
        # for growing.
        return d
    end
    # grow at least 25%
    newsz = max(newsz, (oldsz*5)>>2)
    rehash(d, newsz)
end

function empty!{K,V}(h::HashDict{K,V})
    fill!(h.slots, 0x0)
    sz = length(h.slots)
    h.keys = Array(K, sz)
    h.vals = Array(V, sz)
    h.ndel = 0
    h.count = 0
    return h
end

function empty!{K,V}(h::HashDict{K,V,Ordered})
    sz = length(h.slots)
    fill!(h.slots, 0x0)
    h.keys = Array(K, sz)
    h.vals = Array(V, sz)
    h.idxs = Array(Int, sz)
    h.order = Array(Int, 0)
    h.ndel = 0
    h.count = 0
    return h
end

# get the index where a key is stored, or -1 if not present
function ht_keyindex{K,V}(h::HashDict{K,V}, key)
    sz = length(h.keys)
    iter = 0
    maxprobe = max(16, sz>>6)
    index = hashindex(key, sz)
    keys = h.keys

    while true
        if isslotempty(h,index)
            break
        end
        if !isslotmissing(h,index) && isequal(key,keys[index])
            return index
        end

        index = (index & (sz-1)) + 1
        iter+=1
        iter > maxprobe && break
    end

    return -1
end

# get the index where a key is stored, or -pos if not present
# and the key would be inserted at pos
# This version is for use by setindex! and get!
function ht_keyindex2{K,V}(h::HashDict{K,V}, key)
    sz = length(h.keys)

    if h.ndel >= ((3*sz)>>2) || h.count*3 > sz*2
        # > 3/4 deleted or > 2/3 full
        rehash(h, h.count > 64000 ? h.count*2 : h.count*4)
        sz = length(h.keys)  # rehash may resize the table at this point!
    end

    iter = 0
    maxprobe = max(16, sz>>6)
    index = hashindex(key, sz)
    avail = 0
    keys = h.keys

    while true
        if isslotempty(h,index)
            avail < 0 && return avail
            return -index
        end

        if isslotmissing(h,index)
            if avail == 0
                # found an available slot, but need to keep scanning
                # in case "key" already exists in a later collided slot.
                avail = -index
            end
        elseif isequal(key, keys[index])
            return index
        end

        index = (index & (sz-1)) + 1
        iter+=1
        iter > maxprobe && break
    end

    avail < 0 && return avail

    rehash(h, h.count > 64000 ? sz*2 : sz*4)

    return ht_keyindex2(h, key)
end

function _setindex!(h::HashDict, v, key, index)
    h.slots[index] = 0x1
    h.keys[index] = key
    h.vals[index] = v
    h.count += 1
    return h
end

function _setindex!{K,V}(h::HashDict{K,V,Ordered}, v, key, index)
    h.slots[index] = 0x1
    h.keys[index] = key
    h.vals[index] = v
    push!(h.order, index)
    h.idxs[index] = length(h.order)
    h.count += 1
    return h
end

function setindex!{K,V}(h::HashDict{K,V}, v0, key0)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end
    v   = convert(V,  v0)

    index = ht_keyindex2(h, key)

    if index > 0
        h.vals[index] = v
    else
        _setindex!(h, v, key, -index)
    end

    return h
end

function get!{K,V}(h::HashDict{K,V}, key0, default)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end

    index = ht_keyindex2(h, key)

    index > 0 && return h.vals[index]

    v = convert(V,  default)
    _setindex!(h, v, key, -index)
    return v
end

function get!{K,V}(h::HashDict{K,V}, key0, default)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end

    index = ht_keyindex2(h, key)

    index > 0 && return h.vals[index]

    v = convert(V,  default)
    _setindex!(h, v, key, -index)
    return v
end

# TODO: this makes it challenging to have V<:Base.Callable
function get!{K,V,F<:Base.Callable}(h::HashDict{K,V}, key0, default::F)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end

    index = ht_keyindex2(h, key)

    index > 0 && return h.vals[index]

    v = convert(V,  default())
    _setindex!(h, v, key, -index)
    return v
end

function getindex{K,V}(h::HashDict{K,V}, key)
    index = ht_keyindex(h, key)
    return (index<0) ? throw(KeyError(key)) : h.vals[index]::V
end

function get{K,V}(h::HashDict{K,V}, key, deflt)
    index = ht_keyindex(h, key)
    return (index<0) ? deflt : h.vals[index]::V
end

haskey(h::HashDict, key) = (ht_keyindex(h, key) >= 0)
contains{T<:HashDict}(v::KeyIterator{T}, key) = (ht_keyindex(v.dict, key) >= 0)

function getkey{K,V}(h::HashDict{K,V}, key, deflt)
    index = ht_keyindex(h, key)
    return (index<0) ? deflt : h.keys[index]::K
end

function _pop!(h::HashDict, index)
    val = h.vals[index]
    _delete!(h, index)
    return val
end

function pop!(h::HashDict, key)
    index = ht_keyindex(h, key)
    index > 0 ? _pop!(h, index) : throw(KeyError(key))
end

function pop!(h::HashDict, key, default)
    index = ht_keyindex(h, key)
    index > 0 ? _pop!(h, index) : default
end


function _delete!(h::HashDict, index)
    h.slots[index] = 0x2
    ccall(:jl_arrayunset, Void, (Any, UInt), h.keys, index-1)
    ccall(:jl_arrayunset, Void, (Any, UInt), h.vals, index-1)
    h.ndel += 1
    h.count -= 1
    return h
end

function _delete!{K,V}(h::HashDict{K,V,Ordered}, index)
    h.slots[index] = 0x2
    ccall(:jl_arrayunset, Void, (Any, UInt), h.keys, index-1)
    ccall(:jl_arrayunset, Void, (Any, UInt), h.vals, index-1)
    h.order[h.idxs[index]] = 0
    h.ndel += 1
    h.count -= 1
    return h
end

function delete!(h::HashDict, key)
    index = ht_keyindex(h, key)
    index > 0 && _delete!(h, index)
    return h
end

function skip_deleted{K,V,O}(h::HashDict{K,V,O}, i)
    L = length(h.slots)
    while i<=L && !isslotfilled(h,i)
        i += 1
    end
    return i
end

function skip_deleted{K,V}(h::HashDict{K,V,Ordered}, i)
    L = length(h.order)
    while i<=L && h.order[i] == 0
        i += 1
    end
    return i
end

start(t::HashDict) = skip_deleted(t, 1)
done(t::HashDict, i) = done(t.vals, i)
if VERSION >= v"0.4.0-dev+980"
    next(t::HashDict, i) = (Pair(t.keys[i],t.vals[i]), skip_deleted(t,i+1))
else
    next(t::HashDict, i) = ((t.keys[i],t.vals[i]), skip_deleted(t,i+1))
end


done{K,V}(t::HashDict{K,V,Ordered}, i) = done(t.order, i)
if VERSION >= v"0.4.0-dev+980"
    next{K,V}(t::HashDict{K,V,Ordered}, i) = (Pair(t.keys[t.order[i]],t.vals[t.order[i]]), skip_deleted(t,i+1))
else
    next{K,V}(t::HashDict{K,V,Ordered}, i) = ((t.keys[t.order[i]],t.vals[t.order[i]]), skip_deleted(t,i+1))
end

isempty(t::HashDict) = (t.count == 0)
length(t::HashDict) = t.count

next(v::KeyIterator{HashDict}, i) = (v.dict.keys[i], skip_deleted(v.dict,i+1))
next(v::ValueIterator{HashDict}, i) = (v.dict.vals[i], skip_deleted(v.dict,i+1))

next{K,V}(v::KeyIterator{HashDict{K,V,Ordered}}, i) = (v.dict.keys[v.dict.order[i]], skip_deleted(v.dict,i+1))
next{K,V}(v::ValueIterator{HashDict{K,V,Ordered}}, i) = (v.dict.vals[v.dict.order[i]], skip_deleted(v.dict,i+1))

if VERSION >= v"0.4.0-dev+980"
    push!(t::HashDict, p::Pair) = setindex!(t, p.second, p.first)
    push!(t::HashDict, p::Pair, q::Pair) = push!(push!(t, p), q)
    push!(t::HashDict, p::Pair, q::Pair, r::Pair...) = push!(push!(push!(t, p), q), r...)
end

push!(d::HashDict, p) = setindex!(d, p[2], p[1])
push!(d::HashDict, p, q) = push!(push!(d, p), q)
push!(d::HashDict, p, q, r...) = push!(push!(push!(d, p), q), r...)
