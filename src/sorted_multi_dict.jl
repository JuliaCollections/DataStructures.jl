# A SortedMultiDict is a wrapper around balancedTree.
## Unlike SortedDict, a key in SortedMultiDict can
## refer to multiple data entries.

mutable struct SortedMultiDict{K, D, Ord <: Ordering}
    bt::BalancedTree23{K,D,Ord}
end

"""
    SortedMultiDict{K,V,Ord}(o::Ord=Forward) where {K, V, Ord <: Ordering}
    SortedMultiDict{K,V,Ord}(o::Ord, iterable) where {K, V, Ord <: Ordering}

Construct a sorted multidict in which type parameters are
explicitly listed; ordering object is explicitly specified. 
Time: O(*cn* log *n*)
"""
SortedMultiDict{K,D,Ord}(o::Ord=Forward) where {K,D,Ord<:Ordering} =
    SortedMultiDict{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

function SortedMultiDict{K,D,Ord}(o::Ord, kv) where {K,D,Ord<:Ordering}
    smd = SortedMultiDict{K,D,Ord}(BalancedTree23{K,D,Ord}(o))
    for (k,v) in kv
        push_return_semitoken!(smd, k=>v)
    end
    return smd
end


"""
    SortedMultiDict(o::Ord=Forward) where {Ord <: Ordering}
    SortedMultiDict{K,V}(o::Ordering=Forward) where {K,V}

Construct an empty `SortedMultiDict` with key type `K` and value type
`V` with `o` ordering (default to `Forward` ordering).  If
`K` and `V` are not specified as in the
first form, then they are assumed to both be `Any`.
Time: O(1).

**Note that a key type of `Any` or any other abstract type will lead
to slow performance, as the values are stored boxed (i.e., as
pointers), and insertion will require a run-time lookup of the
appropriate comparison function. It is recommended to always specify
a concrete key type, or to use one of the constructors in
which the key type is inferred.**
"""
SortedMultiDict(o::Ord=Forward) where {Ord <: Ordering} = 
    SortedMultiDict{Any,Any,typeof(o)}(o)
SortedMultiDict{K,D}(o::Ordering=Forward) where {K, D} =
    SortedMultiDict{K,D,typeof(o)}(o)

# Construction from Pairs
"""
    SortedMultiDict(ps::Pair...)
    SortedMultiDict(o, ps::Pair...)
    SortedMultiDict{K,V}(ps::Pair...)
    SortedMultiDict{K,V}(o, ps::Pair...)

Construct a `SortedMultiDict` from the given key-value pairs. 
The key type and value type are inferred from the
given key-value pairs in the first two form.
The ordering is assumed to be `Forward`
ordering in the first and third forms.  
The first two forms involve copying the data three times to
infer the types and so are less efficient than the third and fourth
form where `{K,V}` are specified explicitly.  Time: O(*cn* log *n*)
"""
SortedMultiDict(ps::Pair...) = SortedMultiDict(Forward, ps)
SortedMultiDict{K,D}(ps::Pair...) where {K,D} = SortedMultiDict{K,D,ForwardOrdering}(Forward, ps)
SortedMultiDict(o::Ordering, ps::Pair...) = SortedMultiDict(o, ps)
SortedMultiDict{K,D}(o::Ord, ps::Pair...) where {K,D,Ord<:Ordering} = SortedMultiDict{K,D,Ord}(o, ps)


"""
    SortedMultiDict(iter, o::Ord=Forward) where {Ord <: Ordering}
    SortedMultiDict(o::Ordering, iter)
    SortedMultiDict{K,V}(iter, o::Ordering=Forward) where {K, V}
    SortedMultiDict{K,V}(o::Ordering, iter) where {K, V}

Construct a `SortedMultiDict` from an arbitrary iterable object of
`key=>value` pairs or (key,value) tuples with order object `o`. The key type
and value type are inferred from the given iterable in the
first two forms.  The first two forms copy the
data three times, so
it is more efficient to explicitly specify `K` and `V` as in the
second two forms.  Time: O(*cn* log *n*)

"""
SortedMultiDict(kv, o::Ord=Forward) where {Ord <: Ordering} =
    SortedMultiDict(o, kv)
SortedMultiDict{K,D}(kv, o::Ordering=Forward) where {K,D} =
    SortedMultiDict{K,D, typeof(o)}(o, kv)
SortedMultiDict{K,D}(o::Ordering, kv) where {K,D} =
    SortedMultiDict{K,D, typeof(o)}(o, kv)

# TODO: figure out how to infer type without three copies
function SortedMultiDict(o::Ordering, kv)
    c = collect(kv)
    if eltype(c) <: Pair
        c2 = collect((t.first, t.second) for t in c)
    elseif eltype(c) <: Tuple
        c2 = collect((t[1], t[2]) for t in c)
    else
        throw(ArgumentError("In SortedMultiDict(o,kv), kv should contain either pairs or 2-tuples"))
    end
    SortedMultiDict{eltype(c2).parameters[1], eltype(c2).parameters[2], typeof(o)}(o, c2)
end


"""
    SortedMultiDict{K,V}(::Val{true}, iterable) where {K,V}
    SortedMultiDict{K,V}(::Val{true}, iterable, ord::Ord) where {K,V,Ord<:Ordering}

Construct a `SortedMultiDict` from an iterable whose eltype is
Tuple{K,V} or Pair{K,V} and that is already in sorted ordered. 
The first form assumes Forward ordering.
Duplicate keys
allowed. Time: O(*cn*).
"""
SortedMultiDict{K,D}(::Val{true},iterable) where {K, D} =
    SortedMultiDict{K,D}(Val(true), iterable, Forward)

function SortedMultiDict{K,D}(::Val{true},
                              iterable,
                              ord::Ord) where {K, D, Ord<:Ordering}
    SortedMultiDict{K, D, Ord}(BalancedTree23{K, D, Ord}(Val(true),
                                                         iterable,
                                                         ord,
                                                         true))
end


## The following is needed to resolve ambiguities

SortedMultiDict(::Ordering, ::Ordering) =
    throw(ArgumentError("Not a valid SortedMultiDict constructor"))
SortedMultiDict{K,D}(::Ordering, ::Ordering) where {K,D} =
    throw(ArgumentError("Not a valid SortedMultiDict constructor"))
SortedMultiDict(::Val{true}, ::Ordering) =
    throw(ArgumentError("Not a valid SortedMultiDict constructor"))
SortedMultiDict{K,D}(::Val{true}, ::Ordering) where {K,D}=
throw(ArgumentError("Not a valid SortedMultiDict constructor"))




const SMDSemiToken = IntSemiToken

const SMDToken = Tuple{SortedMultiDict, IntSemiToken}


"""
    DataStructures.push_return_semitoken!(smd::SortedMultiDict, pr::Pair)

Insert the key-value pair `pr`, i.e., `k=>v`, into `smd`.  
If `k` already appears as a key
in `smd`, then `k=>v` is inserted in the rightmost position after existing
items with key `k`.  Unlike `push!`, 
the
return value is a 2-tuple whose first entry is boolean
always equal to `true` and whose second entry is the semitoken of the new entry.
(The reason for returning a bool whose value is always `true` is for consistency
with `push_return_semitoken!` for SortedDict and SortedSet.)
This function replaces
the deprecated `insert!`.
Time: O(*c* log *n*)
"""
@inline function push_return_semitoken!(m::SortedMultiDict, pr::Pair)
    b, i = insert!(m.bt, convert(keytype(m),pr.first), convert(valtype(m),pr.second), true)
    b, IntSemiToken(i)
end


"""
    Base.push!(smd::SortedMultiDict, p::Pair)

Insert the pair `p`, i.e., a `k=>v` into `smd`.
If `k` already appears as a key
in `smd`, then `k=>v` is inserted in the rightmost position after existing
items with key `k`.  Returns the container.
See also [`push_return_semitoken!(smd::SortedMultiDict, p::Pair)`](@ref).
Time: O(*c* log *n*)
"""
@inline function Base.push!(m::SortedMultiDict{K,D}, pr::Pair) where {K,D}
    insert!(m.bt, convert(K,pr[1]), convert(D,pr[2]), true)
    return m
end


"""
    DataStructures.searchequalrange(smd::SortedMultiDict, k)

Return two semitokens that correspond to the first and last
items in the SortedMultiDict that have key exactly equal
to `k`.  If `k` is not found, then it returns 
(pastendsemitoken(smd), beforestartsemitoken(smd)).
Time: O(*c* log *n*)
"""
function searchequalrange(m::SortedMultiDict, k_)
    k = convert(keytype(m),k_)
    i1 = findkeyless(m.bt, k)
    i2, exactfound = findkey(m.bt, k)
    if exactfound
        i1a = nextloc0(m.bt, i1)
        return IntSemiToken(i1a), IntSemiToken(i2)
    else
        return IntSemiToken(2), IntSemiToken(1)
    end
end


"""
    Base.eltype(sc)

Returns the (key,value) type (a 2-entry pair, i.e., `Pair{K,V}`) for
SortedDict and SortedMultiDict. Returns the key type for SortedSet.
This function may also be applied to the type itself. Time: O(1)
"""
@inline Base.eltype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} =  Pair{K,D}
@inline Base.eltype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =  Pair{K,D}


function in_(k_, d_, m::SortedMultiDict)
    k = convert(keytype(m), k_)
    d = convert(valtype(m), d_)
    i1 = findkeyless(m.bt, k)
    i2,exactfound = findkey(m.bt,k)
    !exactfound && return false
    ord = m.bt.ord
    while true
        i1 = nextloc0(m.bt, i1)
        @invariant eq(ord, m.bt.data[i1].k, k)
        m.bt.data[i1].d == d && return true
        i1 == i2 && return false
    end
end


"""
    Base.in(p::Pair, smd::SortedMultiDict)

Return true if `p` is in `smd`. Here, `p` is a key=>value pair. In the
The time is
is O(*c* log *n* + *dl*) where *d* is the time
to compare two values and  *l* stands for the number of entries
that have the key of the given pair. (So therefore this call is
inefficient if the same key addresses a large number of values, and
an alternative should be considered.)
"""
@inline Base.in(pr::Pair, m::SortedMultiDict) =
    in_(pr[1], pr[2], m)

@inline Base.keytype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} = K
@inline Base.keytype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = K
@inline Base.valtype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} = D
@inline Base.valtype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = D


"""
    Base.isequal(smd1::SortedMultiDict{K,V,Ord}, smd2::SortedMultiDict{K,V,Ord}) where {K, V, Ord <: Ordering}
           

Check if two SortedMultiDicts are equal in the sense that they contain
the same items in the same order (that is, the same insertion order).
They must have the same order object, else they compare unequal.
The keys are compared using the `eq` method, while
the values are compared with the `isequal` function.
Note that `isequal` in this sense does not imply any correspondence
between semitokens for items in `smd1` with those for `smd2`. 
Time: O(*cn*)
"""
function Base.isequal(m1::SortedMultiDict{K, D, Ord},
                      m2::SortedMultiDict{K, D, Ord}) where {K, D, Ord <: Ordering}
    ord = orderobject(m1)
    if ord != orderobject(m2)
        return false
    end
    p1 = firstindex(m1)
    p2 = firstindex(m2)
    while true
        if p1 == pastendsemitoken(m1)
            return p2 == pastendsemitoken(m2)
        end
        if p2 == pastendsemitoken(m2)
            return false
        end
        @inbounds k1,d1 = deref((m1,p1))
        @inbounds k2,d2 = deref((m2,p2))
        (!eq(ord,k1,k2) || !isequal(d1,d2)) && return false
        @inbounds p1 = advance((m1,p1))
        @inbounds p2 = advance((m2,p2))
    end
end


function mergetwo!(m::SortedMultiDict{K,D,Ord}, iterable) where {K,D,Ord <: Ordering}
    for (k,v) in iterable
        insert!(m.bt, convert(K,k), convert(D,v), true)
    end
end

Base.copymutable(m::SortedMultiDict) = packcopy(m)
Base.copy(m::SortedMultiDict) = packcopy(m)


# See sorted_set.jl for the docstrings on packcopy and packdeepcopy
function packcopy(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    SortedMultiDict{K, D}(Val(true), m, orderobject(m))
end

function packdeepcopy(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    SortedMultiDict{K, D}(Val(true), deepcopy(m), orderobject(m))
end


struct MergeManySortedMultiDicts{K, D, Ord <: Ordering}
    vec::Vector{SortedMultiDict{K,D,Ord}}
end

function Base.iterate(sds::MergeManySortedMultiDicts{K, D, Ord},
                      state = [firstindex(sds.vec[k]) for k=1:length(sds.vec)]) where
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
            if lt(ord, k2, firstk)
                foundi = i
                firstk = k2
            end
        end
    end
    foundsemitoken = state[foundi]
    @inbounds state[foundi] = advance((sds.vec[foundi], foundsemitoken))
    @inbounds return (deref((sds.vec[foundi], foundsemitoken)), state)
end

"""
    Base.merge!(smd::SortedMultiDict, iter...)

Merge one or more iterables `iter`, etc. into `smd`.
These must all must have the same key-value types.
Items with equal keys are stored
with left-to-right ordering.  Time: O(*cN* log *N*), where *N*
is the total size of all the arguments.
"""
function Base.merge!(m::SortedMultiDict{K,D,Ord},
                     others...) where {K,D,Ord <: Ordering}
    for o in others
        mergetwo!(m,o)
    end
end


"""
    Base.merge(smd::SortedMultiDict, iter...)

Merge `smd` and one or more iterables and return
the resulting new SortedMultiDict.
The iterables must have
the same key-value type as `smd`.
Items with equal keys are stored
with left-to-right ordering.  
Time: O(*cN* log
*N*), where *N* is the total size of all the arguments.  If all
the arguments are SortedMultiDicts with the same
key, value, and order object, then the time is O(*cN*).
"""
function Base.merge(m::SortedMultiDict{K,D,Ord},
                    others...) where {K,D,Ord <: Ordering}
    result = packcopy(m)
    merge!(result, others...)
    return result
end

function Base.merge(m::SortedMultiDict{K,D,Ord},
                    others::SortedMultiDict{K,D,Ord}...) where {K, D, Ord <: Ordering}
    sds = MergeManySortedMultiDicts{K, D, Ord}(SortedMultiDict{K,D,Ord}[m])
    for sd in others
        if orderobject(sd) != orderobject(m)
            return invoke(merge, Tuple{SortedMultiDict, Vararg{Any}},
            m, others...)
        end
        push!(sds.vec, sd)
    end
    SortedMultiDict{K, D}(Val(true), sds, orderobject(m))
end

function Base.show(io::IO, m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    print(io, "SortedMultiDict{", K,
          ",\n                ", D,
          ",\n                ", Ord, "}(")
    print(io, orderobject(m), ",\n")
    print(io, collect(m))
    print(io, ")")
end

"""
    Base.empty(sc)

Returns a new `SortedDict`, `SortedMultiDict`, or `SortedSet` of the same
type and with the same ordering as `sc` but with no entries (i.e.,
empty). Time: O(1)
"""
Base.empty(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord<:Ordering} =
   SortedMultiDict{K,D}(orderobject(m))

OrderedCollections.isordered(::Type{T}) where {T<:SortedMultiDict} = true
