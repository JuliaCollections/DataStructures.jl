# A SortedMultiDict is a wrapper around balancedTree.
## Unlike SortedDict, a key in SortedMultiDict can
## refer to multiple data entries.

mutable struct SortedMultiDict{K, D, Ord <: Ordering}
    bt::BalancedTree23{K,D,Ord}

    ## Base constructors

    """
        SortedMultiDict{K,V,Ord}(o)

    Construct an empty sorted multidict in which type parameters are
    explicitly listed; ordering object is explicitly specified. (See
    below for discussion of ordering.) An empty SortedMultiDict may also
    be constructed via `SortedMultiDict(K[], V[], o)` where the `o`
    argument is optional.
    """
    SortedMultiDict{K,D,Ord}(o::Ord) where {K,D,Ord} = new{K,D,Ord}(BalancedTree23{K,D,Ord}(o))
    function SortedMultiDict{K,D,Ord}(o::Ord, kv) where {K,D,Ord}
        smd = new{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

        if eltype(kv) <: Pair
            # It's (possibly?) more efficient to access the first and second
            # elements of Pairs directly, rather than destructure
            for p in kv
                insert!(smd, p.first, p.second)
            end
        else
            for (k,v) in kv
                insert!(smd, k, v)
            end
        end
        return smd

    end
end

"""
    SortedMultiDict()

Construct an empty `SortedMultiDict` with key type `Any` and value type
`Any`. Ordering defaults to `Forward` ordering.

**Note that a key type of `Any` or any other abstract type will lead
to slow performance.**
"""
SortedMultiDict() = SortedMultiDict{Any,Any,ForwardOrdering}(Forward)


"""
    SortedMultiDict(o)

Construct an empty `SortedMultiDict` with key type `Any` and value type
`Any`, ordered using `o`.

**Note that a key type of `Any` or any other abstract type will lead
to slow performance.**
"""
SortedMultiDict(o::O) where {O<:Ordering} = SortedMultiDict{Any,Any,O}(o)

# Construction from Pairs
"""
    SortedMultiDict(k1=>v1, k2=>v2, ...)

Arguments are key-value pairs for insertion into the multidict. The
keys must be of the same type as one another; the values must also
be of one type.
"""
SortedMultiDict(ps::Pair...) = SortedMultiDict(Forward, ps)

"""
    SortedMultiDict(o, k1=>v1, k2=>v2, ...)

The first argument `o` is an ordering object. The remaining
arguments are key-value pairs for insertion into the multidict. The
keys must be of the same type as one another; the values must also
be of one type.
"""
SortedMultiDict(o::Ordering, ps::Pair...) = SortedMultiDict(o, ps)
SortedMultiDict{K,D}(ps::Pair...) where {K,D} = SortedMultiDict{K,D,ForwardOrdering}(Forward, ps)
SortedMultiDict{K,D}(o::Ord, ps::Pair...) where {K,D,Ord<:Ordering} = SortedMultiDict{K,D,Ord}(o, ps)

# Construction from AbstractDicts
SortedMultiDict(o::Ord, d::AbstractDict{K,D}) where {K,D,Ord<:Ordering} = SortedMultiDict{K,D,Ord}(o, d)

## Construction from iteratables of Pairs/Tuples

# Construction specifying Key/Value types
# e.g., SortedMultiDict{Int,Float64}([1=>1, 2=>2.0])
"""
    SortedMultiDict{K,D}(iter)

Takes an arbitrary iterable object of key=>value pairs with
key type `K` and value type `D`. The default Forward ordering is used.
"""
SortedMultiDict{K,D}(kv) where {K,D} = SortedMultiDict{K,D}(Forward, kv)

"""
    SortedMultiDict{K,D}(o, iter)

Takes an arbitrary iterable object of key=>value pairs with
key type `K` and value type `D`. The ordering object `o` is explicitly given.
"""
function SortedMultiDict{K,D}(o::Ord, kv) where {K,D,Ord<:Ordering}
    try
        SortedMultiDict{K,D,Ord}(o, kv)
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("SortedMultiDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

# Construction inferring Key/Value types from input
# e.g. SortedMultiDict{}

SortedMultiDict(o1::Ordering, o2::Ordering) = throw(ArgumentError("SortedMultiDict with two parameters must be called with an Ordering and an interable of pairs"))
SortedMultiDict(kv, o::Ordering=Forward) = SortedMultiDict(o, kv)
function SortedMultiDict(o::Ordering, kv)
    try
        _sorted_multidict_with_eltype(o, kv, eltype(kv))
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("SortedMultiDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

_sorted_multidict_with_eltype(o::Ord, ps, ::Type{Pair{K,D}}) where {K,D,Ord} = SortedMultiDict{  K,  D,Ord}(o, ps)
_sorted_multidict_with_eltype(o::Ord, kv, ::Type{Tuple{K,D}}) where {K,D,Ord} = SortedMultiDict{  K,  D,Ord}(o, kv)
_sorted_multidict_with_eltype(o::Ord, ps, ::Type{Pair{K}}  ) where {K,  Ord} = SortedMultiDict{  K,Any,Ord}(o, ps)
_sorted_multidict_with_eltype(o::Ord, kv, ::Type            ) where {    Ord} = SortedMultiDict{Any,Any,Ord}(o, kv)

## TODO: It seems impossible (or at least very challenging) to create the eltype below.
##       If deemed possible, please create a test and uncomment this definition.
# _sorted_multi_dict_with_eltype{  D,Ord}(o::Ord, ps, ::Type{Pair{K,D} where K}) = SortedMultiDict{Any,  D,Ord}(o, ps)

const SMDSemiToken = IntSemiToken

const SMDToken = Tuple{SortedMultiDict, IntSemiToken}


## This function inserts an item into the tree.
## It returns a token that
## points to the newly inserted item.

"""
    insert!(sc, k)

Argument `sc` is a SortedDict or SortedMultiDict, `k` is a key and
`v` is the corresponding value. This inserts the `(k,v)` pair into
the container. If the key is already present in a SortedDict, this
overwrites the old value. In the case of SortedMultiDict, no
overwriting takes place (since SortedMultiDict allows the same key
to associate with multiple values). In the case of SortedDict, the
return value is a pair whose first entry is boolean and indicates
whether the insertion was new (i.e., the key was not previously
present) and the second entry is the semitoken of the new entry. In
the case of SortedMultiDict, a semitoken is returned (but no
boolean). Time: O(*c* log *n*)
"""
@inline function Base.insert!(m::SortedMultiDict{K,D,Ord}, k_, d_) where {K, D, Ord <: Ordering}
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), true)
    IntSemiToken(i)
end

## push! is an alternative to insert!; it returns the container.
"""
    push!(sc, k=>v)

Argument `sc` is a SortedDict or SortedMultiDict and `k=>v` is a
key-value pair. This inserts the key-value pair into the container.
If the key is already present, this overwrites the old value. The
return value is `sc`. Time: O(*c* log *n*)
"""
@inline function Base.push!(m::SortedMultiDict{K,D}, pr::Pair) where {K,D}
    insert!(m.bt, convert(K,pr[1]), convert(D,pr[2]), true)
    return m
end


## First and last return the first and last (key,data) pairs
## in the SortedMultiDict.  It is an error to invoke them on an
## empty SortedMultiDict.

"""
    first(sc)

Argument `sc` is a SortedDict, SortedMultiDict or SortedSet. This
function returns the first item (a `k=>v` pair for SortedDict and
SortedMultiDict or a key for SortedSet) according to the sorted
order in the container. Thus, `first(sc)` is equivalent to
`deref((sc,startof(sc)))`. It is an error to call this function on
an empty container. Time: O(log *n*)
"""
@inline function Base.first(m::SortedMultiDict)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return Pair(m.bt.data[i].k, m.bt.data[i].d)
end

"""
    last(sc)

Argument `sc` is a SortedDict, SortedMultiDict or SortedSet. This
function returns the last item (a `k=>v` pair for SortedDict and
SortedMultiDict or a key for SortedSet) according to the sorted
order in the container. Thus, `last(sc)` is equivalent to
`deref((sc,lastindex(sc)))`. It is an error to call this function on an
empty container. Time: O(log *n*)
"""
@inline function Base.last(m::SortedMultiDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return Pair(m.bt.data[i].k, m.bt.data[i].d)
end


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


## '(k,d) in m' checks whether a key-data pair is in
## a sorted multidict.  This requires a loop over
## all data items whose key is equal to k.


function in_(k_, d_, m::SortedMultiDict)
    k = convert(keytype(m), k_)
    d = convert(valtype(m), d_)
    i1 = findkeyless(m.bt, k)
    i2,exactfound = findkey(m.bt,k)
    !exactfound && return false
    ord = m.bt.ord
    while true
        i1 = nextloc0(m.bt, i1)
        @assert(eq(ord, m.bt.data[i1].k, k))
        m.bt.data[i1].d == d && return true
        i1 == i2 && return false
    end
end

"""
    eltype(sc)

Returns the (key,value) type (a 2-entry pair, i.e., `Pair{K,V}`) for
SortedDict and SortedMultiDict. Returns the key type for SortedSet.
This function may also be applied to the type itself. Time: O(1)
"""
@inline Base.eltype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} =  Pair{K,D}
@inline Base.eltype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =  Pair{K,D}

"""
    in(p, sc)

Returns true if `p` is in `sc`. In the case that `sc` is a
SortedDict or SortedMultiDict, `p` is a key=>value pair. In the
case that `sc` is a SortedSet, `p` should be a key. Time: O(*c* log
*n* + *d*) for SortedDict and SortedSet, where *d* stands for the
time to compare two values. In the case of SortedMultiDict, the time
is O(*c* log *n* + *dl*), and *l* stands for the number of entries
that have the key of the given pair. (So therefore this call is
inefficient if the same key addresses a large number of values, and
an alternative should be considered.)
"""
@inline Base.in(pr::Pair, m::SortedMultiDict) =
    in_(pr[1], pr[2], m)
@inline Base.in(::Tuple{Any,Any}, ::SortedMultiDict) =
    throw(ArgumentError("'(k,v) in sortedmultidict' not supported in Julia 0.4 or 0.5.  See documentation"))

"""
    keytype(sc)

Returns the key type for SortedDict, SortedMultiDict and SortedSet.
This function may also be applied to the type itself. Time: O(1)
"""
@inline Base.keytype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} = K
@inline Base.keytype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = K

"""
    valtype(sc)

Returns the value type for SortedDict and SortedMultiDict. This
function may also be applied to the type itself. Time: O(1)
"""
@inline Base.valtype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} = D
@inline Base.valtype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = D

"""
    ordtype(sc)

Returns the order type for SortedDict, SortedMultiDict and
SortedSet. This function may also be applied to the type itself.
Time: O(1)
"""
@inline ordtype(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering} = Ord
@inline ordtype(::Type{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = Ord

"""
    orderobject(sc)

Returns the order object used to construct the container. Time: O(1)
"""
@inline orderobject(m::SortedMultiDict) = m.bt.ord

"""
    haskey(sc,k)

Returns true if key `k` is present for SortedDict, SortedMultiDict
or SortedSet `sc`. For SortedSet, `haskey(sc,k)` is a synonym for
`in(k,sc)`. For SortedDict and SortedMultiDict, `haskey(sc,k)` is
equivalent to `in(k,keys(sc))`. Time: O(*c* log *n*)
"""
@inline function Base.haskey(m::SortedMultiDict, k_)
    i, exactfound = findkey(m.bt,convert(keytype(m),k_))
    return exactfound
end


## Check if two SortedMultiDicts are equal in the sense of containing
## the same (K,D) pairs in the same order.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.
"""
    isequal(sc1,sc2)

Checks if two containers are equal in the sense that they contain
the same items; the keys are compared using the `eq` method, while
the values are compared with the `isequal` function. In the case of
SortedMultiDict, equality requires that the values associated with a
particular key have same order (that is, the same insertion order).
Note that `isequal` in this sense does not imply any correspondence
between semitokens for items in `sc1` with those for `sc2`. If the
equality-testing method associated with the keys and values implies
hash-equivalence in the case of SortedDict, then `isequal` of the
entire containers implies hash-equivalence of the containers. Time:
O(*cn* + *n* log *n*)
"""
function Base.isequal(m1::SortedMultiDict, m2::SortedMultiDict)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedMultiDicts unless their element types and ordering objects are equal"))
    end
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendsemitoken(m1)
            return p2 == pastendsemitoken(m2)
        end
        if p2 == pastendsemitoken(m2)
            return false
        end
        k1,d1 = deref((m1,p1))
        k2,d2 = deref((m2,p2))
        if !eq(ord,k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance((m1,p1))
        p2 = advance((m2,p2))
    end
end

const SDorAbstractDict = Union{AbstractDict,SortedMultiDict}

function mergetwo!(m::SortedMultiDict{K,D,Ord},
                   m2::SDorAbstractDict) where {K,D,Ord <: Ordering}
    for (k,v) in m2
        insert!(m.bt, convert(K,k), convert(D,v), true)
    end
end

# Standard copy functions use packcopy - that is, they retain elements but not
# the identical structure.
Base.copymutable(m::SortedMultiDict) = packcopy(m)
Base.copy(m::SortedMultiDict) = packcopy(m)

"""
    packcopy(sc)

This returns a copy of `sc` in which the data is packed. When
deletions take place, the previously allocated memory is not
returned. This function can be used to reclaim memory after many
deletions. Time: O(*cn* log *n*)
"""
function packcopy(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    w = SortedMultiDict{K,D}(orderobject(m))
    mergetwo!(w,m)
    return w
end

"""
    packdeepcopy(sc)

This returns a packed copy of `sc` in which the keys and values are
deep-copied. This function can be used to reclaim memory after many
deletions. Time: O(*cn* log *n*)
"""
function packdeepcopy(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    w = SortedMultiDict{K,D}(orderobject(m))
    for (k,v) in m
        insert!(w.bt, deepcopy(k), deepcopy(v), true)
    end
    return w
end

"""
    merge!(sc, sc1...)

This updates `sc` by merging SortedDicts or SortedMultiDicts `sc1`,
etc. into `sc`. These must all must have the same key-value types.
In the case of keys duplicated among the arguments, the rightmost
argument that owns the key gets its value stored for SortedDict. In
the case of SortedMultiDict all the key-value pairs are stored, and
for overlapping keys the ordering is left-to-right. This function is
not available for SortedSet, but the `union!` function (see below)
provides equivalent functionality. Time: O(*cN* log *N*), where *N*
is the total size of all the arguments.
"""
function Base.merge!(m::SortedMultiDict{K,D,Ord},
                others::SDorAbstractDict...) where {K,D,Ord <: Ordering}
    for o in others
        mergetwo!(m,o)
    end
end

"""
    merge(sc1, sc2...)

This returns a SortedDict or SortedMultiDict that results from
merging SortedDicts or SortedMultiDicts `sc1`, `sc2`, etc., which
all must have the same key-value-ordering types. In the case of keys
duplicated among the arguments, the rightmost argument that owns the
key gets its value stored for SortedDict. In the case of
SortedMultiDict all the key-value pairs are stored, and for keys
shared between `sc1` and `sc2` the ordering is left-to-right. This
function is not available for SortedSet, but the `union` function
(see below) provides equivalent functionality. Time: O(*cN* log
*N*), where *N* is the total size of all the arguments.
"""
function Base.merge(m::SortedMultiDict{K,D,Ord},
               others::SDorAbstractDict...) where {K,D,Ord <: Ordering}
    result = packcopy(m)
    merge!(result, others...)
    return result
end

function Base.show(io::IO, m::SortedMultiDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    print(io, "SortedMultiDict(")
    print(io, orderobject(m), ",")
    l = length(m)
    for (count,(k,v)) in enumerate(m)
        print(io, k, " => ", v)
        if count < l
            print(io, ", ")
        end
    end
    print(io, ")")
end

"""
    empty(sc)

Returns a new `SortedDict`, `SortedMultiDict`, or `SortedSet` of the same
type and with the same ordering as `sc` but with no entries (i.e.,
empty). Time: O(1)
"""
Base.empty(m::SortedMultiDict{K,D,Ord}) where {K,D,Ord<:Ordering} =
   SortedMultiDict{K,D}(orderobject(m))

OrderedCollections.isordered(::Type{T}) where {T<:SortedMultiDict} = true
