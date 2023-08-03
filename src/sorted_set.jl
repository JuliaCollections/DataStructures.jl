## A SortedSet is a wrapper around balancedTree with
## methods similar to those of the julia Set.

mutable struct SortedSet{K, Ord <: Ordering}  <: AbstractSet{K}
    bt::BalancedTree23{K,Nothing,Ord}
end


"""
    SortedSet{K,Ord}(o::Ord=Forward) where {K, Ord<:Ordering}
    SortedSet{K,Ord}(o::Ord, iter) where {K, Ord<:Ordering}

Construct a SortedSet of eltype `K`using from elements
produced by  iterable `iter` (e.g., an
array) and ordering object `o`.  Running time: O(*cn* log *n*)
where *n* is the length of iterable.
"""
SortedSet{K,Ord}(o::Ord=Forward) where{K,Ord<:Ordering} =
    SortedSet{K,Ord}(BalancedTree23{K,Nothing,Ord}(o))

function SortedSet{K,Ord}(o::Ord, iter) where {K,Ord<:Ordering}
    sorted_set = SortedSet{K,Ord}(BalancedTree23{K,Nothing,Ord}(o))
    for item in iter
        push!(sorted_set, item)
    end
    return sorted_set
end


"""
    SortedSet(o::Ord=Forward) where {Ord <: Ordering}
    SortedSet{K}(o::Ord=Forward) where {K, Ord<:Ordering}


Construct an empty `SortedSet` with `Forward` ordering.  The first form
assumes element type of `Any`.  Time: O(1).

**Note that an element type of `Any` or any other abstract type will lead
to slow performance.**
"""
SortedSet(o::Ord=Forward) where {Ord<:Ordering} = SortedSet{Any,Ord}(o)
SortedSet{K}(o::Ord=Forward) where {K,Ord <: Ordering} =
    SortedSet{K,Ord}(o)


"""
    SortedSet(o::Ordering, iter)
    SortedSet(iter, o::Ordering=Forward)
    SortedSet{K}(o::Ordering, iter)
    SortedSet{K}(iter, o::Ordering=Forward)

Construct a sorted set from an iterable `iter` using order o.   In
the first two forms, the element type is inferred from the
iterable, which requires copying the data twice.  Therefore,
the second two forms (specifying `K` explicitly) are more efficient.
Time: O(*cn* log *n*)
"""
function SortedSet(o::Ordering, iter)
    c = collect(iter)
    SortedSet{eltype(c),typeof(o)}(o, c)
end
SortedSet(iter, o::Ordering=Forward) = SortedSet(o, iter)
SortedSet{K}(o::Ordering, iter) where {K} = SortedSet{K,typeof(o)}(o, iter)
SortedSet{K}(iter, o::Ordering=Forward) where {K} = SortedSet{K}(o, iter)



"""
    SortedSet{K}(::Val{true}, iterable) where {K}
    SortedSet{K}(::Val{true}, iterable, ord::Ord) where {K, Ord <: Ordering}

Construct a `SortedSet` from an iterable whose entries
have type `K` and that is already in sorted ordered. No duplicates
allowed.  The first form assumes Forward ordering.
Time: O(*cn*).
"""
SortedSet{K}(::Val{true}, iterable) where {K} =
    SortedSet{K}(Val(true), iterable, Forward)
function SortedSet{K}(::Val{true},
                      iterable,
                      ord::Ord) where {K, Ord <: Ordering}
    SortedSet{K, Ord}(BalancedTree23{K,Nothing,Ord}(Val(true),
                                                    ((k,nothing) for k in iterable),
                                                    ord,
                                                    false))
end

# The following is needed to resolve ambiguities

SortedSet{K}(::Val{true}, ::Ordering) where {K} =
    throw(ArgumentError("Not a valid SortedSet constructor"))
SortedSet(::Ordering, ::Ordering) =
    throw(ArgumentError("Not a valid SortedSet constructor"))
SortedSet{K}(::Ordering,::Ordering) where {K} =
    throw(ArgumentError("Not a valid SortedSet constructor"))


const SetSemiToken = IntSemiToken


"""
    findkey(m::SortedSet, k)

Return the semitoken of the element `k` in sorted set `m`.
If the element is not present in `m`, then the past-end semitoken
is returned.  Time: O(*c* log *n*)
"""
@inline function findkey(m::SortedSet, k_)
    ll, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(exactfound ? ll : 2)
end


"""
    DataStructures.push_return_semitoken!(ss::SortedSet, k)

Insert the element `k`
into the SortedSet `sc`.
If `k` is already present, this overwrites
the old value. (This is not necessarily a no-op; see remarks about the 
customizing the sort order.) Unlike `push!`,
the return value is a
pair whose first entry is boolean and indicates whether the
insertion was new (i.e., the key was not previously present) and the
second entry is the semitoken of the new entry.   This function
replaces the deprecated `insert!`.
Time: O(*c* log *n*)
"""
@inline function push_return_semitoken!(m::SortedSet, k_)
    b, i = insert!(m.bt, convert(keytype(m),k_), nothing, false)
    return b, IntSemiToken(i)
end


"""
    Base.push!(ss::SortedSet, k)

Insert the element `k` into the sorted set `ss`.
If the `k` is already present, this overwrites
the old value. (This is not necessarily a no-op; see remarks about the 
customizing the sort order.) 
See also [`push_return_semitoken!(ss::SortedSet, k)`](@ref).
The return value is
`ss`. Time: O(*c* log *n*)
"""
@inline function Base.push!(m::SortedSet, k_)
    b, i = insert!(m.bt, convert(keytype(m),k_), nothing, false)
    return m
end



"""
    Base.in(k,m::SortedSet)

Return `true` iff
element `k` is in sorted set `m` is a sorted set.
Unlike the `in` function for
`Set`, this routine will thrown an error if `k` is not 
convertible to `eltype(m)`.  Time: O(*c* log *n*)
"""
@inline function Base.in(k_, m::SortedSet)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    return exactfound
end

@inline Base.keytype(m::SortedSet{K,Ord}) where {K,Ord <: Ordering} = K
@inline Base.keytype(::Type{SortedSet{K,Ord}}) where {K,Ord <: Ordering} = K



"""
    Base.delete!(ss::SortedSet, k)

Delete element `k` from `sc`.  After this operation
is complete, a token addressing the deleted item is invalid.
Returns `sc`.  if `k` is not present, this operation is a no-op.
Time: O(*c* log *n*)
"""
@inline function Base.delete!(m::SortedSet, k_)
    i, exactfound = findkey(m.bt,convert(keytype(m),k_))
    if exactfound
        delete!(m.bt, i)
    end
    return m
end


"""
    Base.pop!(ss::SortedSet, k)
    Base.pop!(ss::SortedSet, k, default)

Delete the item with key `k` in `ss` and
return the item that compares equal to `k` according to the
sort order (which is not necessarily `k`, since equality in the
sort-order does not necessarily imply hash-equality). If `k` is not found,
return `default`, or throw a `KeyError` if `default` is not specified.
Time: O(*c* log *n*)
"""
@inline function Base.pop!(m::SortedSet, k_)
    k = convert(keytype(m),k_)
    i, exactfound = findkey(m.bt, k)
    !exactfound && throw(KeyError(k_))
    k2 = m.bt.data[i].k
    delete!(m.bt, i)
    return k2
end

@inline function Base.pop!(m::SortedSet, k_, default)
    k = convert(keytype(m),k_)
    i, exactfound = findkey(m.bt, k)
    !exactfound && return default
    delete!(m.bt, i)
    return k
end

"""
    Base.popfirst!(ss::SortedSet)

Delete the item with first key in SortedSet `ss` and returns the
key.  This function was named `pop!` in a previous version of the package.
 A `BoundsError` results if `ss` is empty. Time: O(log *n*)
"""
@inline function Base.popfirst!(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    k = m.bt.data[i].k
    delete!(m.bt, i)
    return k
end

Base.pop!(m::SortedSet) = error("pop!(::SortedSet) is disabled in this version; refer to popfirst! and `poplast! in the docs")



"""
    poplast!(ss::SortedSet)

Delete the item with last key in SortedSet `ss` and returns the
key. A `BoundsError` results if `ss` is empty.   This function will
be renamed `Base.pop!` in a future version of the package.
Time: O(log *n*)
"""
@inline function poplast!(m::SortedSet)
    i = endloc(m.bt)
    i == 2 && throw(BoundsError())
    k = m.bt.data[i].k
    delete!(m.bt, i)
    return k
end



## Check if two SortedSets are equal in the sense of containing
## the same K entries.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.
"""
    Base.isequal(ss1::SortedSet{K,Ord}, ss2::SortedSet{K,Ord}) where {K,Ord <: Ordering}
    Base.issetequal(ss1::SortedSet{K,Ord}, ss2::SortedSet{K,Ord}) where {K,Ord <: Ordering}

Check if two sorted sets are equal in the sense that they contain
the same items.
Note that `isequal` in this sense does not imply correspondence
between semitokens for items in `sc1` with those for `sc2`.  Time:
O(*cn*) where n is the size of the smaller container. 
If the two sorted sets have `K`, different `Ord`, or 
different order objects, then a
fallback routine `isequal(::AbstractSet, ::AbstractSet)` is invoked.
"""
function Base.isequal(m1::SortedSet{K, Ord}, m2::SortedSet{K, Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    if ord != orderobject(m2)
        return invoke(issetequal, Tuple{AbstractSet, AbstractSet}, m1, m2)
    end
    p1 = firstindex(m1)
    p2 = firstindex(m2)
    while true
        p1 == pastendsemitoken(m1) && return p2 == pastendsemitoken(m2)
        p2 == pastendsemitoken(m2) && return false
        @inbounds k1 = deref((m1,p1))
        @inbounds k2 = deref((m2,p2))
        !eq(ord,k1,k2) && return false
        @inbounds p1 = advance((m1,p1))
        @inbounds p2 = advance((m2,p2))
    end
end


Base.issetequal(m1::SortedSet, m2::SortedSet) = isequal(m1, m2)


"""
    Base.union!(ss::SortedSet, iterable...)

Insert each item among the second and following
arguments  (which must be
iterable) into the SortedSet `ss`. The items must be convertible to
the key-type of `ss`. Time: O(*cN* log *N*) where *N* is the total number
of items in the iterable arguments.  
"""
function Base.union!(m1::SortedSet, iterable...)
    for iter in iterable
        for k in iter
            push!(m1,convert(eltype(m1),k))
        end
    end
    return m1
end

struct UnionManySortedSets{K, Ord <: Ordering}
    vec::Vector{SortedSet{K, Ord}}
end

function Base.iterate(ss::UnionManySortedSets{K, Ord},
                      state = [firstindex(ss.vec[k]) for k=1:length(ss.vec)]) where
{K, Ord <: Ordering}
    ord = orderobject(ss.vec[1])
    N = length(ss.vec)
    firsti = 0
    for i = 1 : N
        if state[i] != pastendsemitoken(ss.vec[i])
            firsti = i
            break
        end
    end
    firsti == 0 && return nothing
    foundi = firsti
    @inbounds firstk = deref((ss.vec[firsti], state[firsti]))
    for i = firsti + 1 : N
        if state[i] != pastendsemitoken(ss.vec[i])
            @inbounds k2 = deref((ss.vec[i], state[i]))
            if !lt(ord, firstk, k2)
                foundi = i
                firstk = k2
            end
        end
    end
    for i = firsti : N
        if state[i] != pastendsemitoken(ss.vec[i]) &&
            @inbounds eq(ord, deref((ss.vec[i], state[i])), firstk)
            @inbounds state[i] = advance((ss.vec[i], state[i]))
        end
    end
    (firstk, state)
end



"""
    Base.union(ss::SortedSet, iterable...)

Compute and return
the union of a sorted set and one or more iterables.  They must have the same
keytype.  If they are all sorted sets with the same order object, then the
required time is O(*cn*), where *n* is the total size.  If not,
then the fallback routine requires time O(*cn* log *n*).

"""
function Base.union(m1::SortedSet, others...)
    mr = packcopy(m1)
    for m2 in others
        union!(mr, m2)
    end
    return mr
end

function Base.union(s1::SortedSet{K,Ord}, others::SortedSet{K,Ord}...) where
{K, Ord <: Ordering}
    ss = UnionManySortedSets{K, Ord}(SortedSet{K,Ord}[s1])
    for s in others
        if orderobject(s) != orderobject(s1)
            return invoke(union,
                          Tuple{SortedSet, Vararg{Any}},
                          s1, others...)
        end
        push!(ss.vec, s)
    end
    SortedSet{K}(Val(true), ss, orderobject(s1))
end





struct IntersectTwoSortedSets{K, Ord <: Ordering}
    m1::SortedSet{K,Ord}
    m2::SortedSet{K,Ord}
end

struct TwoSortedSets_State
    p1::IntSemiToken
    p2::IntSemiToken
end

function Base.iterate(twoss::IntersectTwoSortedSets,
                      state = TwoSortedSets_State(firstindex(twoss.m1),
                                                  firstindex(twoss.m2)))
    m1 = twoss.m1
    m2 = twoss.m2
    ord = orderobject(m1)
    p1 = state.p1
    p2 = state.p2
    while p1 != pastendsemitoken(m1) && p2 != pastendsemitoken(m2)
        @inbounds k1 = deref((m1, p1))
        @inbounds k2 = deref((m2, p2))
        if lt(ord, k1, k2)
            @inbounds p1 = advance((m1, p1))
            continue
        end
        if lt(ord, k2, k1)
            @inbounds p2 = advance((m2, p2))
            continue
        end
        @inbounds return (k1, TwoSortedSets_State(advance((m1, p1)),
                                                  advance((m2, p2))))
    end
    return nothing
end


function intersect2(m1::SortedSet{K, Ord}, m2::SortedSet{K, Ord}) where {K, Ord <: Ordering}
    if orderobject(m1) != orderobject(m2)
        return invoke(intersect2, Tuple{SortedSet{K, Ord}, Any}, m1, m2)
    end
    SortedSet{K}(Val(true),
                 IntersectTwoSortedSets(m1, m2),
                 orderobject(m1))
end


function intersect2(m1::SortedSet{K,Ord}, iterable) where {K, Ord <: Ordering}
    mi = SortedSet{K, Ord}(orderobject(m1))
    for k_ in iterable
        k = convert(K,k_)
        k in m1 && push!(mi, k)
    end
    mi
end
        



"""
    Base.intersect(ss::SortedSet, others...)

Intersect SortedSets with other SortedSets or other iterables and return
the intersection as a new SortedSet.
Time: O(*cn*), where *n* is the
total number of items in all the arguments if all the arguments are
SortedSets of the same type and same order object.  Otherwise, the
time is O(*cn* log *n*)

"""
function Base.intersect(m1::SortedSet{K,Ord}, others...) where {K, Ord <: Ordering}
    if length(others) == 0
        return packcopy(m1)
    end
    mi = intersect2(m1, others[1])
    for s2 = others[2:end]
        mi = intersect2(mi, s2)
    end
    mi
end


struct SymdiffTwoSortedSets{K,Ord <: Ordering}
    m1::SortedSet{K,Ord}
    m2::SortedSet{K,Ord}
end

function Base.iterate(twoss::SymdiffTwoSortedSets,
                      state = TwoSortedSets_State(firstindex(twoss.m1),
                                                  firstindex(twoss.m2)))
    m1 = twoss.m1
    m2 = twoss.m2
    ord = orderobject(m1)
    p1 = state.p1
    p2 = state.p2
    while true
        m1end = p1 == pastendsemitoken(m1)
        m2end = p2 == pastendsemitoken(m2)
        if m1end && m2end
            return nothing
        end
        if m1end
            @inbounds return (deref((m2, p2)),
                              TwoSortedSets_State(p1, advance((m2,p2))))
        end
        if m2end
            @inbounds return (deref((m1, p1)),
                              TwoSortedSets_State(advance((m1,p1)), p2))
        end
        @inbounds k1 = deref((m1, p1))
        @inbounds k2 = deref((m2, p2))
        if lt(ord, k1, k2)
            @inbounds return (k1, TwoSortedSets_State(advance((m1,p1)), p2))
        end
        if lt(ord, k2, k1)
            @inbounds return (k2, TwoSortedSets_State(p1, advance((m2,p2))))
        end
        @inbounds p1 = advance((m1,p1))
        @inbounds p2 = advance((m2,p2))
    end
end

"""
    Base.symdiff(ss1::SortedSet, iterable)

Compute and
return the symmetric difference of `ss1` and `iterable`, i.e., a sorted set
containing entries that are in one of `ss1` or `iterable` but not both.
Time: O(*cn*), where *n* is the total size of the two
containers if both are sorted sets with the same key and order objects.
Otherwise, the time is O(*cn* log *n*)
"""
function Base.symdiff(m1::SortedSet{K,Ord}, iterable) where {K, Ord <: Ordering}
    ms = SortedSet{K,Ord}(orderobject(m1))
    m1seen = SortedSet{K,Ord}(orderobject(m1))
    for k_ in iterable
        k = convert(K,k_)
        if k in m1
            push!(m1seen, k)
        else
            push!(ms, k)
        end
    end
    for k in m1
        if !(k in m1seen)
            push!(ms, k)
        end
    end
    ms
end

function Base.symdiff(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    if ord != orderobject(m2)
        return invoke(symdiff, Tuple{SortedSet{K,Ord}, Any}, m1, m2)
    end
    SortedSet{K}(Val(true), SymdiffTwoSortedSets(m1, m2), ord)
end


struct SetdiffTwoSortedSets{K, Ord <: Ordering}
    m1::SortedSet{K,Ord}
    m2::SortedSet{K,Ord}
end

function Base.iterate(twoss::SetdiffTwoSortedSets,
                      state = TwoSortedSets_State(firstindex(twoss.m1),
                                                  firstindex(twoss.m2)))
    m1 = twoss.m1
    m2 = twoss.m2
    ord = orderobject(m1)
    p1 = state.p1
    p2 = state.p2
    while true
        m1end = p1 == pastendsemitoken(m1)
        m2end = p2 == pastendsemitoken(m2)
        if m1end
            return nothing
        end
        if m2end
            @inbounds return (deref((m1, p1)), TwoSortedSets_State(advance((m1,p1)), p2))
        end
        @inbounds k1 = deref((m1, p1))
        @inbounds k2 = deref((m2, p2))
        if lt(ord, k1, k2)
            @inbounds return (k1, TwoSortedSets_State(advance((m1,p1)), p2))
        end
        if !lt(ord, k2, k1)
            @inbounds p1 = advance((m1,p1))
        end
        @inbounds p2 = advance((m2, p2))
    end
end

        
"""
    Base.setdiff(ss1::SortedSet{K,Ord}, ss2::SortedSet{K,Ord}) where {K, Ord<:Ordering}
    Base.setdiff(ss1::SortedSet, others...)

Return the set difference, i.e., a sorted set containing entries in `ss1` but not
in `ss2` or successive arguments.   Time for the first form: O(*cn*)
where *n* is the total size of both sets provided that they are both
sorted sets of the same type and order object.  
The second form computes the set difference
between `ss1` and all the others, which are all iterables.  The second
form requires O(*cn* log *n*) time.
"""
function Base.setdiff(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    if ord != orderobject(m2)
        return invoke(setdiff, Tuple{SortedSet{K,Ord}, Vararg{Any}}, m1, m2)
    end
    SortedSet{K}(Val(true), SetdiffTwoSortedSets(m1,m2), ord)
end


function Base.setdiff(m1::SortedSet{K,Ord}, others...) where {K, Ord <: Ordering}
    ms = packcopy(m1)
    setdiff!(ms, others...)
    ms
end


"""
    Base.setdiff!(ss::SortedSet, iterable..)

Delete items in `ss` that appear in any of the
iterables. The arguments after the first  must be iterables each
of whose entries must  convertible to the key type of m1. 
Time: O(*cm* log *n*), where *n* is the size of `ss` and *m* is the 
total number of items in iterable.
"""
function Base.setdiff!(m1::SortedSet, others...)
    for iterable in others
        for p in iterable
            i = findkey(m1, convert(eltype(m1), p))
            i != pastendsemitoken(m1) &&  delete!((m1,i))
        end
    end
end


# TODO: implement a jump-forward method so that issubset runs in time
# O(*m* log (*n*/*m*)) when both sets are sorted sets.

"""
    Base.issubset(iterable, ss::SortedSet)

Check whether each item of the first argument is an
element of  `ss`. The entries must be convertible to
the key-type of `ss`. Time: O(*cm* log *n*), where *n* is the size
of `ss` and *m* is the number of items in `iterable`.  If both are
sorted sets of the same keytype and order object and if *m* > *n* / log *n*,
then an algorithm whose running time is O(*c*(*m*+*n*)) is used.
"""
function Base.issubset(iterable, m2::SortedSet)
    for k in iterable
        if !(k in m2)
            return false
        end
    end
    return true
end

function Base.issubset(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}
    ord = orderobject(m1)
    if ord != orderobject(m2) ||
        length(m1) < length(m2) / log2(length(m2) + 2)
        return invoke(issubset, Tuple{Any, SortedSet}, m1, m2)
    end
    p1 = firstindex(m1)
    p2 = firstindex(m2)
    while p1 != pastendsemitoken(m1)
        p2 == pastendsemitoken(m2) && return false
        @inbounds k1 = deref((m1, p1))
        @inbounds k2 = deref((m2, p2))
        if eq(ord, k1, k2)
            @inbounds p1 = advance((m1,p1))
            @inbounds p2 = advance((m2,p2))
        elseif lt(ord, k1,k2)
            return false
        else
            @inbounds p2 = advance((m2,p2))
        end
    end
    return true
end
            
# Standard copy functions use packcopy - that is, they retain elements but not
# the identical structure.
Base.copymutable(m::SortedSet) = packcopy(m)
Base.copy(m::SortedSet) = packcopy(m)

"""
    copy(sc::SortedSet)
    copy(sc::SortedDict)
    copy(sc::SortedMultiDict)
    packcopy(sc::SortedSet)
    packcopy(sc::SortedDict)
    packcopy(sc::SortedMultiDict)

Return a copy of `sc`, where `sc` is a sorted
container, in which the data is packed. When
deletions take place, the previously allocated memory is not
returned. This function can be used to reclaim memory after many
deletions. Time: O(*cn*)

Note that the semitokens valid for the original container are no
longer valid for the copy because the indexing structure is rebuilt
by these copies.  If an exact copy is needed in which semitokens
remain valid, use `Base.deepcopy`.
"""
function packcopy(m::SortedSet{K,Ord}) where {K,Ord <: Ordering}
    SortedSet{K}(Val(true), m, orderobject(m))
end


"""
    packdeepcopy(sc::SortedSet)
    packdeepcopy(sc::SortedDict)
    packdeepcopy(sc::SorteMultiDict)

Return a packed copy of `sc`, where `sc` is a sorted
container in which the keys and values are
deep-copied. This function can be used to reclaim memory after many
deletions. Time: O(*cn*)
"""
packdeepcopy(m::SortedSet{K,Ord}) where {K, Ord <: Ordering} =
    SortedSet{K}(Val(true), deepcopy(m), orderobject(m))


"""
    Base.empty(sc)

Return a new `SortedDict`, `SortedMultiDict`, or `SortedSet` of the same
type and with the same ordering as `sc` but with no entries (i.e.,
empty). Time: O(1)
"""
function Base.empty(m::SortedSet{K,Ord}, ::Type{U}=K) where {K,Ord<:Ordering,U}
    return Base.emptymutable(m, U)
end
function Base.emptymutable(m::SortedSet{K,Ord}, ::Type{U}=K) where {K,Ord<:Ordering,U}
    return SortedSet{U,Ord}(orderobject(m))
end
