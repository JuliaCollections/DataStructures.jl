# HashDict

import Base: KeyIterator, ValueIterator, haskey, get, getkey, delete!, push!,
             pop!, empty!, filter!, setindex!, getindex, similar,
             sizehint, length, filter, isempty, start, next, done,
             keys, values, _tablesz, skip_deleted, serialize, deserialize, serialize_type

typealias Unordered Nothing
typealias Ordered   Int

abstract AbstractHashDict{K,V,O<:Union(Ordered,Unordered)} <: Associative{K,V}

immutable DefaultHashF; end
immutable CallableIdentity; end

call(::DefaultHashF, arg) = hash(arg)
call(::CallableIdentity, arg) = arg

## General Hash Dict
#
# Can be constructed as HashDict{K,V} to behave the same as a native dictionary.
#
# - Additional features over standard dicts:
#    + O: If O === Ordered, makes iteration order deterministic by insertion order
#    + HashF: Allows changing the hash function to use when computing the the slot
#             into which to insert the item
#    + DeriveF: Stores the value DeriveF(k)::DK rather than k for the key of a value (i.e. lookup will suceed
#               if two keys have the same derived value).
#               This is useful for creating equivalence classes of keys. Note that
#               HashF(a) == HashF(b) should imply DeriveF(a) == DeriveF(b) to ensure correct lookup.
##
type HashDict{K,V,O<:Union(Ordered,Unordered),HashF,DeriveF,DK} <: AbstractHashDict{K,V,O}
    slots::Array{Uint8,1}
    keys::Array{DK,1}
    vals::Array{V,1}
    idxs::Array{O,1}
    order::Array{O,1}
    ndel::Int
    count::Int
    hash::HashF
    derive::DeriveF

    function HashDict(hash::HashF, derive::DeriveF)
        n = 16
        new(zeros(Uint8,n), Array(DK,n), Array(V,n), Array(O,n), Array(O,0), 0, 0, hash, derive)
    end
    if VERSION >= v"0.4.0-dev+980"
        function HashDict(hash::HashF, derive::DeriveF, ps::Pair{K,V}...)
            h = HashDict{K,V,O,HashF,DeriveF,DK}(hash,derive)
            sizehint(h, length(ps))
            for p in ps
                h[p.first] = p.second
            end
            return h
        end
    end
    function HashDict(hash::HashF, derive::DeriveF, ks, vs)
        if VERSION >= v"0.4.0-dev+980"
            Base.warn_once("HashDict(kv,vs) is deprecated, use HashDict(collect(zip(ks,vs))) instead")
        end
        n = length(ks)
        h = HashDict{K,V,O,HashF,DeriveF,DK}(hash,derive)
        for i=1:n
            h[ks[i]] = vs[i]
        end
        return h
    end
    function HashDict(hash::HashF, derive::DeriveF, kv::AbstractArray{(K,V)})
        h = HashDict{K,V,O,HashF,DeriveF,DK}(hash, derive)
        sizehint(h, length(kv))
        for (k,v) in kv
            h[k] = v
        end
        return h
    end

    function call{K,V,O<:Union(Ordered,Unordered)}(::Type{HashDict{K,V,O}},args...)
        HashDict{K,V,O,DefaultHashF,CallableIdentity,K}(DefaultHashF(),CallableIdentity(),args...)
    end
end

#
# Slots are the same as for HashDict, except for the following additional values
#  - 0x3 => This element is a continuation and there are more items in this chain. key[index]
#  - 0x4 => This element is the end of a chain
type MultiHashDict{K,V,O<:Union(Ordered,Unordered),HashF,DeriveF,DK} <: AbstractHashDict{K,V,O}
    slots::Array{Uint8,1}
    keys::Array{DK,1}
    vals::Array{V,1}
    ndel::Int
    count::Int
    hash::HashF
    derive::DeriveF

    function MultiHashDict(hash::HashF, derive::DeriveF)
        if !(O == Unordered)
            error("MultiHashDict does not currently supported ordered data")
        end
        n = 16
        new(zeros(Uint8,n), Array(DK,n), Array(V,n), 0, 0, hash, derive)
    end

    function call{K,V,O<:Union(Ordered,Unordered)}(::Type{MultiHashDict{K,V,O}},args...)
        MultiHashDict{K,V,O,DefaultHashF,CallableIdentity,K}(DefaultHashF(),CallableIdentity(),args...)
    end
end

immutable MultiHashLookup{K,V,O<:Union(Ordered,Unordered),HashF,DeriveF,DK}
    map::MultiHashDict{K,V,O,HashF,DeriveF,DK}
    derived_key::DK
    start_index::Int
end

const SMHashDict = Union(HashDict,MultiHashDict)

call{K,V}(::Type{MultiHashDict{K,V}}) = MultiHashDict{K,V,Unordered}()

call{T<:AbstractHashDict}(::Type{T}) = T{Any,Any,Unordered}()

HashDict{K,V}(ks::AbstractArray{K}, vs::AbstractArray{V}) = HashDict{K,V,Unordered}(ks,vs)
HashDict(ks, vs) = HashDict{Any,Any,Unordered}(ks, vs)
HashDict{K,V}(kv::AbstractArray{(K,V)}) = HashDict{K,V,Unordered}(kv)
if VERSION >= v"0.4.0-dev+980"
    HashDict{K,V}(ps::Pair{K,V}...) = HashDict{K,V,Unordered}(ps...)
end

# TODO: these could be more efficient
HashDict{K,V,O}(d::HashDict{K,V,O}) = HashDict{K,V,O}(collect(kv))
HashDict{K,V}(d::Associative{K,V}) = HashDict{K,V,Unordered}(collect(d))

similar{K,V,O}(d::HashDict{K,V,O}) = HashDict{K,V,O}()

function serialize(s, t::HashDict)
    serialize_type(s, typeof(t))
    write(s, int32(length(t)))
    for (k,v) in t
        serialize(s, k)
        serialize(s, v)
    end
    serialize(s, t.hash)
    serialize(s, t.derive)
end

function deserialize{K,V,O,HashF,DeriveF}(s, T::Type{HashDict{K,V,O,HashF,DeriveF}})
    n = read(s, Int32)
    t = T(); sizehint(t, n)
    for i = 1:n
        k = deserialize(s)
        v = deserialize(s)
        t[k] = v
    end
    t.hash = deserialize(s)
    t.derive = deserialize(s)
    return t
end

nextind(h::SMHashDict, ind, sz=length(h.slots)) = (ind & (sz-1)) + 1

hashindex(h::Union(HashDict, MultiHashDict), key, sz) = ((h.hash(key) & (sz-1)) + 1) % Int
rehash_item{K,V,O,HashF}(h::HashDict{K,V,O,HashF,CallableIdentity,K}, k, v, sz) = hashindex(h, k, sz)
rehash_item{K,V,O,HashF,DeriveF}(h::HashDict{K,V,O,HashF,DeriveF}, k, v, sz) = error("Must implement rehash_item if DeriveF is not the identity")

isslotempty(h::SMHashDict, i::Integer, slots = h.slots) = slots[i] == 0x0
isslotfilled(h::HashDict, i::Integer, slots = h.slots) = slots[i] == 0x1
isslotfilled(h::MultiHashDict, i::Integer, slots = h.slots) = (slots[i] == 0x1) || (slots[i] == 0x3) || (slots[i] == 0x4)
isslotmissing(h::SMHashDict, i::Integer, slots = h.slots) = slots[i] == 0x2
isslotcontinuation(h::SMHashDict, i::Integer, slots = h.slots) = slots[i] == 0x3

# An internal rehash function to be used by other data structures
# that contain a HashDict internally, but need to do rehashing differently

function _rehash(containing,h::HashDict, newsz)
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

    slots = zeros(Uint8,newsz)
    keys = Array(eltype(oldk), newsz)
    vals = Array(eltype(oldv), newsz)
    count0 = h.count
    count = 0

    for i = 1:sz
        if olds[i] == 0x1
            k = oldk[i]
            v = oldv[i]
            index = rehash_item(containing, k, v, newsz)
            while slots[index] != 0
                index = nextind(h,index,newsz)
            end
            slots[index] = 0x1
            keys[index] = k
            vals[index] = v
            count += 1

            if h.count != count0
                # if items are removed by finalizers, retry
                return _rehash(containing, h, newsz)
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

function _rehash(containing,h::MultiHashDict, newsz)
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

    slots = zeros(Uint8,newsz)
    keys = Array(eltype(oldk), newsz)
    vals = Array(eltype(oldv), newsz)
    count0 = h.count
    count = 0

    for i = 1:sz
        if isslotfilled(h,i,olds)
            k = oldk[i]
            v = oldv[i]
            index = rehash_item(containing, k, v, newsz)
            last_index = 0
            while isslotfilled(h,index,slots)
                if isequal(keys[index],k)
                    last_index = index
                end
                index = nextind(h,index,newsz)
            end
            if last_index != 0
                slots[last_index] = 0x3
            end
            slots[index] = 0x1
            keys[index] = k
            vals[index] = v
            count += 1

            if h.count != count0
                # if items are removed by finalizers, retry
                return _rehash(containing, h, newsz)
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



function _rehash{K,V}(containing,h::HashDict{K,V,Ordered}, newsz)
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

    slots = zeros(Uint8,newsz)
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
            index = rehash_item(containing, k, v, newsz)
            while slots[index] != 0
                index = nextind(h, index, newsz)
            end
            slots[index] = 0x1
            keys[index] = k
            vals[index] = v
            idxs[index] = idx
            order[idx] = index
            count += 1

            if h.count != count0
                # if items are removed by finalizers, retry
                return _rehash(containing, h, newsz)
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

rehash(h::HashDict, newsz) = _rehash(h,h,newsz)
rehash(h::MultiHashDict, newsz) = _rehash(h,h,newsz)


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

function sizehint(d::Union(HashDict,MultiHashDict), newsz)
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

function empty!{K,V}(h::Union(HashDict{K,V},MultiHashDict{K,V}))
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

function __ht_keyindex(h::Union(HashDict, MultiHashDict), derived_key, index, maxprobe=0)
    sz = length(h.keys)
    iter = 0
    if maxprobe == 0
        maxprobe = max(16, sz>>6)
    end
    keys = h.keys
    while true
        if isslotempty(h,index)
            return -1
        end
        if !isslotmissing(h,index) && isequal(derived_key,keys[index])
            return index
        end

        index = (index & (sz-1)) + 1
        iter +=1
        iter > maxprobe && break
    end

    return 0
end

# get the index where a key is stored, or -1 if not present
function _ht_keyindex(containing, h::Union(HashDict, MultiHashDict),
        key, derived_key = h.derive(key), index = hashindex(h, key, length(h.keys)))
    idx = __ht_keyindex(h, derived_key, index)
    if idx == 0
        # Table full
        _rehash(containing, h, h.count > 64000 ? sz*2 : sz*4)
        return ht_keyindex(h,key,derived_key)
    end
    return idx
end

ht_keyindex(h::Union(HashDict, MultiHashDict), key, derived_key = h.derive(key)) =
    _ht_keyindex(h,h,key,derived_key)

# get the index where a key is stored, or -pos if not present
# and the key would be inserted at pos
# This version is for use by setindex! and get!
function _ht_keyindex2{K,V}(containing, h::HashDict{K,V}, key, derived_key = h.derive(key))
    sz = length(h.keys)

    if h.ndel >= ((3*sz)>>2) || h.count*3 > sz*2
        # > 3/4 deleted or > 2/3 full
        _rehash(containing, h, h.count > 64000 ? h.count*2 : h.count*4)
        sz = length(h.keys)  # rehash may resize the table at this point!
    end

    iter = 0
    maxprobe = max(16, sz>>6)
    index = hashindex(h, key, sz)
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
        elseif isequal(derived_key, keys[index])
            return index
        end

        index = (index & (sz-1)) + 1
        iter+=1
        iter > maxprobe && break
    end

    avail < 0 && return avail

    _rehash(containing, h, h.count > 64000 ? sz*2 : sz*4)

    return _ht_keyindex2(containing, h, key, derived_key)
end

function insert_item!{K,V}(containing, h::MultiHashDict{K,V}, key, value, derived_key = h.derive(key))
    sz = length(h.keys)

    if h.ndel >= ((3*sz)>>2) || h.count*3 > sz*2
        # > 3/4 deleted or > 2/3 full
        _rehash(containing, h, h.count > 64000 ? h.count*2 : h.count*4)
        sz = length(h.keys)  # rehash may resize the table at this point!
    end

    iter = 0
    maxprobe = max(16, sz>>6)
    index = hashindex(h, key, sz)
    avail = 0
    keys = h.keys
    last_index = 0

    while true
        if isslotempty(h,index)
            avail != 0 && return _setindex!(h, value, key, derived_key, avail, last_index)
            return _setindex!(h, value, key, derived_key, index, last_index)
        end

        if isslotmissing(h,index)
            if avail == 0
                # found an available slot, but need to keep scanning
                # in case "key" already exists in a later collided slot.
                avail = index
            end
        else
            if isequal(derived_key, keys[index])
                last_index = index
                if avail != 0
                    # Can just insert into the middle of the chain
                    return _setindex!(h, value, key, derived_key, avail, 0)
                end
            end
        end

        index = (index & (sz-1)) + 1
        iter+=1
        iter > maxprobe && break
    end

    _rehash(containing, h, h.count > 64000 ? sz*2 : sz*4)

    return insert_item!(containing, h, key, value, derived_key)
end
ht_keyindex2{K,V}(h::HashDict{K,V}, key, derived_key = h.derive(key)) =
    _ht_keyindex2(h,h,key,derived_key)

# MultiHashIterator Implementation
start(lookup::MultiHashLookup) = lookup.start_index
done(lookup::MultiHashLookup,index) = index == -1
function next(lookup::MultiHashLookup,index)
    if index == -1
        error("next called on a done iterator")
    end

    # We can't afford to rehash inside this iterator, because
    # we'd lose our place
    item = lookup.map.vals[index]
    newindex = __ht_keyindex(lookup.map,lookup.derived_key,
                             nextind(lookup.map,index),typemax(Uint64))
    (item,newindex)
end

function _setindex!(h::HashDict, v, key, derived_key, index)
    h.slots[index] = 0x1
    h.keys[index] = derived_key
    h.vals[index] = v
    h.count += 1
    return h
end

function _setindex!(h::MultiHashDict, v, key, derived_key, index, last_index)
    h.slots[index] = 0x1
    h.keys[index] = derived_key
    h.vals[index] = v
    if last_index != 0
        @assert !isslotmissing(h,last_index) && !isslotempty(h,last_index)
        h.slots[last_index] = 0x03
    end
    h.count += 1
    return h
end

function _setindex!{K,V}(h::HashDict{K,V,Ordered}, v, key, derived_key, index)
    h.slots[index] = 0x1
    h.keys[index] = derived_key
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

    derived_key = h.derive(key)
    index = ht_keyindex2(h, key, derived_key)

    if index > 0
        h.vals[index] = v
    else
        _setindex!(h, v, key, derived_key, -index)
    end

    return h
end

function get!{K,V}(h::HashDict{K,V}, key0, default)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end

    derived_key = h.derive(key)
    index = ht_keyindex2(h, key, derived_key)

    index > 0 && return h.vals[index]

    v = convert(V,  default)
    _setindex!(h, v, key, derived_key, -index)
    return v
end

function get!{K,V}(h::HashDict{K,V}, key0, default)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end

    derived_key = h.derive(key)
    index = ht_keyindex2(h, key, derived_key)

    index > 0 && return h.vals[index]

    v = convert(V,  default)
    _setindex!(h, v, key, derived_key, -index)
    return v
end

# TODO: this makes it challenging to have V<:Base.Callable
function get!{K,V,F<:Base.Callable}(h::HashDict{K,V}, key0, default::F)
    key = convert(K,key0)
    if !isequal(key,key0)
        error(key0, " is not a valid key for type ", K)
    end

    derived_key = h.derive(key)
    index = ht_keyindex2(h, key, derived_key)

    index > 0 && return h.vals[index]

    v = convert(V,  default())
    _setindex!(h, v, key, derived_key, -index)
    return v
end

function _push!(containing, h::MultiHashDict,p::Pair)
    key = p.first
    value = p.second
    derived_key = h.derive(key)
    insert_item!(containing, h, key, value, derived_key)
    return p.second
end
push!(h::MultiHashDict,p::Pair) = _push!(h,h,p)

function getindex{K,V}(h::HashDict{K,V}, key)
    index = ht_keyindex(h, key)
    return (index<0) ? throw(KeyError(key)) : h.vals[index]::V
end

function getindex(h::MultiHashDict, key)
    derived_key = h.derive(key)
    index = ht_keyindex(h,key,derived_key)
    MultiHashLookup(h,derived_key,int(index))
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
    ccall(:jl_arrayunset, Void, (Any, Uint), h.keys, index-1)
    ccall(:jl_arrayunset, Void, (Any, Uint), h.vals, index-1)
    h.ndel += 1
    h.count -= 1
    return h
end

function _delete!{K,V}(h::HashDict{K,V,Ordered}, index)
    h.slots[index] = 0x2
    ccall(:jl_arrayunset, Void, (Any, Uint), h.keys, index-1)
    ccall(:jl_arrayunset, Void, (Any, Uint), h.vals, index-1)
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
next(t::HashDict, i) = ((t.keys[i],t.vals[i]), skip_deleted(t,i+1))

done{K,V}(t::HashDict{K,V,Ordered}, i) = done(t.order, i)
next{K,V}(t::HashDict{K,V,Ordered}, i) = ((t.keys[t.order[i]],t.vals[t.order[i]]), skip_deleted(t,i+1))

isempty(t::Union(HashDict,MultiHashDict)) = (t.count == 0)
length(t::Union(HashDict,MultiHashDict)) = t.count

next(v::KeyIterator{HashDict}, i) = (v.dict.keys[i], skip_deleted(v.dict,i+1))
next(v::ValueIterator{HashDict}, i) = (v.dict.vals[i], skip_deleted(v.dict,i+1))

next{K,V}(v::KeyIterator{HashDict{K,V,Ordered}}, i) = (v.dict.keys[v.dict.order[i]], skip_deleted(v.dict,i+1))
next{K,V}(v::ValueIterator{HashDict{K,V,Ordered}}, i) = (v.dict.vals[v.dict.order[i]], skip_deleted(v.dict,i+1))
