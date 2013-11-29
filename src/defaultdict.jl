# Dictionary which returns (and sets) a default value for a requested item not
# already in to the dictionary

immutable DefaultDict{K,V,F,D<:Associative} <: Associative{K,V}
    default::F
    d::D

    DefaultDict(x::F, kv::AbstractArray{(K,V)}) = new(x, D{K,V}(kv))
    DefaultDict(x::F, d::DefaultDict) = DefaultDict(x, d.d)
    DefaultDict(x::F, d::D=D{K,V}()) = new(x, d)
    DefaultDict(x, ks, vs) = new(x, D{K,V}(ks,vs))
end

DefaultDict() = error("DefaultDict: no default specified")
DefaultDict(k,v) = error("DefaultDict: no default specified")

# TODO: these mimic similar Dict constructors, but may not be needed
DefaultDict{K,V,F}(default::F, ks::AbstractArray{K}, vs::AbstractArray{V}) = DefaultDict{K,V,F,Dict}(default,ks,vs)
DefaultDict{F}(default::F,ks,vs) = DefaultDict{Any,Any,F,Dict}(default, ks, vs)

# syntax entry points
DefaultDict{F}(default::F) = DefaultDict{Any,Any,F,Dict}(default)
DefaultDict{K,V,F}(::Type{K}, ::Type{V}, default::F) = DefaultDict{K,V,F,Dict}(default)
DefaultDict{K,V,F}(default::F, kv::AbstractArray{(K,V)}) = DefaultDict{K,V,F,Dict}(default, kv)
DefaultDict{F,D<:Associative}(default::F, d::D) = ((K,V)=eltype(d); DefaultDict{K,V,F,D}(default, d))

similar{K,V,F,D}(d::DefaultDict{K,V,F,D}) = DefaultDict{K,V,F,D}()

sizehint(d::DefaultDict) = sizehint(d.d)
empty!(d::DefaultDict) = empty!(d.d)
setindex!(d::DefaultDict, v, k) = setindex!(d.d, v, k)

# Note that getindex depends on the particular implementation of Dict in Base.
# If the Dict implementation changes, this may break.
# Also note that we hash twice here if the key is not in the dictionary: once
# when retrieving, and once when assigning.
function getindex{K,V,F<:Base.Callable}(d::DefaultDict{K,V,F}, key)
    index = Base.ht_keyindex(d.d, key)
    if index < 0
        d.d[key] = ret = convert(V, d.default())
        return ret::V
    end
    return d.d.vals[index]::V
end

function getindex{K,V}(d::DefaultDict{K,V}, key)
    index = Base.ht_keyindex(d.d, key)
    if index < 0
        d.d[key] = ret = convert(V, d.default)
        return ret::V
    end
    return d.d.vals[index]::V
end

get(d::DefaultDict, key, deflt) = get(d.d, key, deflt)

haskey(d::DefaultDict, key) = haskey(d.d, key)
in{T<:DefaultDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d)
getkey(d::DefaultDict, key, deflt) = getkey(d.d, key, deflt)

pop!(d::DefaultDict, key) = pop!(d.d, key)
delete!(d::DefaultDict, key) = delete!(d.d, key)

start(d::DefaultDict) = start(d.d)
done(d::DefaultDict, i) = done(d.d,i)
next(d::DefaultDict, i) = next(d.d,i)

isempty(d::DefaultDict) = isempty(d.d)
length(d::DefaultDict) = length(d.d)

next{T<:DefaultDict}(v::Base.KeyIterator{T}, i) = (v.dict.d.keys[i], Base.skip_deleted(v.dict.d,i+1))
next{T<:DefaultDict}(v::Base.ValueIterator{T}, i) = (v.dict.d.vals[i], Base.skip_deleted(v.dict.d,i+1))

