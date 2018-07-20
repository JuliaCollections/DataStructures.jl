# weak key dict using object-id hashing/equality

# Type to wrap a WeakRef to furbish it with objectid comparison and hashing.
struct WeakRefForWeakDict
    w::WeakRef
    WeakRefForWeakDict(wr::WeakRef) = new(wr)
end
WeakRefForWeakDict(val) = WeakRefForWeakDict(WeakRef(val))
Base.:(==)(wr1::WeakRefForWeakDict, wr2::WeakRefForWeakDict) = wr1.w.value===wr2.w.value
Base.hash(wr::WeakRefForWeakDict, h::UInt) = Base.hash_uint(3h - objectid(wr.w.value))

"""
    WeakKeyIdDict([itr])
`WeakKeyIdDict()` constructs a hash table where the keys are weak
references to objects, and thus may be garbage collected even when
referenced in a hash table.
See [`Dict`](@ref) for further help.
"""
mutable struct WeakKeyIdDict{K,V} <: AbstractDict{K,V}
    ht::Dict{WeakRefForWeakDict,V}
    lock::Threads.RecursiveSpinLock
    finalizer::Function

    # Constructors mirror Dict's
    function WeakKeyIdDict{K,V}() where V where K
        t = new(Dict{WeakRefForWeakDict,V}(), Threads.RecursiveSpinLock(), identity)
        t.finalizer = function (k)
            # when a weak key is finalized, remove from dictionary if it is still there
            if islocked(t)
                finalizer(t.finalizer, k)
                return nothing
            end
            delete!(t, k)
        end
        return t
    end
end
function WeakKeyIdDict{K,V}(kv) where V where K
    h = WeakKeyIdDict{K,V}()
    for (k,v) in kv
        h[k] = v
    end
    return h
end
WeakKeyIdDict{K,V}(p::Pair) where V where K = setindex!(WeakKeyIdDict{K,V}(), p.second, p.first)
function WeakKeyIdDict{K,V}(ps::Pair...) where V where K
    h = WeakKeyIdDict{K,V}()
    sizehint!(h, length(ps))
    for p in ps
        h[p.first] = p.second
    end
    return h
end
WeakKeyIdDict() = WeakKeyIdDict{Any,Any}()

WeakKeyIdDict(kv::Tuple{}) = WeakKeyIdDict()
Base.copy(d::WeakKeyIdDict) = WeakKeyIdDict(d)

WeakKeyIdDict(ps::Pair{K,V}...)           where {K,V} = WeakKeyIdDict{K,V}(ps)
WeakKeyIdDict(ps::Pair{K}...)             where {K}   = WeakKeyIdDict{K,Any}(ps)
WeakKeyIdDict(ps::(Pair{K,V} where K)...) where {V}   = WeakKeyIdDict{Any,V}(ps)
WeakKeyIdDict(ps::Pair...)                            = WeakKeyIdDict{Any,Any}(ps)

function WeakKeyIdDict(kv)
    try
        Base.dict_with_eltype((K, V) -> WeakKeyIdDict{K, V}, kv, eltype(kv))
    catch e
        if !Base.isiterable(typeof(kv)) || !all(x->isa(x,Union{Tuple,Pair}),kv)
            throw(ArgumentError("WeakKeyIdDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

Base.empty(d::WeakKeyIdDict, ::Type{K}, ::Type{V}) where {K, V} = WeakKeyIdDict{K, V}()

Base.islocked(wkh::WeakKeyIdDict) = islocked(wkh.lock)
Base.lock(f, wkh::WeakKeyIdDict) = lock(f, wkh.lock)
Base.trylock(f, wkh::WeakKeyIdDict) = trylock(f, wkh.lock)

function Base.setindex!(wkh::WeakKeyIdDict{K}, v, key) where K
    !isa(key, K) && throw(ArgumentError("$key is not a valid key for type $K"))
    finalizer(wkh.finalizer, key)
    lock(wkh) do
        wkh.ht[WeakRefForWeakDict(key)] = v
    end
    return wkh
end

function Base.getkey(wkh::WeakKeyIdDict{K}, kk, default) where K
    return lock(wkh) do
        k = getkey(wkh.ht, WeakRefForWeakDict(kk), secret_table_token)
        k === secret_table_token && return default
        return k.w.value::K
    end
end

Base.get(wkh::WeakKeyIdDict{K}, key, default) where {K} = lock(() -> get(wkh.ht, WeakRefForWeakDict(key), default), wkh)
Base.get(default::Base.Callable, wkh::WeakKeyIdDict{K}, key) where {K} = lock(() -> get(default, wkh.ht, WeakRefForWeakDict(key)), wkh)
Base.get!(wkh::WeakKeyIdDict{K}, key, default) where {K} = lock(() -> get!(wkh.ht, WeakRefForWeakDict(key), default), wkh)
Base.get!(default::Base.Callable, wkh::WeakKeyIdDict{K}, key) where {K} = lock(() -> get!(default, wkh.ht, WeakRefForWeakDict(key)), wkh)
Base.pop!(wkh::WeakKeyIdDict{K}, key) where {K} = lock(() -> pop!(wkh.ht, WeakRefForWeakDict(key)), wkh)
Base.pop!(wkh::WeakKeyIdDict{K}, key, default) where {K} = lock(() -> pop!(wkh.ht, WeakRefForWeakDict(key), default), wkh)
Base.delete!(wkh::WeakKeyIdDict, key) = lock(() -> delete!(wkh.ht, WeakRefForWeakDict(key)), wkh)
Base.empty!(wkh::WeakKeyIdDict) = (lock(() -> empty!(wkh.ht), wkh); wkh)
Base.haskey(wkh::WeakKeyIdDict{K}, key) where {K} = lock(() -> haskey(wkh.ht, WeakRefForWeakDict(key)), wkh)
Base.getindex(wkh::WeakKeyIdDict{K}, key) where {K} = lock(() -> getindex(wkh.ht, WeakRefForWeakDict(key)), wkh)
Base.isempty(wkh::WeakKeyIdDict) = isempty(wkh.ht)
Base.length(t::WeakKeyIdDict) = length(t.ht)

function Base.iterate(t::WeakKeyIdDict{K,V}) where V where K
    gc_token = Ref{Bool}(false) # no keys will be deleted via finalizers until this token is gc'd
    finalizer(gc_token) do r
        if r[]
            r[] = false
            unlock(t.lock)
        end
    end
    s = lock(t.lock)
    iterate(t, (gc_token,))
end
function Base.iterate(t::WeakKeyIdDict{K,V}, state) where V where K
    gc_token = first(state)
    y = iterate(t.ht, Base.tail(state)...)
    y === nothing && return nothing
    wkv, i = y
    kv = Pair{K,V}(wkv[1].w.value::K, wkv[2])
    return (kv, (gc_token, i))
end

Base.filter!(f, d::WeakKeyIdDict) = Base.filter_in_one_pass!(f, d)
