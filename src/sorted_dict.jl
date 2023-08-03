## A SortedDict is a wrapper around balancedTree with methods similar
## to those of Julia container Dict.

mutable struct SortedDict{K, D, Ord <: Ordering} <: AbstractDict{K,D}
    bt::BalancedTree23{K,D,Ord}
end


"""
    SortedDict{K,V,Ord}(o::Ord=Forward) where {K, V, Ord <: Ordering}
    SortedDict{K,V,Ord}(o::Ord, kv) where {K, V, Ord <: Ordering}

Construct a `SortedDict` with key type `K` and value type
`V` with `o` ordering from an iterable `kv`.  The iterable should
generate either `Pair{K,V}` or `Tuple{K,V}`.  If omitted, then
the SortedDict is initially empty.  Time: O(*cn* log *n*) where
*n* is the length of the iterable.
"""
SortedDict{K,D,Ord}(o::Ord=Forward) where {K, D, Ord <: Ordering} =
    SortedDict{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

function SortedDict{K,D,Ord}(o::Ord, kv) where {K, D, Ord <: Ordering}
    s = SortedDict{K,D,Ord}(BalancedTree23{K,D,Ord}(o))
    for (k, v) in kv
        s[k] = v
    end
    return s
end



"""
    SortedDict(o::Ord=Forward) where {Ord <: Ordering}
    SortedDict{K,V}(o::Ord=Forward) where {K,V,Ord<:Ordering}

Construct an empty `SortedDict` with key type `K` and value type
`V` with `o` ordering (default to forward ordering).  If
`K` and `V` are not specified as in the
first form, then they are assumed to both be `Any`.
Time: O(1)

**Note that a key type of `Any` or any other abstract type will lead
to slow performance, as the values are stored boxed (i.e., as
pointers), and insertion will require a run-time lookup of the
appropriate comparison function. It is recommended to always specify
a concrete key type, or to use one of the constructors in
which the key type is inferred.**
"""
SortedDict(o::Ord=Forward) where {Ord <: Ordering} = SortedDict{Any,Any,Ord}(o)
SortedDict{K,D}(o::Ord=Forward) where {K,D,Ord<:Ordering} =
    SortedDict{K,D,Ord}(o)



"""
    SortedDict(iter, o::Ord=Forward) where {Ord <: Ordering}
    SortedDict(o::Ordering, iter)
    SortedDict{K,V}(iter, o::Ordering=Forward) where {K,V}
    SortedDict{K,V}(o::Ordering, iter) where {K,V}

Construct a `SortedDict` from an arbitrary iterable object of
`key=>value` pairs or `(key,value)` tuples with order object `o`. The key type
and value type are inferred from the given iterable in the
first two forms.  The first two forms copy the
data three times, so
it is more efficient to explicitly specify `K` and `V` as in the
second two forms.  Time: O(*cn* log *n*)

"""
SortedDict(iter, o::Ord=Forward) where {Ord <: Ordering} =
    SortedDict(o, iter)

# TODO: figure out how to infer type without three copies

function SortedDict(o::Ordering, kv)
    c = collect(kv)
    if eltype(c) <: Pair
        c2 = collect((t.first, t.second) for t in c)
    elseif eltype(c) <: Tuple
        c2 = collect((t[1], t[2]) for t in c)
    else
        throw(ArgumentError("In SortedDict(o,kv), kv should contain either pairs or 2-tuples"))
    end
    SortedDict{eltype(c2).parameters[1], eltype(c2).parameters[2], typeof(o)}(o, c2)
end
SortedDict{K,D}(iter, o::Ordering=Forward) where {K, D} =
    SortedDict{K,D,typeof(o)}(o, iter)
SortedDict{K,D}(o::Ordering, iter) where {K, D} =
    SortedDict{K,D,typeof(o)}(o, iter)


"""
    SortedDict(ps::Pair...)
    SortedDict(o::Ordering, ps::Pair...)
    SortedDict{K,V}(ps::Pair...)
    SortedDict{K,V}(o::Ordering, ps::Pair...) where {K,V}

Construct a `SortedDict` from the given key-value pairs. 
The key type and value type are inferred from the
given key-value pairs in the first two forms.
The ordering is assumed to be `Forward`
ordering in the first and third form.  
The first two forms (where `K` and `V` are not specified
but inferred) involves copying the data three times 
and so is less efficient than the second two forms.
Time: O(*cn* log *n*)
"""
SortedDict(ps::Pair...) = SortedDict(Forward, ps)
SortedDict{K,D}(ps::Pair...) where {K,D} = SortedDict{K,D,ForwardOrdering}(Forward, ps)
SortedDict(o::Ordering, ps::Pair...) = SortedDict(o, ps)
SortedDict{K,D}(o::Ord, ps::Pair...) where {K,D,Ord<:Ordering} =
    SortedDict{K,D,Ord}(o, ps)



"""
    SortedDict{K,V}(::Val{true}, iterable) where {K, V}
    SortedDict{K,V}(::Val{true}, iterable, ord::Ordering) where {K,V}

Construct a `SortedDict` from an iterable whose eltype
is Tuple{K,V} or Pair{K,V} and that is already in sorted ordered. 
The first form assumes Forward ordering.  No duplicate
keys allowed.   Time: O(*cn*).
"""
SortedDict{K,D}(::Val{true}, iterable) where {K,D} =
    SortedDict{K,D}(Val(true), iterable, Forward)

function SortedDict{K,D}(::Val{true},
                         iterable,
                         ord::Ord) where {K,D,Ord <: Ordering}
    SortedDict{K, D, Ord}(BalancedTree23{K,D,Ord}(Val(true), iterable, ord, false))
end


## The following is needed to resolve ambiguities

SortedDict(::Ordering, ::Ordering) =
    throw(ArgumentError("Not a valid SortedDict constructor"))
SortedDict{K,D}(::Ordering, ::Ordering) where {K,D} =
    throw(ArgumentError("Not a valid SortedDict constructor"))
SortedDict(::Val{true}, ::Ordering) = throw(ArgumentError("Not a valid SortedDict constructor"))
SortedDict{K,D}(::Val{true}, ::Ordering) where {K,D} =
    throw(ArgumentError("Not a valid SortedDict constructor"))


"""
    Base.getindex(sd::SortedDict, k)

Retrieve the value associated with key `k` in SortedDict `sc`.
Yields a `KeyError` if `k` is not found.   The following
functions do not throw an error if the key is not found:
[`Base.get(sd::SortedDict,k,v)`](@ref) and
[`findkey(sd::SortedDict, k)`](@ref).
Time: O(*c* log *n*)
"""
@inline function Base.getindex(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    !exactfound && throw(KeyError(k_))
    @inbounds return m.bt.data[i].d
end


"""
    Base.setindex!(sd::SortedDict, newvalue, k)

Assign or
reassign the value associated with the key `k` to `newvalue`.  Note
that the key is also overwritten; this is not necessarily a no-op
since the equivalence in the sort-order does not imply equality.
See also [`push_return_semitoken!(sd::SortedDict, p::Pair)`](@ref).
Time: O(*c* log *n*)
"""
@inline function Base.setindex!(m::SortedDict, d_, k_)
    insert!(m.bt, convert(keytype(m),k_), convert(valtype(m),d_), false)
    return m
end


"""
    Base.push!(sd::SortedDict, p::Pair)

Insert key-value pair `p`, i.e., a `k=>v` pair, into `sd`.
If the key `k` is already present, this overwrites the old value. 
The key is also overwritten (not necessarily a no-op, since 
sort-order equivalence may differ from equality).
The return value is `sd`.   See also [`push_return_semitoken!(sd::SortedDict, p::Pair)`](@ref).
Time: O(*c* log *n*)
"""
@inline function Base.push!(m::SortedDict{K,D}, pr::Pair) where {K,D}
    insert!(m.bt, convert(K, pr[1]), convert(D, pr[2]), false)
    return m
end


"""
    DataStructures.findkey(sd::SortedDict, k)

Return the semitoken that 
points to the item whose key is
`k`, or past-end semitoken if `k` is absent. 
See also  [`Base.getindex(sd::SortedDict, k)`](@ref)
Time: O(*c* log *n*)
"""
@inline function findkey(m::SortedDict, k_)
    ll, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(exactfound ? ll : 2)
end


"""
    DataStructures.push_return_semitoken!(sd::SortedDict, p::Pair)

Insert pair `p` of the form `k=>v` into `sd`.
If the key is already present in `sd`, this
overwrites the old value. Note that the key is also overwritten,
which is not necessarily a no-op because equivalence in the sort
order does not necessarily imply equality.  Unlike `push!`,
the
return value is a 2-tuple whose first entry is boolean and indicates
whether the insertion was new (i.e., the key was not previously
present) and whose second entry is the semitoken of the new entry.
This function replaces the deprecated `insert!(sd,k,v)`.
 Time: O(*c* log *n*)
"""
@inline function push_return_semitoken!(m::SortedDict, pr::Pair)
    b, i = insert!(m.bt, convert(keytype(m), pr.first), convert(valtype(m), pr.second), false)
    b, IntSemiToken(i)
end




@inline Base.eltype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} =  Pair{K,D}
@inline Base.keytype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} = K
@inline Base.valtype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} = D

"""
    Base.in(p::Pair, sd::SortedDict)

Return true if `p` is in `sd`.  Here, `p` is a key=>value pair. 
Time: O(*c* log *n* + *d*) where *d* stands for the
time to compare two values.
"""
@inline function Base.in(pr::Pair, m::SortedDict)
    i, exactfound = findkey(m.bt,convert(keytype(m),pr[1]))
    return exactfound && isequal(m.bt.data[i].d, convert(valtype(m),pr[2]))
end


"""
    Base.get(sd::SortedDict,k,default)
    Base.get(default_f::Union{Function,Type}, sd::SortedDict, k)

Return the value associated with key `k` where `sd` is a
SortedDict, or else returns `default` if `k` is not in `sd`.  
The second form obtains `default` as the return argument of
the function/type-constructor `default_f` (with no arguments) 
when the key is not present.
Time: O(*c* log *n*)
"""
@inline function Base.get(m::SortedDict, k_, default_)
    get(()->default_, m, k_)
end


function Base.get(default_::Union{Function,Type}, m::SortedDict{K,D}, k_) where {K,D}
    i, exactfound = findkey(m.bt, convert(K, k_))
    return exactfound ? m.bt.data[i].d : default_()
end

Base.get(m::SortedDict, n::SortedDict, ::Any) =
    error("Ambiguous invocation of 'get'; please select the correct version using Base.invoke")


"""
    Base.get!(sd::SortedDict,k,default)
    Base.get!(default_f::Union{Function,Type}, sd::SortedDict, k)

Return the value associated with key `k` where `sd` is a
SortedDict, or else return `default` if `k` is not in `sd`, and in the
latter case, inserts `(k,default)` into `sd`. 
The
second form computes a default value by calling
the function `default_f` (with no arguments) or the constructor of
type `default_f` when the key is not present.
Time: O(*c* log *n*)
"""
Base.get!(m::SortedDict, k_, default_) = get!(()->default_, m, k_)

function Base.get!(default_::Union{Function,Type}, m::SortedDict{K,D}, k_) where {K,D}
    k = convert(K,k_)
    i, exactfound = findkey(m.bt, k)
    if exactfound
        return m.bt.data[i].d
    else
        default = convert(D, default_())
        insert!(m.bt,k, default, false)
        return default
    end
end



"""
    Base.getkey(sd::SortedDict,k,defaultk)

Return the key `k` where `sd` is a SortedDict, if `k` is in `sd` else
it returns `defaultk`. If the container uses in its ordering an `eq`
method different from isequal (e.g., case-insensitive ASCII strings
illustrated below), then the return value is the actual key stored
in the SortedDict that is equivalent to `k` according to the `eq`
method, which might not be equal to `k`. Similarly, if the user
performs an implicit conversion as part of the call (e.g., the
container has keys that are floats, but the `k` argument to `getkey`
is an Int), then the returned key is the actual stored key rather
than `k`. Time: O(*c* log *n*)
"""
function Base.getkey(m::SortedDict{K,D,Ord}, k_, default_) where {K,D,Ord <: Ordering}
    i, exactfound = findkey(m.bt, convert(K, k_))
    exactfound ? m.bt.data[i].k : default_
end

## Function delete! deletes an item at a given
## key
"""
    Base.delete!(sd::SortedDict, k)

Delete the item whose key is `k` in `sd`.
After this operation
is complete, any token addressing the deleted item is invalid.
Returns `sc`.  This is a no-op if `k` is not present in `sd`.
 Time: O(*c* log *n*)
"""
@inline function Base.delete!(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    if exactfound
        delete!(m.bt, i)
    end
    m
end

"""
    Base.pop!(sd::SortedDict, k)
    Base.pop!(sd::SortedDict, k, default)

Delete the item with key `k` in `sd` and
return the value that was associated with `k`.
If `k` is not in `sd`
return `default`, or throw a `KeyError` if `default` is not specified.
Time: O(*c* log *n*)
"""
@inline function Base.pop!(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    !exactfound && throw(KeyError(k_))
    @inbounds d = m.bt.data[i].d
    delete!(m.bt, i)
    return d
end

@inline function Base.pop!(m::SortedDict, k_, default)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    !exactfound && return default
    @inbounds d = m.bt.data[i].d
    delete!(m.bt, i)
    return d
end


"""
    Base.isequal(sd1::SortedDict{K,V,Ord}, sd2::SortedDict{K,V,Ord}) where {K, V, Ord <: Ordering}

Check if two SortedDicts are equal in the sense that they contain
the same items; the keys are compared using the `eq` method, while
the values are compared with the `isequal` function.  
Note that `isequal` in this sense does not imply correspondence
between semitokens for items in `sd1` with those for `sd2`.  
Time: O(*cn*). Note
that if `K`, `V`, `Ord`, or the
order objects of sd1 and sd2 are different, then a fallback routine
`Base.isequal(::AbstractDict, ::AbstractDict)` is invoked.
Time: O(*cn*)
"""
function Base.isequal(m1::SortedDict{K, D, Ord}, m2::SortedDict{K, D, Ord}) where
{K, D, Ord <: Ordering}

    ord = orderobject(m1)
    if ord != orderobject(m2)
        return invoke((==), Tuple{AbstractDict, AbstractDict}, m1, m2)
    end
    p1 = firstindex(m1)
    p2 = firstindex(m2)
    while true
        p1 == pastendsemitoken(m1) && return p2 == pastendsemitoken(m2)
        p2 == pastendsemitoken(m2) && return false
        @inbounds k1,d1 = deref((m1,p1))
        @inbounds k2,d2 = deref((m2,p2))
        (!eq(ord,k1,k2) || !isequal(d1,d2)) && return false
        @inbounds p1 = advance((m1,p1))
        @inbounds p2 = advance((m2,p2))
    end
end


function mergetwo!(m::SortedDict{K,D,Ord},
                   m2) where {K,D,Ord <: Ordering}
    for (k,v) in m2
        m[convert(K,k)] = convert(D,v)
    end
end

Base.copymutable(m::SortedDict) = packcopy(m)
Base.copy(m::SortedDict) = packcopy(m)

# See sorted_set for the docstrings for packcopy and packdeepcopy

function packcopy(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    SortedDict{K,D}(Val(true), m, orderobject(m))
end
function packdeepcopy(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    m2 = deepcopy(m)
    SortedDict{K,D}(Val(true), m2, orderobject(m))
end


struct MergeManySortedDicts{K, D, Ord <: Ordering}
    vec::Vector{SortedDict{K,D,Ord}}
end

function Base.iterate(sds::MergeManySortedDicts{K, D, Ord},
                      state = [firstindex(sds.vec[i]) for i=1:length(sds.vec)]) where
{K, D, Ord <: Ordering}
    ord = orderobject(sds.vec[1])
    firsti = 0
    N = length(sds.vec)
    for i = 1 : N
        if state[i] != pastendsemitoken(sds.vec[i])
            firsti = i
            break
        end
    end
    firsti == 0 && return nothing
    foundi = firsti
    @inbounds firstk = deref_key((sds.vec[firsti], state[firsti]))
    for i = firsti + 1 : N
        if state[i] != pastendsemitoken(sds.vec[i])
            @inbounds k2 = deref_key((sds.vec[i], state[i]))
            if !lt(ord, firstk, k2)
                foundi = i
                firstk = k2
            end
        end
    end
    foundsemitoken = state[foundi]
    for i = firsti : N
        @inbounds if state[i] != pastendsemitoken(sds.vec[i]) &&
            eq(ord, deref_key((sds.vec[i], state[i])), firstk)
            state[i] = advance((sds.vec[i], state[i]))
        end
    end
    @inbounds return (deref((sds.vec[foundi], foundsemitoken)), state)
end

"""
    Base.merge!(sd::SortedDict{K,V,Ord}, d1::AbstractDict{K,V}...) where {K,V,Ord<:Ordering}

Merge one or more dicts `d1`, etc. into `sd`.
These must all must have the same key-value types.
In the case of keys duplicated among the arguments, the rightmost
argument that owns the key gets its value stored.
Time: O(*cN* log *N*), where *N*
is the total size of all the arguments.
"""
function Base.merge!(m::SortedDict{K,D,Ord},
                     others::AbstractDict{K,D}...) where {K,D,Ord <: Ordering}
    for o in others
        mergetwo!(m,o)
    end
end


"""
    Base.merge(sd::SortedDict{K,V,Ord}, d1::AbstractDict{K,V}...) where {K,V,Ord <: Ordering}

Merge one or more dicts into a single SortedDict
and return the new SortedDict.  Arguments `d1` etc.
must have the same key-value type as `sd`.
In the case of keys
duplicated among the arguments, the rightmost argument that owns the
key gets its value stored.  Time: O(*cN* log
*N*), where *N* is the total size of all the arguments.  If all
the arguments are SortedDicts with the same
key, value, and order object, then the time is O(*cN*).
"""
function Base.merge(m::SortedDict{K,D,Ord},
                    others::AbstractDict{K,D}...) where {K,D,Ord <: Ordering}
    result = packcopy(m)
    merge!(result, others...)
    return result
end

function Base.merge(m::SortedDict{K,D,Ord},
                    others::SortedDict{K,D,Ord}...) where {K, D, Ord <: Ordering}
    sds = MergeManySortedDicts{K, D, Ord}(SortedDict{K,D,Ord}[m])
    for sd in others
        if orderobject(sd) != orderobject(m)
            return invoke(merge,
                          Tuple{SortedDict{K,D,Ord}, Vararg{AbstractDict{K,D}}},
                          m, others...)
        end
        push!(sds.vec, sd)
    end
    SortedDict{K,D}(Val(true), sds, orderobject(m))
end



"""
    Base.empty(sc)

Return a new `SortedDict`, `SortedMultiDict`, or `SortedSet` of the same
type and with the same ordering as `sc` but with no entries (i.e.,
empty). Time: O(1)
"""
Base.empty(m::SortedDict{K,D,Ord}) where {K,D,Ord<:Ordering} =
    SortedDict{K,D,Ord}(orderobject(m))

OrderedCollections.isordered(::Type{T}) where {T<:SortedDict} = true
