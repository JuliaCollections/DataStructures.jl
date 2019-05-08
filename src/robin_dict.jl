
 import Base: setindex!, sizehint!, empty!

mutable struct RobinDict{K,V} <: AbstractDict{K,V}
    #there is no need to maintain an table_size as an additional variable
    slots::Array{UInt8,1} # indicator, to be used later on
    keys::Array{K,1}
    vals::Array{V,1}
    dibs::Array{Int,1} # distance to initial bucket - critical for implementation
    count::Int
    totalcost::Int
    maxprobe::Int    # length of longest probe
    
    function RobinDict{K, V}() where {K, V}
        n = 16 # default size of an empty Dict in Julia
        new(zeros(UInt, n), Vector{K}(undef, n), Vector{V}(undef, n), 0, 0, 0)
    end

    function RobinDict{K, V}(d::RobinDict{K, V}) where {K, V}
        new(copy(d.slots), copy(d.keys), copy(d.vals), d.count, d.totalcost, d.maxprobe)
    end
    
    function RobinDict{K, V}(slots, keys, vals, count, totalcost, maxprobe) where {K, V}
        new(slots, keys, vals, count, totalcost, maxprobe)
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

# default hashing scheme used by Julia
hashindex(key, sz) = (((hash(key)%Int) & (sz-1)) + 1)::Int

# insert algorithm 
function rh_insert!(h::RobinDict{K, V}, key) where {K, V}
    # table full
    if h.count == length(h.keys) 
        return -1
    end
    
    sz = length(h.keys)
    index = hashkey(key, ) # this is going to be critical
    # understand and then implement, task for tomorrow
end
    
function setindex!(h::RobinDict{K,V}, v0, key0) where {K, V}
    key = convert(K, key0)
    isequal(key, key0) || throw(ArgumentError("$key0 is not a valid key for type $K"))
    setindex!(h, v0, key)
end

function setindex!(h::Dict{K,V}, v0, key::K) where {K, V}
    v = convert(V, v0)
    index = rh_insert!(h, key)
    if index > 0
        @inbounds h.keys[index] = key
        @inbounds h.vals[index] = v
    else
        throw(error("Dictionary table full"))
    end
    h
end




