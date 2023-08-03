## A SortedDict is a wrapper around balancedTree with
## methods similiar to those of Julia container Dict.

mutable struct SortedDict{K, D, Ord <: Ordering} <: AbstractDict{K,D}
    bt::BalancedTree23{K,D,Ord}

    ## Base constructors
    """
        SortedDict{K,V}(o=Forward)

    Construct an empty `SortedDict` with key type `K` and value type
    `V` with `o` ordering (default to forward ordering).
    """
    SortedDict{K,D,Ord}(o::Ord) where {K, D, Ord <: Ordering} =
        new{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

    function SortedDict{K,D,Ord}(o::Ord, kv) where {K, D, Ord <: Ordering}
        s = new{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

        if eltype(kv) <: Pair
            # It's (possibly?) more efficient to access the first and second
            # elements of Pairs directly, rather than destructure
            for p in kv
                s[p.first] = p.second
            end
        else
            for (k, v) in kv
                s[k] = v
            end
        end
        return s
    end

end

# Any-Any constructors
"""
    SortedDict()

Construct an empty `SortedDict` with key type `Any` and value type
`Any`. Ordering defaults to `Forward` ordering.

**Note that a key type of `Any` or any other abstract type will lead
to slow performance, as the values are stored boxed (i.e., as
pointers), and insertion will require a run-time lookup of the
appropriate comparison function. It is recommended to always specify
a concrete key type, or to use one of the constructors below in
which the key type is inferred.**
"""
SortedDict() = SortedDict{Any,Any,ForwardOrdering}(Forward)

"""
    SortedDict(o=Forward)

Construct an empty `SortedDict` with key type `K` and value type
`V`. If `K` and `V` are not specified, the dictionary defaults to a
`SortedDict{Any,Any}`. Keys and values are converted to the given
type upon insertion. Ordering `o` defaults to `Forward` ordering.

**Note that a key type of `Any` or any other abstract type will lead
to slow performance, as the values are stored boxed (i.e., as
pointers), and insertion will require a run-time lookup of the
appropriate comparison function. It is recommended to always specify
a concrete key type, or to use one of the constructors below in
which the key type is inferred.**
"""
SortedDict(o::Ord) where {Ord <: Ordering} = SortedDict{Any,Any,Ord}(o)

# Construction from Pairs
# TODO: fix SortedDict(1=>1, 2=>2.0)
"""
    SortedDict(k1=>v1, k2=>v2, ...)
and `SortedDict{K,V}(k1=>v1, k2=>v2, ...)`

Construct a `SortedDict` from the given key-value pairs. If `K` and
`V` are not specified, key type and value type are inferred from the
given key-value pairs, and ordering is assumed to be `Forward`
ordering.
"""
SortedDict(ps::Pair...) = SortedDict(Forward, ps)
SortedDict{K,D}(ps::Pair...) where {K,D} = SortedDict{K,D,ForwardOrdering}(Forward, ps)

"""
    SortedDict(o, k1=>v1, k2=>v2, ...)

Construct a `SortedDict` from the given pairs with the specified
ordering `o`. The key type and value type are inferred from the
given pairs.
"""
SortedDict(o::Ordering, ps::Pair...) = SortedDict(o, ps)

"""
    SortedDict{K,V}(o, k1=>v1, k2=>v2, ...)

Construct a `SortedDict` from the given pairs with the specified
ordering `o`. If `K` and `V` are not specified, the key type and
value type are inferred from the given pairs. See below for more
information about ordering.
"""
SortedDict{K,D}(o::Ord, ps::Pair...) where {K,D,Ord<:Ordering} = SortedDict{K,D,Ord}(o, ps)


# Construction from AbstractDicts
SortedDict(o::Ord, d::AbstractDict{K,D}) where {K,D,Ord<:Ordering} = SortedDict{K,D,Ord}(o, d)

## Construction from iteratables of Pairs/Tuples

# Construction specifying Key/Value types
# e.g., SortedDict{Int,Float64}([1=>1, 2=>2.0])
"""
    SortedDict(iter, o=Forward)
and `SortedDict{K,V}(iter, o=Forward)`

Construct a `SortedDict` from an arbitrary iterable object of
`key=>value` pairs. If `K` and `V` are not specified, the key type
and value type are inferred from the given iterable. The ordering
object `o` defaults to `Forward`.
"""
SortedDict{K,D}(kv) where {K,D} = SortedDict{K,D}(Forward, kv)
function SortedDict{K,D}(o::Ord, kv) where {K,D,Ord<:Ordering}
    try
        SortedDict{K,D,Ord}(o, kv)
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("SortedDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

# Construction inferring Key/Value types from input
# e.g. SortedDict{}

SortedDict(o1::Ordering, o2::Ordering) = throw(ArgumentError("SortedDict with two parameters must be called with an Ordering and an interable of pairs"))


"""
    SortedDict(d, o=Forward)
and `SortedDict{K,V}(d, o=Forward)`

Construct a `SortedDict` from an ordinary Julia dict `d` (or any
associative type), e.g.:

```julia
d = Dict("New York" => 1788, "Illinois" => 1818)
c = SortedDict(d)
```

In this example the key-type is deduced to be `String`, while the
value-type is `Int`.

If `K` and `V` are not specified, the key type and value type are
inferred from the given dictionary. The ordering object `o` defaults
to `Forward`.
"""
SortedDict(kv, o::Ordering=Forward) = SortedDict(o, kv)
function SortedDict(o::Ordering, kv)
    try
        _sorted_dict_with_eltype(o, kv, eltype(kv))
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("SortedDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

_sorted_dict_with_eltype(o::Ord, ps, ::Type{Pair{K,D}}) where {K,D,Ord} = SortedDict{  K,  D,Ord}(o, ps)
_sorted_dict_with_eltype(o::Ord, kv, ::Type{Tuple{K,D}}) where {K,D,Ord} = SortedDict{  K,  D,Ord}(o, kv)
_sorted_dict_with_eltype(o::Ord, ps, ::Type{Pair{K}}  ) where {K,  Ord} = SortedDict{  K,Any,Ord}(o, ps)
_sorted_dict_with_eltype(o::Ord, kv, ::Type            ) where {    Ord} = SortedDict{Any,Any,Ord}(o, kv)

## TODO: It seems impossible (or at least very challenging) to create the eltype below.
##       If deemed possible, please create a test and uncomment this definition.
# _sorted_dict_with_eltype{  D,Ord}(o::Ord, ps, ::Type{Pair{K,D} where K}) = SortedDict{Any,  D,Ord}(o, ps)

const SDSemiToken = IntSemiToken

const SDToken = Tuple{SortedDict,IntSemiToken}

## This function implements m[k]; it returns the
## data item associated with key k.
"""
    v = sd[k]

Argument `sd` is a SortedDict and `k` is a key. In an expression,
this retrieves the value (`v`) associated with the key (or `KeyError` if
none). On the left-hand side of an assignment, this assigns or
reassigns the value associated with the key. (For assigning and
reassigning, see also `insert!` below.) Time: O(*c* log *n*)
"""
@inline function Base.getindex(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    !exactfound && throw(KeyError(k_))
    return m.bt.data[i].d
end


## This function implements m[k]=d; it sets the
## data item associated with key k equal to d.
"""
    sc[st] = v

If `st` is a semitoken and `sc` is a SortedDict or SortedMultiDict,
then `sc[st]` refers to the value field of the (key,value) pair that
the full token `(sc,st)` refers to. This expression may occur on
either side of an assignment statement. Time: O(1)
"""
@inline function Base.setindex!(m::SortedDict{K,D,Ord}, d_, k_) where {K, D, Ord <: Ordering}
    insert!(m.bt, convert(K,k_), convert(D,d_), false)
    return m
end

## push! is an alternative to insert!; it returns the container.
"""
    push!(sc, k=>v)

Argument `sc` is a SortedDict or SortedMultiDict and `k=>v` is a
key-value pair. This inserts the key-value pair into the container.
If the key is already present, this overwrites the old value. The
return value is `sc`. Time: O(*c* log *n*)
"""
@inline function Base.push!(m::SortedDict{K,D}, pr::Pair) where {K,D}
    insert!(m.bt, convert(K, pr[1]), convert(D, pr[2]), false)
    return m
end

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.

"""
    findkey(sd, k)

Argument `sd` is a SortedDict and argument `k` is a key. This
function returns the semitoken that refers to the item whose key is
`k`, or past-end semitoken if `k` is absent. Time: O(*c* log *n*)
"""
@inline function findkey(m::SortedDict, k_)
    ll, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(exactfound ? ll : 2)
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

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
@inline function Base.insert!(m::SortedDict{K,D,Ord}, k_, d_) where {K,D, Ord <: Ordering}
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), false)
    b, IntSemiToken(i)
end

"""
    eltype(sc)

Returns the (key,value) type (a 2-entry pair, i.e., `Pair{K,V}`) for
SortedDict and SortedMultiDict. Returns the key type for SortedSet.
This function may also be applied to the type itself. Time: O(1)
"""
@inline Base.eltype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} =  Pair{K,D}
@inline Base.eltype(::Type{SortedDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =  Pair{K,D}

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
@inline function Base.in(pr::Pair, m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    i, exactfound = findkey(m.bt,convert(K,pr[1]))
    return exactfound && isequal(m.bt.data[i].d,convert(D,pr[2]))
end

@inline Base.in(::Tuple{Any,Any}, ::SortedDict) =
    throw(ArgumentError("'(k,v) in sorteddict' not supported in Julia 0.4 or 0.5.  See documentation"))

"""
    keytype(sc)

Returns the key type for SortedDict, SortedMultiDict and SortedSet.
This function may also be applied to the type itself. Time: O(1)
"""
@inline Base.keytype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} = K
@inline Base.valtype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} = D

"""
    valtype(sc)

Returns the value type for SortedDict and SortedMultiDict. This
function may also be applied to the type itself. Time: O(1)
"""

"""
    ordtype(sc)

Returns the order type for SortedDict, SortedMultiDict and
SortedSet. This function may also be applied to the type itself.
Time: O(1)
"""
@inline ordtype(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering} = Ord
@inline ordtype(::Type{SortedDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = Ord


"""
    orderobject(sc)

Returns the order object used to construct the container. Time: O(1)
"""
@inline orderobject(m::SortedDict) = m.bt.ord


## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.

"""
    first(sc)

Argument `sc` is a SortedDict, SortedMultiDict or SortedSet. This
function returns the first item (a `k=>v` pair for SortedDict and
SortedMultiDict or a key for SortedSet) according to the sorted
order in the container. Thus, `first(sc)` is equivalent to
`deref((sc,startof(sc)))`. It is an error to call this function on
an empty container. Time: O(log *n*)
"""
@inline function Base.first(m::SortedDict)
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
@inline function Base.last(m::SortedDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return Pair(m.bt.data[i].k, m.bt.data[i].d)
end

"""
    haskey(sc,k)

Returns true if key `k` is present for SortedDict, SortedMultiDict
or SortedSet `sc`. For SortedSet, `haskey(sc,k)` is a synonym for
`in(k,sc)`. For SortedDict and SortedMultiDict, `haskey(sc,k)` is
equivalent to `in(k,keys(sc))`. Time: O(*c* log *n*)
"""
@inline function Base.haskey(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    exactfound
end

"""
    get(sd,k,v)

Returns the value associated with key `k` where `sd` is a
SortedDict, or else returns `v` if `k` is not in `sd`. Time: O(*c*
log *n*)
"""
function Base.get(default_::Union{Function,Type}, m::SortedDict{K,D}, k_) where {K,D}
    i, exactfound = findkey(m.bt, convert(K, k_))
    return exactfound ? m.bt.data[i].d : default_()
end

Base.get(m::SortedDict, k_, default_) = get(()->default_, m, k_)

"""
    get!(sd,k,v)

Returns the value associated with key `k` where `sd` is a
SortedDict, or else returns `v` if `k` is not in `sd`, and in the
latter case, inserts `(k,v)` into `sd`. Time: O(*c* log *n*)
"""
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

Base.get!(m::SortedDict, k_, default_) = get!(()->default_, m, k_)

"""
    getkey(sd,k,defaultk)

Returns key `k` where `sd` is a SortedDict, if `k` is in `sd` else
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
    delete!(sc, k)

Argument `sc` is a SortedDict or SortedSet and `k` is a key. This
operation deletes the item whose key is `k`. It is a `KeyError` if
`k` is not a key of an item in the container. After this operation
is complete, any token addressing the deleted item is invalid.
Returns `sc`. Time: O(*c* log *n*)
"""
@inline function Base.delete!(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    if exactfound
        delete!(m.bt, i)
    end
    m
end

"""
    pop!(sc, k[, default])

Deletes the item with key `k` in SortedDict or SortedSet `sc` and
returns the value that was associated with `k` in the case of
SortedDict or `k` itself in the case of SortedSet. If `k` is not in `sc`
return `default`, or throw a `KeyError` if `default` is not specified.
Time: O(*c* log *n*)
"""
@inline function Base.pop!(m::SortedDict, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    !exactfound && throw(KeyError(k_))
    d = m.bt.data[i].d
    delete!(m.bt, i)
    return d
end

@inline function Base.pop!(m::SortedDict, k_, default)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    !exactfound && return default
    d = m.bt.data[i].d
    delete!(m.bt, i)
    return d
end


## Check if two SortedDicts are equal in the sense of containing
## the same (K,D) pairs.  This sense of equality does not mean
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
function Base.isequal(m1::SortedDict, m2::SortedDict)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedDicts unless their element types and ordering objects are equal"))
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


function mergetwo!(m::SortedDict{K,D,Ord},
                   m2::AbstractDict{K,D}) where {K,D,Ord <: Ordering}
    for (k,v) in m2
        m[convert(K,k)] = convert(D,v)
    end
end

# Standard copy functions use packcopy - that is, they retain elements but not
# the identical structure.
Base.copymutable(m::SortedDict) = packcopy(m)
Base.copy(m::SortedDict) = packcopy(m)

"""
    packcopy(sc)

This returns a copy of `sc` in which the data is packed. When
deletions take place, the previously allocated memory is not
returned. This function can be used to reclaim memory after many
deletions. Time: O(*cn* log *n*)
"""
function packcopy(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    w = SortedDict(Dict{K,D}(), orderobject(m))
    mergetwo!(w,m)
    return w
end

"""
    packdeepcopy(sc)

This returns a packed copy of `sc` in which the keys and values are
deep-copied. This function can be used to reclaim memory after many
deletions. Time: O(*cn* log *n*)
"""
function packdeepcopy(m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering}
    w = SortedDict(Dict{K,D}(),orderobject(m))
    for (k,v) in m
        newk = deepcopy(k)
        newv = deepcopy(v)
        w[newk] = newv
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
function Base.merge!(m::SortedDict{K,D,Ord},
                others::AbstractDict{K,D}...) where {K,D,Ord <: Ordering}
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
function Base.merge(m::SortedDict{K,D,Ord},
               others::AbstractDict{K,D}...) where {K,D,Ord <: Ordering}
    result = packcopy(m)
    merge!(result, others...)
    return result
end


"""
    empty(sc)

Returns a new `SortedDict`, `SortedMultiDict`, or `SortedSet` of the same
type and with the same ordering as `sc` but with no entries (i.e.,
empty). Time: O(1)
"""
Base.empty(m::SortedDict{K,D,Ord}) where {K,D,Ord<:Ordering} =
    SortedDict{K,D,Ord}(orderobject(m))

OrderedCollections.isordered(::Type{T}) where {T<:SortedDict} = true
