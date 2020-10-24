#  multi-value dictionary (multidict)

using Base.Iterators: flatten, repeated

# Internal helper inner constructor for MultiSet
function _multidict_from_dict end

struct MultiDict{K,V} <: AbstractDict{K,V}
    d::Dict{K,MultiSet{V}}

    @__MODULE__()._multidict_from_dict(d::Dict{K,MultiSet{V}}) where {K,V} = new{K,V}(d)
end
MultiDict{K,V}() where {K,V} = _multidict_from_dict(Dict{K,MultiSet{V}}())
MultiDict{K,V}(d::MultiDict{K,V}) where {K,V} = _multidict_from_dict(copy(d.d))

MultiDict{K,V}(pairs::Pair...) where {K,V} = MultiDict{K,V}(pairs)
function MultiDict{K,V}(kvs) where {K,V}
    md = MultiDict{K,V}()
    sizehint!(md.d, length(kvs))  # This might be an overestimate, but :shrug:
    for (k,v) in kvs
        insert!(md, k, v)
    end
    return md
end

MultiDict() = MultiDict{Any,Any}()
MultiDict(kv::Tuple{}) = MultiDict()
MultiDict(d::Dict{K,<:AbstractVector{V}}) where {K,V} = MultiDict{K,V}(d)
MultiDict(ps::Pair...) = MultiDict(ps)
MultiDict(kvs) = multi_dict_with_eltype(kvs, eltype(kvs))

TP = Base.TP  # Tuple and/or Pair

multi_dict_with_eltype(kvs, ::TP{K,V}) where {K,V} = MultiDict{K,V}(kvs)
multi_dict_with_eltype(kvs, ::Type) = Base.grow_to!(multi_dict_with_eltype(Base.@default_eltype(typeof(kvs))), kvs)
multi_dict_with_eltype(::TP{K,V}) where {K,V} = MultiDict{K,V}()
multi_dict_with_eltype(::Type) = MultiDict{Any,Any}()
multi_dict_with_eltype(kv::Base.Generator, ::TP{K,V}) where {K,V} = MultiDict{K, V}(kv)
function multi_dict_with_eltype(kv::Base.Generator, ::Type)
    T = Base.@default_eltype(kv)
    if T <: Union{Pair, Tuple{Any, Any}} && isconcretetype(T)
        return multi_dict_with_eltype(kv, T)
    end
    return Base.grow_to!(multi_dict_with_eltype(T), kv)
end

MultiDict(kv::AbstractArray{Pair{K,V}}) where {K,V}  = MultiDict(kv...)
MultiDict(ps::Pair{K,V}...) where {K,V}  = MultiDict{K,V}(ps)

# Copy constructors
MultiDict{K,V}(md::MultiDict) where {K,V} = MultiDict(md.d)
MultiDict(md::MultiDict) = MultiDict(md.d)


## Functions

## Most functions are simply delegated to the wrapped Dict

@delegate MultiDict.d [ Base.haskey, Base.get, Base.getkey,
                        Base.getindex, Base.isempty, ]

Base.sizehint!(d::MultiDict, sz::Integer) = (sizehint!(d.d, sz); d)
Base.copy(d::MultiDict) = MultiDict(d)
Base.empty(d::MultiDict{K,V}) where {K,V} = MultiDict{K,V}()
Base.empty(a::MultiDict, ::Type{K}, ::Type{V}) where {K, V} = MultiDict{K, V}()
Base.:(==)(d1::MultiDict, d2::MultiDict) = d1.d == d2.d
Base.empty!(d::MultiDict) = (empty!(d.d); d)

function Base.insert!(d::MultiDict{K,V}, k, v) where {K,V}
    vs = get!(d.d, k, MultiSet{V}())
    insert!(vs, v)
    return d
end

# Delete all pairs starting with a given key.
Base.delete!(d::MultiDict, key) = (delete!(d.d, key); d)
# Delete a single pair key=>val from the dict.
function Base.delete!(d::MultiDict, key, val)
    vs = get(d.d, key, Base.secret_table_token)
    if vs !== Base.secret_table_token
        delete!(vs, val)
    end
    isempty(vs) && delete!(d, key)
    return d
end

function Base.in(pr::Pair, d::MultiDict{K,V}) where {K,V}
    k = convert(K, pr[1])
    vs = get(d.d, k, Base.secret_table_token)
    (vs !== Base.secret_table_token) && (pr[2] in vs)
end

Base.length(md::MultiDict) = length(keys(md.d)) == 0 ? 0 : sum(length(vs) for (_,vs) in md.d)

Base.eltype(::MultiDict{K,V}) where {K,V} = Pair{K,V}
function Base.iterate(md::MultiDict)
    i = iterate(md.d)
    if i === nothing
        return nothing
    end
    ((k,vs), state) = i
    (v, vstate) = iterate(vs)  # Should be non-empty
    return (k=>v, (k, state, vs, vstate))
end
function Base.iterate(md::MultiDict, md_state)
    (k, state, vs, vstate) = md_state
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
    return (k=>v, (k, state, vs, vstate))
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
function Base.pop!(md::MultiDict)
    isempty(md) && throw(ArgumentError("multidict must be non-empty"))
    (k,v) = first(md)
    delete!(md, k, v)
    return k=>v
end

Base.push!(d::MultiDict, kv::Pair) = (insert!(d, kv[1], kv[2]); d)

Base.size(d::MultiDict) = (length(keys(d)), count(d::MultiDict))

# grow_to! copied from Base -- needed for abstract generator constructor
function Base.grow_to!(dest::MultiDict{K, V}, itr) where V where K
    y = iterate(itr)
    y === nothing && return dest
    ((k, v), st) = y
    dest2 = empty(dest, typeof(k), typeof(v))
    insert!(dest2, k, v)
    Base.grow_to!(dest2, itr, st)
end
# grow_to! copied from Base -- needed for abstract generator constructor
# this is a special case due to (1) allowing both Pairs and Tuples as elements,
# and (2) Pair being invariant. a bit annoying.
function Base.grow_to!(dest::MultiDict{K,V}, itr, st) where V where K
    y = iterate(itr, st)
    while y !== nothing
        (k, v), st = y
        if isa(k, K) && isa(v, V)
            insert!(dest, k, v)
        else
            new_md = empty(dest, promote_typejoin(K,typeof(k)), promote_typejoin(V,typeof(v)))
            merge!(new_md, dest)
            insert!(new_md, k, v)
            return grow_to!(new_md, itr, st)
        end
        y = iterate(itr, st)
    end
    return dest
end

function Base.merge!(md::MultiDict, others::MultiDict...)
    for other in others
        for (k,vs) in other
            for v in vs
                insert!(md, k, v)
            end
        end
    end
    return md
end
