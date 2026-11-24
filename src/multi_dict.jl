#  multi-value dictionary (multidict)

using Base.Iterators: flatten, repeated

struct MultiDict{K,V}
    d::Dict{K,Vector{V}}

    MultiDict{K,V}() where {K,V} = new{K,V}(Dict{K,Vector{V}}())
    MultiDict{K,V}(kvs) where {K,V} = new{K,V}(Dict{K,Vector{V}}(kvs))
    MultiDict{K,V}(ps::Pair{K,Vector{V}}...) where {K,V} = new{K,V}(Dict{K,Vector{V}}(ps...))
end

MultiDict() = MultiDict{Any,Any}()
MultiDict(kv::Tuple{}) = MultiDict()
MultiDict(kvs) = multi_dict_with_eltype(kvs, eltype(kvs))

multi_dict_with_eltype(kvs, ::Type{Tuple{K,Vector{V}}}) where {K,V} = MultiDict{K,V}(kvs)
function multi_dict_with_eltype(kvs, ::Type{Tuple{K,V}}) where {K,V}
    md = MultiDict{K,V}()
    for (k,v) in kvs
        insert!(md, k, v)
    end
    return md
end
multi_dict_with_eltype(kvs, t) = MultiDict{Any,Any}(kvs)


MultiDict(kv::AbstractArray{Pair{K,V}}) where {K,V}  = MultiDict(kv...)
function MultiDict(ps::Pair{K,V}...) where {K,V}
    md = MultiDict{K,V}()
    for (k,v) in ps
        insert!(md, k, v)
    end
    return md
end

## Functions

## Most functions are simply delegated to the wrapped Dict

@delegate MultiDict.d [ Base.haskey, Base.get, Base.get!, Base.getkey,
                        Base.getindex, Base.isempty, ]

Base.sizehint!(d::MultiDict, sz::Integer) = (sizehint!(d.d, sz); d)
Base.copy(d::MultiDict) = MultiDict(d)
Base.empty(d::MultiDict{K,V}) where {K,V} = MultiDict{K,V}()
Base.:(==)(d1::MultiDict, d2::MultiDict) = d1.d == d2.d
Base.delete!(d::MultiDict, key) = (delete!(d.d, key); d)
Base.empty!(d::MultiDict) = (empty!(d.d); d)

function Base.insert!(d::MultiDict{K,V}, k, v) where {K,V}
    if !haskey(d.d, k)
        d.d[k] = V[]
    end
    push!(d.d[k], v)
    return d
end

function Base.in(pr::(Tuple{Any,Any}), d::MultiDict{K,V}) where {K,V}
    k = convert(K, pr[1])
    v = get(d,k,Base.secret_table_token)
    (v !== Base.secret_table_token) && (pr[2] in v)
end

# TODO: For efficiency, we probably want a MultiKeySet to correspond to Dict's KeySet
#       Instead, we currently return this Generator / Iterator.
# EDIT: What value would MultiKeySet provide over the iterator we get via `flatten()`?
function Base.keys(md::MultiDict)
    flatten((repeated(k, length(vs)) for (k,vs) in md.d))
end
Base.length(md::MultiDict) = sum(length(vs) for (_,vs) in md.d)
# TODO: Should this return (something like?) a ValueIterator? ValueIterator itself
# currently requires its dict to be <: AbstractDict, but we could create something similar.
# What does it provide that this `flatten()` iterator / generator doesn't?
function Base.values(md::MultiDict)
    flatten(vs for (_,vs) in md.d)
end

Base.eltype(md::MultiDict{K,V}) where {K,V} = Pair{K,V}
function Base.iterate(md::MultiDict)
    i = iterate(md.d)
    if i === nothing
        return nothing
    end
    ((k,vs), state) = i
    (v, vstate) = iterate(vs)  # Should be non-empty
    return (k=>v, (state, ((k,vs), vstate)))
end
function Base.iterate(md::MultiDict, md_state)
    state, ((k,vs), vstate) = md_state
    i = iterate(vs, vstate)
    if i === nothing
        # Finished iterating vs, move on to the next key
        i = iterate(md.d, state)
        if i === nothing
            return nothing
        end
        ((k,vs), state) = i
        (v, vstate) = iterate(vs)  # Should be non-empty
    else
        (v, vstate) = i
    end
    return (k=>v, (state, ((k,vs), vstate)))
end

function Base.pop!(d::MultiDict, key, default)
    vs = get(d, key, Base.secret_table_token)
    if vs === Base.secret_table_token
        if default !== Base.secret_table_token
            return default
        else
            throw(KeyError(key))
        end
    end
    v = pop!(vs)
    (length(vs) == 0) && delete!(d, key)
    return v
end
Base.pop!(d::MultiDict, key) = pop!(d, key, Base.secret_table_token)

Base.push!(d::MultiDict, kv::Pair) = insert!(d, kv[1], kv[2])
#Base.push!(d::MultiDict, kv::Pair, kv2::Pair) = (push!(d.d, kv, kv2); d)
#Base.push!(d::MultiDict, kv::Pair, kv2::Pair, kv3::Pair...) = (push!(d.d, kv, kv2, kv3...); d)

Base.push!(d::MultiDict, kv) = insert!(d, kv[1], kv[2])
#Base.push!(d::MultiDict, kv, kv2...) = (push!(d.d, kv, kv2...); d)

Base.count(d::MultiDict) = length(keys(d)) == 0 ? 0 : mapreduce(k -> length(d[k]), +, keys(d))
Base.size(d::MultiDict) = (length(keys(d)), count(d::MultiDict))

# enumerate

struct EnumerateAll
    d::MultiDict
end
enumerateall(d::MultiDict) = EnumerateAll(d)

Base.length(e::EnumerateAll) = count(e.d)

function Base.iterate(e::EnumerateAll)
    V = eltype(eltype(values(e.d)))
    vs = V[]
    dstate = iterate(e.d.d)
    vstate = iterate(vs)
    dstate === nothing || vstate === nothing && return nothing
    k = nothing
    while vstate === nothing
        ((k, vs), dst) = dstate
        dstate = iterate(e.d.d, dst)
        vstate = iterate(vs)
    end
    v, vst = vstate
    return ((k, v), (dstate, k, vs, vstate))
end

function Base.iterate(e::EnumerateAll, s)
    dstate, k, vs, vstate = s
    dstate === nothing || vstate === nothing && return nothing
    while vstate === nothing
        ((k, vs), dst) = dstate
        dstate = iterate(e.d.d, dst)
        vstate = iterate(vs)
    end
    v, vst = vstate
    return ((k, v), (dstate, k, vs, vstate))
end
