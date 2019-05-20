import Base: setindex!, sizehint!, empty!, isempty, length, getindex, getkey, haskey, iterate, @propagate_inbounds, pop!, delete!, get, isbitstype 

const LOAD_FACTOR = 0.80

mutable struct RobinDict{K,V} <: AbstractDict{K,V}
    #there is no need to maintain an table_size as an additional variable
    slots::Array{UInt8,1} # indicator, to be used later on
    keys::Array{K,1}
    vals::Array{V,1}
    dibs::Array{Int,1} # distance to initial bucket - critical for implementation
    count::Int
    totalcost::Int
    maxprobe::Int    # length of longest probe
    idxfloor::Int

    function RobinDict{K, V}() where {K, V}
        n = 16 # default size of an empty Dict in Julia
        new(zeros(UInt, n), Vector{K}(undef, n), Vector{V}(undef, n), zeros(Int, n), 0, 0, 0, 0)
    end

    function RobinDict{K, V}(d::RobinDict{K, V}) where {K, V}
        new(copy(d.slots), copy(d.keys), copy(d.vals), copy(d.dibs), d.count, d.totalcost, d.maxprobe, d.idxfloor)
    end

    function RobinDict{K, V}(slots, keys, vals, dibs, count, totalcost, maxprobe, idxfloor) where {K, V}
        new(slots, keys, dibs, vals, count, totalcost, maxprobe, idxfloor)
    end
end

function RobinDict{K,V}(kv) where {K, V}
    h = RobinDict{K,V}()
    for (k,v) in kv
        h[k] = v
    end
    h
end
RobinDict{K,V}(p::Pair) where {K,V} = setindex!(RobinDict{K,V}(), p.second, p.first)
function RobinDict{K,V}(ps::Pair...) where {K, V}
    h = RobinDict{K,V}()
    sizehint!(h, length(ps))
    for p in ps
        h[p.first] = p.second
    end
    return h
end

RobinDict() = RobinDict{Any,Any}()
RobinDict(kv::Tuple{}) = RobinDict()

RobinDict(ps::Pair{K,V}...) where {K,V} = RobinDict{K,V}(ps)
RobinDict(ps::Pair...) = RobinDict(ps)

# default hashing scheme used by Julia
hashindex(key, sz) = (((hash(key)%Int) & (sz-1)) + 1)::Int

_tablesz(x::Integer) = x < 16 ? 16 : one(x)<<((sizeof(x)<<3)-leading_zeros(x-1))

# insert algorithm
function rh_insert!(h::RobinDict{K, V}, key::K, val::V) where {K, V}
    # table full
    if h.count == length(h.keys)
        return -1
    end
    ckey, cval, cdibs = key, val, 0
    sz = length(h.keys)
    index = hashindex(ckey, sz)
    @inbounds while true
    	if (h.slots[index] == 0x0) || (h.slots[index] == 0x1 && h.keys[index] == ckey)
    		break
    	end
        if h.dibs[index] < cdibs
            h.vals[index], cval = cval, h.vals[index]
            h.keys[index], ckey = ckey, h.keys[index]
            h.maxprobe = max(h.maxprobe, cdibs)
            h.dibs[index], cdibs = cdibs, h.dibs[index]
        end
        cdibs += 1
        h.totalcost += 1
        index = (index & (sz - 1)) + 1
    end
    # println("Successfully inserted at $index")
    @inbounds if h.slots[index] == 0x0
    	h.count += 1
    end
    @inbounds h.slots[index] = 0x1
    @inbounds h.vals[index] = cval
    @inbounds h.keys[index] = ckey
    @inbounds h.dibs[index] = cdibs
    h.totalcost += 1
    h.maxprobe = max(h.maxprobe, cdibs)
    if h.idxfloor == 0
        h.idxfloor = index
    else
        h.idxfloor = min(h.idxfloor, index)
    end
    return index
end

#rehash! algorithm
function rehash!(h::RobinDict{K,V}, newsz = length(h.keys)) where {K, V}
    olds = h.slots
    oldk = h.keys
    oldv = h.vals
    oldd = h.dibs
    sz = length(olds)
    newsz = _tablesz(newsz)
    h.totalcost += 1
    h.idxfloor = 1
    if h.count == 0
        resize!(h.slots, newsz)
        fill!(h.slots, 0)
        resize!(h.keys, sz)
        resize!(h.vals, sz)
        resize!(h.dibs, sz)
        h.count = 0
        h.maxprobe = 0
        h.totalcost = 0
        h.idxfloor = 0
        return h
    end

    slots = zeros(UInt8,newsz)
    keys = Vector{K}(undef, newsz)
    vals = Vector{V}(undef, newsz)
    dibs = Vector{Int}(undef, newsz)
    fill!(dibs, 0)
    totalcost0 = h.totalcost
    count = 0
    maxprobe = 0

    for i = 1:sz
        @inbounds if olds[i] == 0x1
            k = oldk[i]
            v = oldv[i]
            d = dibs[i]
            index0 = index = hashindex(k, newsz)
            while slots[index] != 0
                index = (index & (newsz-1)) + 1
            end
            probe = (index - index0) & (newsz-1)
            probe > maxprobe && (maxprobe = probe)
            slots[index] = 0x1
            keys[index] = k
            vals[index] = v
            dibs[index] = d
            count += 1

            if h.totalcost != totalcost0
                # if `h` is changed by a finalizer, retry
                return rehash!(h, newsz)
            end
        end
    end

    h.slots = slots
    h.keys = keys
    h.vals = vals
    h.count = count
    h.maxprobe = maxprobe
    @assert h.totalcost == totalcost0
    return h
end

function sizehint!(d::IdDict, newsz)
    newsz = _tablesz(newsz*2)  # *2 for keys and values in same array
    oldsz = length(d.ht)
    # grow at least 25%
    if newsz < (oldsz*5)>>2
        return d
    end
    rehash!(d, newsz)
end

@propagate_inbounds isslotempty(h::RobinDict{K, V}, i) where {K, V} = h.slots[i] == 0x0
@propagate_inbounds isslotfilled(h::RobinDict{K, V}, i) where {K, V} = h.slots[i] == 0x1
@propagate_inbounds isslotdeleted(h::RobinDict{K, V}, i) where {K, V} = h.slots[i] == 0x2

function setindex!(h::RobinDict{K,V}, v0, key0) where {K, V}
    key = convert(K, key0)
    isequal(key, key0) || throw(ArgumentError("$key0 is not a valid key for type $K"))
    _setindex!(h, key, v0)
end

function _setindex!(h::RobinDict{K,V}, key::K, v0) where {K, V}
    v = convert(V, v0)
    sz = length(h.keys)
    (h.count > LOAD_FACTOR * sz) && rehash!(h, h.count > 64000 ? h.count*2 : h.count*4)
    index = rh_insert!(h, key, v)
    @assert index > 0
    h
end

isempty(d::RobinDict) = (d.count == 0)
length(d::RobinDict) = d.count

function empty!(h::RobinDict{K,V}) where {K, V}
    fill!(h.slots, 0x0)
    sz = length(h.slots)
    empty!(h.dibs)
    empty!(h.keys)
    empty!(h.vals)
    resize!(h.keys, sz)
    resize!(h.vals, sz)
    resize!(h.dibs, sz)
    h.count = 0
    h.maxprobe = 0
    h.totalcost = 0
    h.idxfloor = 0
    return h
end
 
function rh_search(h::RobinDict{K, V}, key::K) where {K, V}
	sz = length(h.keys)
	index = hashindex(key, sz)
	cdibs = 0
	while true
		if h.slots[index] == 0x0
			return -1
		elseif cdibs > h.dibs[index]
			return -1
		elseif h.keys[index] == key 
			return index
		end
		index = (index & (sz - 1)) + 1
		cdibs += 1
	end
end

function getindex(h::RobinDict{K, V}, key0) where {K, V}
	key = convert(K, key0)
	index = rh_search(h, key)
	@inbounds return (index < 0) ? throw(KeyError(key)) : h.vals[index]
end

# function get(default::Callable, h::RobinDict{K,V}, key) where {K, V}
#     index = rh_search(h, key)
#     @inbounds return (index < 0) ? default() : h.vals[index]::V
# end

haskey(h::RobinDict, key) = (rh_search(h, key) > 0) 
# in(key, v::KeySet{<:Any, <:RobinDict}) = (rh_search(v.dict, key) >= 0)

function getkey(h::RobinDict{K,V}, key, default) where {K, V}
    index = rh_search(h, key)
    @inbounds return (index < 0) ? default : h.keys[index]::K
end

function skip_deleted(h::RobinDict, i)
    L = length(h.slots)
    for i = i:L
        @inbounds if isslotfilled(h,i)
            return  i
        end
    end
    return 0
end

function rh_delete!(h::RobinDict{K, V}, index) where {K, V}
    if index < 0
        return false;
    else
        @inbounds h.slots[index] = 0x2
        isbitstype(K) || ccall(:jl_arrayunset, Cvoid, (Any, UInt), h.keys, index-1)
        isbitstype(V) || ccall(:jl_arrayunset, Cvoid, (Any, UInt), h.vals, index-1)
        h.count -= 1
        return true
    end
end

function _pop!(h::RobinDict, index)
    @inbounds val = h.vals[index]
    rh_delete!(h, index)
    return val
end

function pop!(h::RobinDict{K, V}, key::K) where {K, V}
    index = rh_search(h, key)
    return index > 0 ? _pop!(h, index) : throw(KeyError(key))
end

function pop!(h::RobinDict{K, V}, key::K, default) where {K, V}
    index = rh_search(h, key)
    return index > 0 ? _pop!(h, index) : default
end

function pop!(h::RobinDict)
    isempty(h) && throw(ArgumentError("dict must be non-empty"))
    idx = skip_deleted_floor!(h)
    @inbounds key = h.keys[idx]
    @inbounds val = h.vals[idx]
    rh_delete!(h, idx)
    key => val
end

function delete!(h::RobinDict{K, V}, key::K) where {K, V}
    index = rh_search(h, key)
    if index > 0
        rh_delete!(h, index)
    end
    return h
end

function skip_deleted_floor!(h::RobinDict)
    idx = skip_deleted(h, h.idxfloor)
    if idx != 0
        h.idxfloor = idx
    end
    idx
end

@propagate_inbounds _iterate(t::RobinDict{K,V}, i) where {K,V} = i == 0 ? nothing : (Pair{K,V}(t.keys[i],t.vals[i]), i == typemax(Int) ? 0 : i+1)
@propagate_inbounds function iterate(t::RobinDict)
    _iterate(t, skip_deleted_floor!(t))
end
@propagate_inbounds iterate(t::RobinDict, i) = _iterate(t, skip_deleted(t, i))
