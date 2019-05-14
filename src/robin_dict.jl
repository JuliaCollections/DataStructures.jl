import Base: setindex!, sizehint!, empty!, isempty, length, getindex

const LOAD_FACTOR = 0.90

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
RobinDict{K,V}(p::Pair) where {K,V} = setindex!(Dict{K,V}(), p.second, p.first)
function RobinDict{K,V}(ps::Pair...) where {K, V}
    h = RobinDict{K,V}()
#     sizehint!(h, length(ps))
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

isslotempty(h::RobinDict{K, V}, i) where {K, V} = h.slots[i] == 0x0
isslotfilled(h::RobinDict{K, V}, i) where {K, V} = h.slots[i] == 0x1
isslotdeleted(h::RobinDict{K, V}, i) where {K, V} = h.slots[i] == 0x2

function setindex!(h::RobinDict{K,V}, v0, key0) where {K, V}
    key = convert(K, key0)
    isequal(key, key0) || throw(ArgumentError("$key0 is not a valid key for type $K"))
    _setindex!(h, key, v0)
end

function _setindex!(h::RobinDict{K,V}, key::K, v0) where {K, V}
    v = convert(V, v0)
    index = rh_insert!(h, key, v)
    if index > 0
        println("Successfully inserted at $index")
    else
        throw(error("Dictionary table full"))
    end
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


