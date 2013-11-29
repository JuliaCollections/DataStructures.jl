# Dictionary which returns (and sets) a default value for a requested item not
# already in to the dictionary

type DefaultDict{K,V,F} <: Associative{K,V}
    d::Dict{K,V}
    default::F

    DefaultDict(x::F) = new(Dict{K,V}(), x)
    DefaultDict(kv::AbstractArray{(K,V)}, x::F) = new(Dict{K,V}(kv), x)
    DefaultDict(ks, vs, x) = new(Dict{K,V}(ks,vs), x)
end

DefaultDict() = error("DefaultDict: no default specified")
DefaultDict(k,v) = error("DefaultDict: no default specified")

DefaultDict{K,V,F}(ks::AbstractArray{K}, vs::AbstractArray{V}, default::F) = DefaultDict{K,V,F}(ks,vs,default)
DefaultDict{F}(ks,vs,default::F) = DefaultDict{Any,Any,F}(ks, vs, default)


# syntax entry points
DefaultDict{F}(default::F) = DefaultDict{Any,Any,F}(default)
DefaultDict{K,V,F}(::Type{K}, ::Type{V}, default::F) = DefaultDict{K,V,F}(default)
DefaultDict{K,V,F}(kv::AbstractArray{(K,V)}, default::F) = DefaultDict{K,V,F}

similar{K,V,F}(d::DefaultDict{K,V,F}) = DefaultDict{K,V,F}()

sizehint(d::DefaultDict) = sizehint(d.d)
empty!(d::DefaultDict) = empty!(d.d)
setindex!(d::DefaultDict, v, k) = setindex!(d.d, v, k)

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

haskey(d::DefaultDict, key) = haskey(d, key)
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

