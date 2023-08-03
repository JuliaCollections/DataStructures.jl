## A SortedSet is a wrapper around balancedTree with
## methods similiar to those of the julia Set.


"""
    SortedSet(iter, o=Forward)
and
    `SortedSet{K}(iter, o=Forward)`
and
    `SortedSet(o, iter)`
and
    `SortedSet{K}(o, iter)`

Construct a SortedSet using keys given by iterable `iter` (e.g., an
array) and ordering object `o`. The ordering object defaults to
`Forward` if not specified.
"""
mutable struct SortedSet{K, Ord <: Ordering} <: AbstractSet{K}
    bt::BalancedTree23{K,Nothing,Ord}

    function SortedSet{K,Ord}(o::Ord=Forward, iter=[]) where {K,Ord<:Ordering}
        sorted_set = new{K,Ord}(BalancedTree23{K,Nothing,Ord}(o))

        for item in iter
            push!(sorted_set, item)
        end

        return sorted_set
    end
end

"""
    SortedSet()

Construct a `SortedSet{Any}` with `Forward` ordering.

**Note that a key type of `Any` or any other abstract type will lead
to slow performance.**
"""
SortedSet() = SortedSet{Any,ForwardOrdering}(Forward)

"""
    SortedSet(o)

Construct a `SortedSet{Any}` with `o` ordering.

**Note that a key type of `Any` or any other abstract type will lead
to slow performance.**
"""
SortedSet(o::O) where {O<:Ordering} = SortedSet{Any,O}(o)

# To address ambiguity warnings on Julia v0.4
SortedSet(o1::Ordering, o2::Ordering) =
    throw(ArgumentError("SortedSet with two parameters must be called with an Ordering and an interable"))
SortedSet(o::Ordering, iter) = sortedset_with_eltype(o, iter, eltype(iter))
SortedSet(iter, o::Ordering=Forward) = sortedset_with_eltype(o, iter, eltype(iter))

"""
    SortedSet{K}()

Construct a `SortedSet` of keys of type `K` with `Forward` ordering.
"""
SortedSet{K}() where {K} = SortedSet{K,ForwardOrdering}(Forward)

"""
    SortedSet{K}(o)

Construct a `SortedSet` of keys of type `K` with ordering given according
`o` parameter.
"""
SortedSet{K}(o::O) where {K,O<:Ordering} = SortedSet{K,O}(o)

# To address ambiguity warnings on Julia v0.4
SortedSet{K}(o1::Ordering,o2::Ordering) where {K} =
    throw(ArgumentError("SortedSet with two parameters must be called with an Ordering and an interable"))
SortedSet{K}(o::Ordering, iter) where {K} = sortedset_with_eltype(o, iter, K)
SortedSet{K}(iter, o::Ordering=Forward) where {K} = sortedset_with_eltype(o, iter, K)

sortedset_with_eltype(o::Ord, iter, ::Type{K}) where {K,Ord} = SortedSet{K,Ord}(o, iter)

const SetSemiToken = IntSemiToken

# The following definition was moved to tokens2.jl
# const SetToken = Tuple{SortedSet, IntSemiToken}

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.

@inline function findkey(m::SortedSet, k_)
    ll, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(exactfound ? ll : 2)
end


## This function inserts an item into the tree.
## It returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

"""
    insert!(sc, k)

Argument `sc` is a SortedSet and `k` is a key. This inserts the key
into the container. If the key is already present, this overwrites
the old value. (This is not necessarily a no-op; see below for
remarks about the customizing the sort order.) The return value is a
pair whose first entry is boolean and indicates whether the
insertion was new (i.e., the key was not previously present) and the
second entry is the semitoken of the new entry. Time: O(*c* log *n*)
"""
@inline function Base.insert!(m::SortedSet, k_)
    b, i = insert!(m.bt, convert(keytype(m),k_), nothing, false)
    return b, IntSemiToken(i)
end

## push! is similar to insert but returns the set
"""
    push!(sc, k)

Argument `sc` is a SortedSet and `k` is a key. This inserts the key
into the container. If the key is already present, this overwrites
the old value. (This is not necessarily a no-op; see below for
remarks about the customizing the sort order.) The return value is
`sc`. Time: O(*c* log *n*)
"""
@inline function Base.push!(m::SortedSet, k_)
    b, i = insert!(m.bt, convert(keytype(m),k_), nothing, false)
    return m
end


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
@inline function Base.first(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k
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
@inline function Base.last(m::SortedSet)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k
end


@inline function Base.in(k_, m::SortedSet)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    return exactfound
end

"""
    keytype(sc)

Returns the key type for SortedDict, SortedMultiDict and SortedSet.
This function may also be applied to the type itself. Time: O(1)
"""
@inline Base.keytype(m::SortedSet{K,Ord}) where {K,Ord <: Ordering} = K
@inline Base.keytype(::Type{SortedSet{K,Ord}}) where {K,Ord <: Ordering} = K

"""
    ordtype(sc)

Returns the order type for SortedDict, SortedMultiDict and
SortedSet. This function may also be applied to the type itself.
Time: O(1)
"""
@inline ordtype(m::SortedSet{K,Ord}) where {K,Ord <: Ordering} = Ord
@inline ordtype(::Type{SortedSet{K,Ord}}) where {K,Ord <: Ordering} = Ord

"""
    orderobject(sc)

Returns the order object used to construct the container. Time: O(1)
"""
@inline orderobject(m::SortedSet) = m.bt.ord

"""
    haskey(sc,k)

Returns true if key `k` is present for SortedDict, SortedMultiDict
or SortedSet `sc`. For SortedSet, `haskey(sc,k)` is a synonym for
`in(k,sc)`. For SortedDict and SortedMultiDict, `haskey(sc,k)` is
equivalent to `in(k,keys(sc))`. Time: O(*c* log *n*)
"""
Base.haskey(m::SortedSet, k_) = in(k_, m)

"""
    delete!(sc, k)

Argument `sc` is a SortedDict or SortedSet and `k` is a key. This
operation deletes the item whose key is `k`. It is a `KeyError` if
`k` is not a key of an item in the container. After this operation
is complete, any token addressing the deleted item is invalid.
Returns `sc`. Time: O(*c* log *n*)
"""
@inline function Base.delete!(m::SortedSet, k_)
    i, exactfound = findkey(m.bt,convert(keytype(m),k_))
    if exactfound
        delete!(m.bt, i)
    end
    return m
end


"""
    pop!(sc, k[, default])

Deletes the item with key `k` in SortedDict or SortedSet `sc` and
returns the value that was associated with `k` in the case of
SortedDict or `k` itself in the case of SortedSet. If `k` is not in `sc`
return `default`, or throw a `KeyError` if `default` is not specified.
Time: O(*c* log *n*)
"""
@inline function Base.pop!(m::SortedSet, k_)
    k = convert(keytype(m),k_)
    i, exactfound = findkey(m.bt, k)
    !exactfound && throw(KeyError(k_))
    d = m.bt.data[i].d
    delete!(m.bt, i)
    return k
end

@inline function Base.pop!(m::SortedSet, k_, default)
    k = convert(keytype(m),k_)
    i, exactfound = findkey(m.bt, k)
    !exactfound && return default
    d = m.bt.data[i].d
    delete!(m.bt, i)
    return k
end

"""
    pop!(ss)

Deletes the item with first key in SortedSet `ss` and returns the
key. A `BoundsError` results if `ss` is empty. Time: O(*c* log *n*)
"""
@inline function Base.pop!(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    k = m.bt.data[i].k
    delete!(m.bt, i)
    return k
end


## Check if two SortedSets are equal in the sense of containing
## the same K entries.  This sense of equality does not mean
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
function Base.isequal(m1::SortedSet, m2::SortedSet)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedSets unless their element types and ordering objects are equal"))
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
        k1 = deref((m1,p1))
        k2 = deref((m2,p2))
        if !eq(ord,k1,k2)
            return false
        end
        p1 = advance((m1,p1))
        p2 = advance((m2,p2))
    end
end

"""
    union!(ss, iterable)

This function inserts each item from the second argument (which must
iterable) into the SortedSet `ss`. The items must be convertible to
the key-type of `ss`. Time: O(*ci* log *n*) where *i* is the number
of items in the iterable argument.
"""
function Base.union!(m1::SortedSet{K,Ord}, iterable_item) where {K, Ord <: Ordering}
    for k in iterable_item
        push!(m1,convert(K,k))
    end
    return m1
end

"""
    union(ss, iterable...)

This function creates a new SortedSet (the return argument) and
inserts each item from `ss` and each item from each iterable
argument into the returned SortedSet. Time: O(*cn* log *n*) where
*n* is the total number of items in all the arguments.
"""
function Base.union(m1::SortedSet, others...)
    mr = packcopy(m1)
    for m2 in others
        union!(mr, m2)
    end
    return mr
end

function intersect2(m1::SortedSet{K, Ord}, m2::SortedSet{K, Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendsemitoken(m1) || p2 == pastendsemitoken(m2)
            return mi
        end
        k1 = deref((m1,p1))
        k2 = deref((m2,p2))
        if lt(ord,k1,k2)
            p1 = advance((m1,p1))
        elseif lt(ord,k2,k1)
            p2 = advance((m2,p2))
        else
            push!(mi,k1)
            p1 = advance((m1,p1))
            p2 = advance((m2,p2))
        end
    end
end

"""
    intersect(ss, others...)

Each argument is a SortedSet with the same key and order type. The
return variable is a new SortedSet that is the intersection of all
the sets that are input. Time: O(*cn* log *n*), where *n* is the
total number of items in all the arguments.
"""
function Base.intersect(m1::SortedSet{K,Ord}, others::SortedSet{K,Ord}...) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    for s2 in others
        if !isequal(ord, orderobject(s2))
            throw(ArgumentError("Cannot intersect two SortedSets unless their ordering objects are equal"))
        end
    end
    if length(others) == 0
        return m1
    else
        mi = intersect2(m1, others[1])
        for s2 = others[2:end]
            mi = intersect2(mi, s2)
        end
        return mi
    end
end

"""
    symdiff(ss1, ss2)

The two argument are sorted sets with the same key and order type.
This operation computes the symmetric difference, i.e., a sorted set
containing entries that are in one of `ss1`, `ss2` but not both.
Time: O(*cn* log *n*), where *n* is the total size of the two
containers.
"""
function Base.symdiff(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        throw(ArgumentError("Cannot apply symdiff to two SortedSets unless their ordering objects are equal"))
    end
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        m1end = p1 == pastendsemitoken(m1)
        m2end = p2 == pastendsemitoken(m2)
        if m1end && m2end
            return mi
        elseif m1end
            push!(mi, deref((m2,p2)))
            p2 = advance((m2,p2))
        elseif m2end
            push!(mi, deref((m1,p1)))
            p1 = advance((m1,p1))
        else
            k1 = deref((m1,p1))
            k2 = deref((m2,p2))
            if lt(ord,k1,k2)
                push!(mi, k1)
                p1 = advance((m1,p1))
            elseif lt(ord,k2,k1)
                push!(mi, k2)
                p2 = advance((m2,p2))
            else
                p1 = advance((m1,p1))
                p2 = advance((m2,p2))
            end
        end
    end
end

"""
    setdiff(ss1, ss2)

The two arguments are sorted sets with the same key and order type.
This operation computes the difference, i.e., a sorted set
containing entries that in are in `ss1` but not `ss2`. Time: O(*cn*
log *n*), where *n* is the total size of the two containers.
"""
function Base.setdiff(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        throw(ArgumentError("Cannot apply setdiff to two SortedSets unless their ordering objects are equal"))
    end
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendsemitoken(m1)
            return mi
        elseif p2 == pastendsemitoken(m2)
            push!(mi, deref((m1,p1)))
            p1 = advance((m1,p1))
        else
            k1 = deref((m1,p1))
            k2 = deref((m2,p2))
            if lt(ord,k1,k2)
                push!(mi, deref((m1,p1)))
                p1 = advance((m1,p1))
            elseif lt(ord,k2,k1)
                p2 = advance((m2,p2))
            else
                p1 = advance((m1,p1))
                p2 = advance((m2,p2))
            end
        end
    end
end

"""
    setdiff!(ss, iterable)

This function deletes items in `ss` that appear in the second
argument. The second argument must be iterable and its entries must
be convertible to the key type of m1. Time: O(*cm* log *n*), where
*n* is the size of `ss` and *m* is the number of items in
`iterable`.
"""
function Base.setdiff!(m1::SortedSet, iterable)
    for p in iterable
        i = findkey(m1, p)
        if i != pastendsemitoken(m1)
            delete!((m1,i))
        end
    end
end

"""
    issubset(iterable, ss)

This function checks whether each item of the first argument is an
element of the SortedSet `ss`. The entries must be convertible to
the key-type of `ss`. Time: O(*cm* log *n*), where *n* is the sizes
of `ss` and *m* is the number of items in `iterable`.
"""
function Base.issubset(iterable, m2::SortedSet)
    for k in iterable
        if !in(k, m2)
            return false
        end
    end
    return true
end

# Standard copy functions use packcopy - that is, they retain elements but not
# the identical structure.
Base.copymutable(m::SortedSet) = packcopy(m)
Base.copy(m::SortedSet) = packcopy(m)

"""
    packcopy(sc)

This returns a copy of `sc` in which the data is packed. When
deletions take place, the previously allocated memory is not
returned. This function can be used to reclaim memory after many
deletions. Time: O(*cn* log *n*)
"""
function packcopy(m::SortedSet{K,Ord}) where {K,Ord <: Ordering}
    w = SortedSet(K[], orderobject(m))
    for k in m
        push!(w, k)
    end
    return w
end

"""
    packdeepcopy(sc)

This returns a packed copy of `sc` in which the keys and values are
deep-copied. This function can be used to reclaim memory after many
deletions. Time: O(*cn* log *n*)
"""
function packdeepcopy(m::SortedSet{K,Ord}) where {K, Ord <: Ordering}
    w = SortedSet(K[], orderobject(m))
    for k in m
        newk = deepcopy(k)
        push!(w, newk)
    end
    return w
end


function Base.show(io::IO, m::SortedSet{K,Ord}) where {K,Ord <: Ordering}
    print(io, "SortedSet(")
    keys = K[]
    for k in m
        push!(keys, k)
    end
    print(io, keys)
    println(io, ",")
    print(io, orderobject(m))
    print(io, ")")
end

"""
    empty(sc)

Returns a new `SortedDict`, `SortedMultiDict`, or `SortedSet` of the same
type and with the same ordering as `sc` but with no entries (i.e.,
empty). Time: O(1)
"""
Base.empty(m::SortedSet{K,Ord}) where {K,Ord<:Ordering} = SortedSet{K,Ord}(orderobject(m))
