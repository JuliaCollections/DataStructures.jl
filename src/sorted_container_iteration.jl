## Functions in this file implement many kinds of iterations over
## SortedDict, SortedMultiDict, and SortedSet.
## The iteration state is a "semitoken".
## A "token" is a (container,index_into_container) 2-tuple,
## while semitokens are the second part, index_into_container.

# From tokens.jl:
# abstract type AbstractSemiToken end

# struct IntSemiToken <: AbstractSemiToken
#     address::Int
# end

const SDMContainer = Union{SortedDict, SortedMultiDict}
const SortedContainer = Union{SDMContainer, SortedSet}
const Token = Tuple{SortedContainer, IntSemiToken}
const SortedDictToken = Tuple{SortedDict, IntSemiToken}
const SortedMultiDictToken = Tuple{SortedMultiDict, IntSemiToken}
const SDMToken = Tuple{SDMContainer, IntSemiToken}
const SortedSetToken = Tuple{SortedSet, IntSemiToken}

Base.:(==)(t1::Token, t2::Token) = (t1[1] === t2[1] && t1[2] == t2[2])


"""
    Base.firstindex(m::SortedContainer)

Return the semitoken of
the first entry of the container `m`, or the past-end semitoken
if the container is empty.  This function was called
`startof` (now deprecated) in previous versions of the package.
Time: O(log *n*)
"""  
Base.firstindex(m::SortedContainer) = IntSemiToken(beginloc(m.bt))


"""
    token_firstindex(m::SortedContainer)


Return the token of
the first entry of the sorted container `m`, or the past-end token
if the container is empty.  Time: O(log *n*)
"""  
token_firstindex(m::SortedContainer) = (m, firstindex(m))



"""
    Base.lastindex(m::SortedContainer)

Return the semitoken of the
last entry of the sorted container `m`, or the before-start semitoken
if the container is empty.   This function was called `endof` (now
deprecated) in previous versions of the package.
Time: O(log *n*)
"""
Base.lastindex(m::SortedContainer) = IntSemiToken(endloc(m.bt))


"""
    token_lastindex(m::SortedContainer)

Return the token of the
last entry of the sorted container `m`, or the before-start semitoken
if the container is empty.  Time: O(log *n*)
"""
token_lastindex(m::SortedContainer) = (m, lastindex(m))


"""
    pastendsemitoken(m::SortedContainer)

Return the semitoken
of the entry that is one past the end of the sorted container `m`.
Time: O(1)
"""
pastendsemitoken(::SortedContainer) = IntSemiToken(2)


"""
    pastendtoken(m::SortedContainer)

Return the token
of the entry that is one past the end of the sorted container `m`.
Time: O(1)
"""
pastendtoken(m::SortedContainer) = (m, pastendsemitoken(m))



"""
    beforestartsemitoken(m::SortedContainer)

Return the semitoken
of the entry that is one before the beginning of the 
sorted container `m`.  Time: O(1)
"""
beforestartsemitoken(::SortedContainer) = IntSemiToken(1)


"""
    beforestarttoken(m::SortedContainer)

Return the token
of the entry that is one before the beginning of the 
sorted container `m`. Time: O(1)
"""
beforestarttoken(m::SortedContainer) = (m, beforestartsemitoken(m))



"""
    Base.delete!(token::Token) 

Delete the item indexed by the token from a sorted container.  
A `BoundsError` is thrown if the token is invalid.
Prepending with
`@inbounds` may elide the correctness check and will result
in undefined behavior if the token is invalid.
Time: O(log *n*).
"""
Base.@propagate_inbounds function Base.delete!(ii::Token)
    Base.@boundscheck has_data(ii)
    delete!(ii[1].bt, ii[2].address)
end


"""
    advance(token::Token)
    advance((m,st))

Return the semitoken of the item in a sorted container
one after the given token.  A `BoundsError` is thrown if the token is
the past-end token.  
Prepending with
`@inbounds` may elide the correctness check and will result
in undefined behavior if the token is invalid or
points to the past-end token.
The second form creates the token
in-place as a tuple of a  container `m` and a semitoken `st`.
Time: O(log *n*)
"""
Base.@propagate_inbounds function advance(ii::Token)
    Base.@boundscheck not_pastend(ii)
    IntSemiToken(nextloc0(ii[1].bt, ii[2].address))
end


"""
    regress(token::Token)
    regress((m,st))

Return the semitoken of the item in a sorted container
one before the given token.  A `BoundsError` is thrown if the token is
the before-start token.  
Prepending with
`@inbounds` may elide the correctness check and will result
in undefined behavior if the token is invalid or
points to the before-start token.
The second form creates the token
in-place as a tuple of a container `m` and a semitoken `st`.
Time: O(log *n*)
"""
Base.@propagate_inbounds function regress(ii::Token)
    Base.@boundscheck not_beforestart(ii)
    IntSemiToken(prevloc0(ii[1].bt, ii[2].address))
end


"""
    status(token::Token) 
    status((m, st))

Determine the status of a token.  Return values are:
-  0 = invalid token
-  1 = valid and points to live data
-  2 = before-start token
-  3 = past-end token
The second form creates the token
in-place as a tuple of a sorted container `m` and a semitoken `st`.
Time: O(1)
"""
status(ii::Token) =
       !(ii[2].address in ii[1].bt.useddatacells) ? 0 :
         ii[2].address == 1 ?                       2 :
         ii[2].address == 2 ?                       3 : 1

"""
    compare(m::SortedContainer, s::IntSemiToken, t::IntSemiToken)

Determine the  relative position according to the
sort order of the  data items indexed
by tokens `(m,s)` and  `(m,t)`.  Return:
- `-1`if`(m,s)` precedes `(m,t)`, 
- `0` if `s == t` 
- `1` if `(m,s)`succeeds `(m,t)`. 
The relative positions are determined 
from the tree topology without any key
comparisons. Time: O(log *n*)
"""
compare(m::SortedContainer, s::IntSemiToken, t::IntSemiToken) =
      compareInd(m.bt, s.address, t.address)


"""
    ordtype(sc::SortedSet)
    ordtype(sc::SortedDict)
    ordtype(sc::SortedMultiDict)

Return the order type for a sorted container.
This function may also be applied to the type itself.
Time: O(1)
"""
@inline ordtype(::SortedSet{K,Ord}) where {K, Ord} = Ord
@inline ordtype(::Type{SortedSet{K,Ord}}) where {K, Ord} = Ord
@inline ordtype(::SortedDict{K,D,Ord}) where {K, D, Ord} = Ord
@inline ordtype(::Type{SortedDict{K,D,Ord}}) where {K, D, Ord} = Ord
@inline ordtype(::SortedMultiDict{K,D, Ord}) where {K, D, Ord} = Ord
@inline ordtype(::Type{SortedMultiDict{K,D, Ord}}) where {K, D, Ord} = Ord

"""
    orderobject(sc::SortedContainer)

Return the order object used to construct the container. Time: O(1)
"""
@inline orderobject(m::SortedContainer) = m.bt.ord


"""
    deref(token::Token)
    deref((m,st))

Return the data item indexed by the token.  If
the container is a `SortedSet`, then this is a key in the set.
If the container is a `SortedDict` or `SortedMultiDict`, then
this is a key=>value pair.  It is a `BoundsError` if the token
is invalid or is the before-start or past-end token.  
Prepending with
`@inbounds` may elide the correctness check and will result
in undefined behavior if the token is invalid or
points to the before-start or past-end token.
The 
second form creates the token in-place as a tuple of a 
sorted container `m` 
and a semitoken `st`.  Time: O(1)
"""
function deref(ii::Token)
    error("This is not reachable because the specialized methods below will always be selected but is here to make the doc work")
end

Base.@propagate_inbounds function deref(ii::SortedDictToken)
    Base.@boundscheck has_data(ii)
    @inbounds kdrec = ii[1].bt.data[ii[2].address]
    return Pair(kdrec.k, kdrec.d)
end

Base.@propagate_inbounds function deref(ii::SortedMultiDictToken)
    Base.@boundscheck has_data(ii)
    @inbounds kdrec = ii[1].bt.data[ii[2].address]
    return Pair(kdrec.k, kdrec.d)
end


Base.@propagate_inbounds function deref(ii::SortedSetToken)
    Base.@boundscheck has_data(ii)
    @inbounds k = ii[1].bt.data[ii[2].address].k
    return k
end


"""
    deref_key(token::Token)
    deref_key((m,st))

Return the key portion of a data item (a key=>value pair) in a 
`SortedDict` or `SortedMultiDict` indexed by the token.
It is a `BoundsError` if the token
is invalid or is the before-start or past-end token. 
Prepending with
`@inbounds` may elide the correctness check and will result
in undefined behavior if the token is invalid or
points to the before-start or past-end token.
The 
second form creates the token in-place as a tuple of a container `m` 
and a semitoken `st`.  Time: O(1)
"""
function deref_key(ii::Token)
    error("Cannot invoke deref_key on a SortedSet")
end


Base.@propagate_inbounds function deref_key(ii::SDMToken)
    Base.@boundscheck has_data(ii)
    @inbounds k = ii[1].bt.data[ii[2].address].k
    return k
end


"""
    deref_value(token::Token)
    deref_value((m,st))

Returns the value portion of a data item (a key=>value pair)
in a `SortedDict` or `SortedMultiDict` 
indexed by the token. 
It is a `BoundsError` if the token
is invalid or is the before-start or past-end token. 
Prepending with
`@inbounds` may elide the correctness check and will result
in undefined behavior if the token is invalid or
points to the before-start or past-end token.
The 
second form creates the token in-place as a tuple of a container `m` 
and a semitoken `st`.  Time: O(1)
"""
function deref_value(ii::Token)
    error("Cannot invoke deref_key on a SortedSet")
end

Base.@propagate_inbounds function deref_value(ii::SDMToken)
    Base.@boundscheck has_data(ii)
    @inbounds d = ii[1].bt.data[ii[2].address].d
    return d
end


"""
    Base.first(sc::SortedContainer)

Return the 
first item (a `k=>v` pair for SortedDict and
SortedMultiDict or an element for SortedSet) in `sc` according to the sorted
order in the container. It is a `BoundsError` to call this function on
an empty container.  Equivalent to `deref(token_startindex(sc))`. Time: O(log *n*)
"""
Base.first(m::SortedContainer) = deref(token_firstindex(m))


"""
    Base.last(sc::SortedContainer)

Return the last item (a `k=>v` pair for SortedDict and
SortedMultiDict or a key for SortedSet) in `sc` according to the sorted
order in the container. It is a `BoundsError` to call this function on an
empty container. Equivalent to `deref(token_lastindex(sc))`. Time: O(log *n*)
"""
Base.last(m::SortedContainer) = deref(token_lastindex(m))



"""
    Base.getindex(m::SortedDict, st::IntSemiToken)
    Base.getindex(m::SortedMultiDict, st::IntSemiToken)

Retrieve value portion of item from SortedDict or SortedMultiDict
`m` indexed by `st`, a semitoken. Notation `m[st]` appearing in 
an expression
is equivalent to [`deref_value(token::Token)`](@ref) where `token=(m,st)`.  
It is a `BoundsError` if the token is invalid.  Prepending with
`@inbounds` may elide the correctness check and results in undefined
behavior if the token is invalid.
Time: O(1)
"""
Base.@propagate_inbounds function Base.getindex(m::SortedDict,
                       i::IntSemiToken)
    @boundscheck has_data((m,i))
    @inbounds d = m.bt.data[i.address].d
    return d
end
# Must repeat this to break ambiguity; cannot use SDMContainer.
Base.@propagate_inbounds function Base.getindex(m::SortedMultiDict,
                       i::IntSemiToken)
    @boundscheck has_data((m,i))
    @inbounds d = m.bt.data[i.address].d
    return d
end



"""
    Base.setindex!(m::SortedDict, newvalue, st::IntSemiToken)
    Base.setindex!(m::SortedMultiDict, newvalue, st::IntSemiToken)

Set the value portion of item from SortedDict or SortedMultiDict
`m` indexed by `st`, a semitoken to `newvalue`.  
A `BoundsError` is thrown if the token is invalid.
Prepending with `@inbounds` may elide the correctness check and
results in undefined behavior if the token is invalid.
Time: O(1)
"""
Base.@propagate_inbounds function Base.setindex!(m::SortedDict,
                        d_,
                        i::IntSemiToken)
    @boundscheck has_data((m,i))
    @inbounds m.bt.data[i.address] =
        KDRec{keytype(m),valtype(m)}(m.bt.data[i.address].parent,
                                     m.bt.data[i.address].k,
                                     convert(valtype(m),d_))
    return m
end

## Must repeat this to break ambiguity; cannot use SDMContainer
Base.@propagate_inbounds function Base.setindex!(m::SortedMultiDict,
                        d_,
                        i::IntSemiToken)
    @boundscheck has_data((m,i))
    @inbounds m.bt.data[i.address] =
        KDRec{keytype(m),valtype(m)}(m.bt.data[i.address].parent,
                                     m.bt.data[i.address].k,
                                     convert(valtype(m),d_))
    return m
end


"""
    Base.searchsortedfirst(m::SortedContainer, k)

Return the semitoken of the first item in the 
sorted container `m` that is greater than or equal to
`k` in the sort order.
If there is no
such item, then the past-end semitoken is returned.  Time: O(*c* log *n*)

"""
function Base.searchsortedfirst(m::SortedContainer, k_)
    i = findkeyless(m.bt, convert(keytype(m), k_))
    IntSemiToken(nextloc0(m.bt, i))
end


"""
    searchsortedafter(m::SortedContainer, k)

Return the semitoken of the first item in the container that is greater than
`k` in the sort order.  If there is no
such item, then the past-end semitoken is returned. Time: O(*c* log *n*)
"""
function searchsortedafter(m::SortedContainer, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    IntSemiToken(nextloc0(m.bt, i))
end


"""
    Base.searchsortedlast(m::SortedContainer, k)

Return the semitoken of the last item in the container that is less than or equal
to `k` in sort order.  If there is no
such item, then the before-start semitoken is returned.  Time: O(*c* log *n*)
"""
function Base.searchsortedlast(m::SortedContainer, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(i)
end


## The next four are correctness-checking routines.  They are
## not exported.


not_beforestart(i::Token) =
    (!(i[2].address in i[1].bt.useddatacells) ||
     i[2].address == 1) && throw(BoundsError())

not_pastend(i::Token) =
    (!(i[2].address in i[1].bt.useddatacells) ||
     i[2].address == 2) && throw(BoundsError())


has_data(i::Token) =
    (!(i[2].address in i[1].bt.useddatacells) ||
     i[2].address < 3) && throw(BoundsError())




# Container iterables IterableObject{C, R, KV, T, D}
# have five independent parameters as follows
#    C is the type of container, i.e., SortedSet{K,Ord}, SortedDict{K,D,Ord}
#          or SortedMultiDict{K,D,Ord}
#    R indicates whether the iteration is over the entire container,
#          an exclusive range (i.e., a:b where b is omitted) or
#          over an inclusive range (i.e., a:b where b is included)
#    KV indicates whether the iteration is supposed to return keys, values, or both
#       If T is set to onlysemitokens or onlytokens, then this parameter
#       has no effect
#    T indicates whether to return tokens or semitokens in addition to
#       keys and values
#    D indicates whether the iteration is forward or reverse
#



# This struct indicates iteration over the entire container is specified

abstract type RangeTypes end

struct EntireContainer <: RangeTypes
end

# This struct stores an exclusive range
struct ExclusiveRange <: RangeTypes
    first::Int
    pastlast::Int
end

# This struct stores an inclusive range
struct InclusiveRange <: RangeTypes
    first::Int
    last::Int
end


abstract type KVIterTypes end


# This struct indicates 'keys' iteration
struct KeysIter <: KVIterTypes
end

# This struct indicates 'vals' iteration
struct ValsIter <: KVIterTypes
end

# This struct indicates keys+vals iteration
struct KeysValsIter <: KVIterTypes
end

default_KVIterType(::SDMContainer) = KeysValsIter
default_KVIterType(::SortedSet) = KeysIter

abstract type TokenIterTypes end

# This struct indicates 'semitokens' iteration
struct SemiTokenIter <: TokenIterTypes
end

# This struct indicates 'tokens' iteration
struct TokenIter <: TokenIterTypes
end

# This struct indicates 'onlysemitokens' iteration
struct OnlySemiTokenIter <: TokenIterTypes
end

# This struct indicates 'onlytokens' iteration
struct OnlyTokenIter <: TokenIterTypes
end

# This struct indicates neither tokens nor semitokens iteration
struct NoTokens <: TokenIterTypes
end


# This struct indicates  forward iteration

abstract type IterDirection end

struct ForwardIter <: IterDirection
end

# This struct indicates reverse iteration
struct ReverseIter <: IterDirection
end


struct IterableObject{C <: SortedContainer,
                      R <: RangeTypes,
                      Kv <: KVIterTypes,
                      T <: TokenIterTypes,
                      D <: IterDirection}
    m::C
    r::R
end

const SortedContainerIterable = Union{IterableObject, SortedContainer}


base_iterable_object(m::SortedContainer) =
    IterableObject{typeof(m),
                   EntireContainer,
                   default_KVIterType(m),
                   NoTokens,
                   ForwardIter}(m, EntireContainer())

exclusive(m::SortedContainer, (ii1, ii2)::Tuple{IntSemiToken, IntSemiToken}) =
    IterableObject{typeof(m),
                   ExclusiveRange,
                   default_KVIterType(m),
                   NoTokens,
                   ForwardIter}(m, ExclusiveRange(ii1.address, ii2.address))


exclusive(m::SortedContainer, ii1::IntSemiToken, ii2::IntSemiToken) =
    exclusive(m, (ii1, ii2))

exclusive_key(m::SortedContainer, key1, key2) =
    exclusive(m, (searchsortedfirst(m, key1), searchsortedfirst(m, key2)))


inclusive(m::SortedContainer, (ii1, ii2)::Tuple{IntSemiToken, IntSemiToken}) =
    IterableObject{typeof(m),
                   InclusiveRange,
                   default_KVIterType(m),
                   NoTokens,
                   ForwardIter}(m, InclusiveRange(ii1.address, ii2.address))

inclusive(m::SortedContainer,ii1::IntSemiToken, ii2::IntSemiToken) =
    inclusive(m, (ii1, ii2))

inclusive_key(m::SortedContainer, key1, key2) =
    inclusive(m, (searchsortedfirst(m, key1), searchsortedlast(m, key2)))


Base.keys(ito::IterableObject{C, R, KeysValsIter, T, D}) where
{C <: SDMContainer, R, T, D} = 
    IterableObject{C, R, KeysIter, T, D}(ito.m, ito.r)

Base.keys(m::SDMContainer) = keys(base_iterable_object(m))

Base.pairs(ito::IterableObject{<: SDMContainer, R, KV, T, D}) where {R, KV, T, D} = ito
Base.pairs(m::SDMContainer) = base_iterable_object(m)


Base.values(ito::IterableObject{C, R, KeysValsIter, T, D}) where
{C <: SDMContainer, R, T, D} = 
    IterableObject{C, R, ValsIter, T, D}(ito.m, ito.r)

Base.values(m::SDMContainer) = values(base_iterable_object(m))

semitokens(ito::IterableObject{C, R, KV, NoTokens, D}) where {C, R, KV, D} =
    IterableObject{C, R, KV, SemiTokenIter, D}(ito.m, ito.r)

semitokens(m::SortedContainer) = semitokens(base_iterable_object(m))

tokens(ito::IterableObject{C, R, KV, NoTokens, D}) where {C, R, KV, D} =
    IterableObject{C, R, KV, TokenIter, D}(ito.m, ito.r)

tokens(m::SortedContainer) = tokens(base_iterable_object(m))

onlysemitokens(ito::IterableObject{C, R, KV, NoTokens, D}) where {C, R, KV, D} =
    IterableObject{C, R, KV, OnlySemiTokenIter, D}(ito.m, ito.r)

onlysemitokens(m::SortedContainer) = onlysemitokens(base_iterable_object(m))

onlytokens(ito::IterableObject{C, R, KV, NoTokens, D}) where  {C, R, KV, D} =
    IterableObject{C, R, KV, OnlyTokenIter, D}(ito.m, ito.r)

onlytokens(m::SortedContainer) = onlytokens(base_iterable_object(m))


Base.Iterators.reverse(ito::IterableObject{C, R, KV, T, ForwardIter}) where {C, R, KV, T} =
    IterableObject{C, R, KV, T, ReverseIter}(ito.m, ito.r)

Base.Iterators.reverse(ito::IterableObject{C, R, KV, T, ReverseIter}) where {C, R, KV, T} =
    IterableObject{C, R, KV, T, ForwardIter}(ito.m, ito.r)

Base.Iterators.reverse(m::SortedContainer) = Iterators.reverse(base_iterable_object(m))

struct SAIterationState
    next::Int
    final::Int
end


# The iterate function is decomposed into three pieces:
# The iteration_init function initializes the iteration state and
# also stores the final state.  It
# does different things depending on the parameter R (range) and D (direction).
# The get_item function retrieves the requested data from the
# the container and depends on the KV and D parameters.
# The next function updates the iteration state to the next item
# and depends on the D (direction) parameter.


iteration_init(ito::IterableObject{C, EntireContainer, KV, T, ForwardIter}) where
{C, KV, T} = SAIterationState(beginloc(ito.m.bt), 2)

iteration_init(ito::IterableObject{C, EntireContainer, KV, T, ReverseIter}) where
{C, KV, T} = SAIterationState(endloc(ito.m.bt), 1)

function iteration_init(ito::IterableObject{C, ExclusiveRange, KV, T, ForwardIter}) where
{C, KV, T}
    (!(ito.r.first in ito.m.bt.useddatacells) || ito.r.first == 1 ||
     !(ito.r.pastlast in ito.m.bt.useddatacells)) &&
     throw(BoundsError())
    if compareInd(ito.m.bt, ito.r.first, ito.r.pastlast) < 0
        return SAIterationState(ito.r.first, ito.r.pastlast)
    else
        return SAIterationState(2, 2)
    end
end

function iteration_init(ito::IterableObject{C, ExclusiveRange, KV, T, ReverseIter}) where
{C, KV, T}
    (!(ito.r.first in ito.m.bt.useddatacells) || ito.r.first == 2 ||
     !(ito.r.pastlast in ito.m.bt.useddatacells)) &&
     throw(BoundsError())
    if compareInd(ito.m.bt, ito.r.first, ito.r.pastlast) < 0
        return SAIterationState(prevloc0(ito.m.bt, ito.r.pastlast),
                                prevloc0(ito.m.bt, ito.r.first))
    else
        return SAIterationState(2, 2)
    end
end

function iteration_init(ito::IterableObject{C, InclusiveRange, KV, T, ForwardIter}) where
{C, KV, T}
    (!(ito.r.first in ito.m.bt.useddatacells) || ito.r.first == 1 ||
     !(ito.r.last in ito.m.bt.useddatacells) || ito.r.last == 2) &&
     throw(BoundsError())
    if compareInd(ito.m.bt, ito.r.first, ito.r.last) <= 0
        return SAIterationState(ito.r.first, nextloc0(ito.m.bt, ito.r.last))
    else
        return SAIterationState(2, 2)
    end
end    


function iteration_init(ito::IterableObject{C, InclusiveRange, KV, T, ReverseIter}) where
{C, KV, T}
    (!(ito.r.first in ito.m.bt.useddatacells) || ito.r.first == 2 ||
     !(ito.r.last in ito.m.bt.useddatacells) || ito.r.last == 1) &&
     throw(BoundsError())
    if compareInd(ito.m.bt, ito.r.first, ito.r.last) <= 0
        return SAIterationState(ito.r.last, prevloc0(ito.m.bt, ito.r.first))
    else
        return SAIterationState(2, 2)
    end
end

iteration_init(m::SortedContainer) = iteration_init(base_iterable_object(m))

@inline function get_item0(ito::IterableObject{C, R, KeysIter, T, D},
                           state::SAIterationState) where {C, R, T, D} 
    @inbounds k = ito.m.bt.data[state.next].k
    return k
end


@inline function get_item0(ito::IterableObject{C, R, ValsIter, T, D},
                           state::SAIterationState) where {C, R, T, D} 
    @inbounds v = ito.m.bt.data[state.next].d
    return v
end


@inline function get_item0(ito::IterableObject{C, R, KeysValsIter, T, D},
                           state::SAIterationState) where {C, R, T, D}
    @inbounds dt = ito.m.bt.data[state.next]
    return (dt.k => dt.d)
end

get_item(ito::IterableObject{C, R, KeysIter, TokenIter, D},
         state::SAIterationState) where {C, R, D} =
             ((ito.m, IntSemiToken(state.next)), get_item0(ito, state))

Base.eltype(::Type{IterableObject{C, R, KeysIter, TokenIter, D}}) where {C, R, D} =
    Tuple{Tuple{C,IntSemiToken}, keytype(C)}


get_item(ito::IterableObject{C, R, ValsIter, TokenIter, D},
         state::SAIterationState) where {C, R, D} =
             ((ito.m, IntSemiToken(state.next)), get_item0(ito, state))

Base.eltype(::Type{IterableObject{C, R, ValsIter, TokenIter, D}}) where {C, R, D} =
    Tuple{Tuple{C,IntSemiToken}, valtype(C)}


function get_item(ito::IterableObject{C, R, KeysValsIter, TokenIter, D},
                  state::SAIterationState) where {C, R, D}
    i = get_item0(ito, state)
    ((ito.m, IntSemiToken(state.next)), i.first, i.second)
end

Base.eltype(::Type{IterableObject{C, R, KeysValsIter, TokenIter, D}}) where {C, R, D} =
    Tuple{Tuple{C,IntSemiToken}, keytype(C), valtype(C)}

get_item(ito::IterableObject{C, R, KeysIter, SemiTokenIter, D},
         state::SAIterationState) where {C, R, D} = 
             (IntSemiToken(state.next), get_item0(ito, state))

Base.eltype(::Type{IterableObject{C, R, KeysIter, SemiTokenIter, D}}) where {C, R, D} =
    Tuple{IntSemiToken, keytype(C)}

get_item(ito::IterableObject{C, R, ValsIter, SemiTokenIter, D},
         state::SAIterationState) where {C, R, D} = 
             (IntSemiToken(state.next), get_item0(ito, state))

Base.eltype(::Type{IterableObject{C, R, ValsIter, SemiTokenIter, D}}) where {C, R, D} =
    Tuple{IntSemiToken, valtype(C)}

function get_item(ito::IterableObject{C, R, KeysValsIter, SemiTokenIter, D},
                  state::SAIterationState) where {C, R, D}
    i = get_item0(ito, state)
    (IntSemiToken(state.next), i.first, i.second)
end

Base.eltype(::Type{IterableObject{C, R, KeysValsIter, SemiTokenIter, D}}) where {C, R, D} =
    Tuple{IntSemiToken, keytype(C), valtype(C)}

get_item(ito::IterableObject{C, R, KV, OnlyTokenIter, D},
         state::SAIterationState) where {C, R, KV, D} =
             (ito.m, IntSemiToken(state.next))

Base.eltype(::Type{IterableObject{C, R, KV, OnlyTokenIter, D}}) where {C, KV, R, D} =
    Tuple{C, IntSemiToken}


get_item(ito::IterableObject{C, R, KV, OnlySemiTokenIter, D},
         state::SAIterationState) where {C, R, KV, D} = 
             IntSemiToken(state.next)


Base.eltype(::Type{IterableObject{C, R, KV, OnlySemiTokenIter, D}}) where {C, R, KV, D} = IntSemiToken

get_item(ito::IterableObject{C, R, KV, NoTokens, D},
         state::SAIterationState) where {C, R, KV, D} = 
             get_item0(ito, state)

Base.eltype(::Type{IterableObject{C, R, KeysIter, NoTokens, D}}) where {C, R, D} =
    keytype(C)
Base.eltype(::Type{IterableObject{C, R, ValsIter, NoTokens, D}}) where {C, R, D} =
    valtype(C)
Base.eltype(::Type{IterableObject{C, R, KeysValsIter, NoTokens, D}}) where {C, R, D} =
    eltype(C)

Base.eltype(::ItObj) where {ItObj <: IterableObject} = eltype(ItObj)

get_item(m::SortedContainer, state::SAIterationState) =
    get_item(base_iterable_object(m), state)


function next(ito::IterableObject{C, R, KV, T, ForwardIter},
              state::SAIterationState) where {C, R, KV, T} 
    sn = state.next
    (sn < 3 || !(sn in ito.m.bt.useddatacells)) && throw(BoundsError())
    SAIterationState(nextloc0(ito.m.bt, sn), state.final)
end

function next(ito::IterableObject{C, R, KV, T, ReverseIter},
              state::SAIterationState) where {C, R, KV, T}
    sn = state.next
    (sn < 3 || !(sn in ito.m.bt.useddatacells)) && throw(BoundsError())
    SAIterationState(prevloc0(ito.m.bt, sn), state.final)
end

next(m::SortedContainer, state::SAIterationState) =
    next(base_iterable_object(m), state)

"""
    Base.iterate(iter::SortedContainerIterable)

with the following helper functions to construct a `SortedContainerIterable`:

    inclusive(m::SortedContainer, st1, st2)
    inclusive(m::SortedContainer, (st1, st2))
    inclusive_key(m::SortedContainer, key1, key2)
    inclusive_key(m::SortedContainer, (key1, key2))
    exclusive(m::SortedContainer, st1, st2)
    exclusive(m::SortedContainer, (st1, st2))
    exclusive_key(m::SortedContainer, key1, key2)
    exclusive_key(m::SortedContainer, (key1, key2))
    Base.keys(b)
    Base.values(b)
    Base.pairs(b)
    Base.eachindex(b)
    tokens(kv)
    semitokens(kv)
    onlytokens(kv)
    onlysemitokens(kv)
    Base.Iterators.reverse(m)
    (:)(a,b)



Iterate over a sorted container, typically 
within a for-loop, comprehension, or generator.
Here, `iter` is an iterable object constructed from a sorted
container.  The possible iterable objects are constructed from
the helper functions as follows:

A *basic* iterable object is either 
- an entire sorted container `m`,
- `inclusive(m, (st1, st2))` or equivalently `inclusive(m, st1, st2)`, 
- `inclusive_key(m, (k1, k2))` or equivalently `inclusive_key(m, k1, k2)`
- `a:b`, where `a` and `b` are tokens addressing the same container
- `exclusive(m, (st1, st2))` or equivalently `exclusive(m, st1, st2)`
- `exclusive_key(m, (k1, k2))` or equivalently `exclusive_key(m, k1, k2)`

These extract ranges of consecutive items in the containers.  In the
`inclusive` and `exclusive` constructions,
constructions, `m` is a container, `st1` and `st2` are semitokens.  The
`inclusive` range includes both endpoints `st1` and `st2`. 
The inclusive 
iteration is empty if `compare(m,st1,st2)<0`. The `exclusive` range includes
endpoint `st1` but not `st2`.  The exclusive iteration is empty if
`compare(m,st1,st2)<=0`.  In the exclusive iteration, it is acceptable
if `st2` is the past-end semitoken.  


The range `exclusive_key` means all data items with keys between `k1` up to but
excluding items with key `k2`.  For this range to be nonempty, 
`k1<k2` must hold (in the sort order).  
The range `inclusive_key` means all data items with
keys between `k1` and `k2` inclusive.  For this range to be nonempty, `k1<=k2`
must hold.


A *kv* iterable object has the form 
- `b`, a basic iterable object
- `keys(b)` where `b` is a basic object.  Extract keys only (not applicable
   to SortedSet)
- `values(b)` where `b` is a basic object.  Extract values only
   (not applicable to SortedSet).
- `pairs(b)` where `b` is a basic object. Extracts key=>value pairs
   (not applicable to SortedSet).  
   This is the same as just specifying `b` and is provided only for compatibility
   with `Base.pairs`.  

A *tkv* object has the form 
- `kv`, a kv iterable object
- `tokens(kv)` where `kv` is a kv iterable object.  
   Return 2-tuples of the form `(t,w)`, where `t` is the
   token of the item and `w` is a key or value if `kv` is a keys or values
   iteration, or `(t,k,v)` if `kv` is a pairs iteration. 
- `semitokens(kv)` where `kv` is a kv iterable object.  
   Return pairs of the form `(st,w)`, where `st` is the
   token of the item and `w` is a key or value if `kv` is a keys or values
   iteration, or `(st,k,v)` if `kv` is a pairs iteration.
- `onlytokens(kv)` where `kv` is a kv iterable object. Return only tokens
   of the data items but not the items themselves.  
   The `keys`, `values`, or `pairs` modifiers described above
   are ignored.
- `onlysemitokens(kv)` where `kv` is a kv iterable object. Return only semitokens
   of the data items but not the items themselves.  
   The `keys`, `values`, or `pairs` modifiers described above
   are ignored.

Finally, a tkv iteration can be reversed by the `Iterators.reverse` function.  The
`Iterators.reverse` function
may be nested in an arbitrary position with respect to the other operations described 
above. Two reverse operations cancel each other out.  For example,
`Iterators.reverse(keys(Iterators.reverse(m)))` is the same iteration as `keys(m)`.

For compatibility with `Base`, there is also an `eachindex` function:
`eachindex(b)` where the base object `b` a SortedDict is
the same as `keys(b)` (to be compatible with Dict).  
On the other hand, `eachindex(b)` where the
base object `b` is a SortedSet or SortedMultiDict is the
same as `onlysemitokens(b)`.

Colon notation `a:b`  is equivalent
to `onlytokens(inclusive(a[1], a[2], b[2]))`, in other words, it yields
an iteration that provides all the tokens of items in the sort order ranging
from token `a` up to token `b`. It is required that `a[1]===b[1]` (i.e.,
`a` and `b` are tokens for the same container).  Exclusive iteration using
colon notation is obtained via `a : b-1`.

# Examples:

```julia
   for (k,v) in sd
       <body>
   end
```
Here, `sd` is a `SortedDict` or `SortedMultiDict`.  The variables `(k,v)` 
are set to consecutive key-value pairs.  All items in the container are
produced in order.


```julia
   for k in inclusive(ss, st1, st2)
       <body>
   end
```
Here, `ss` is a `SortedSet`, and `st1`, and `st2` are semitokens indexing `ss`.
The elements of the set between `st1` and `st2` inclusive are returned.


```julia
   for (t,k) in tokens(keys(exclusive_key(sd, key1, key2)))
      <body>
   end
```
Here, `sd` is a `SortedDict` or `SortedMultiDict`, `key1` and `key2` are keys
indexing `sd`.  In this case, `t` will be tokens of consecutive items,
while `k` will be the corresponding keys.  The returned keys lie between `key1` and
`key2` excluding `key2`.

```julia
   for (t,k) in Iterators.reverse(tokens(keys(exclusive_key(sd, key1, key2))))
      <body>
   end
```
Same as above, except the iteration is in the reverse order.

Writing on the objects returned by `values` is not currently supported, e.g.,
the following `map!` statement is not implemented even though the 
analogous statement is available for `Dict` in Base.
```julia
    s = SortedDict(3=>4)
    map!(x -> x*2, values(s))
```
The workaround is an explicit loop:
```julia
    s = SortedDict(3=>4)
    for t in onlysemitokens(s)
        s[t] *= 2
    end
```

Running time for all iterations: O(*c*(*s* + log *n*)), where
*s* is the number of steps from start to end of the iteration.
"""
function Base.iterate(s::SortedContainerIterable,
                      state = iteration_init(s))
    if state.next == state.final
        return nothing
    else
        return (get_item(s, state), next(s, state))
    end
end

Base.keytype(::IterableObject{C, R, KeysValsIter, NoTokens, D}) where
{C <: SDMContainer, R, D} = keytype(C)

Base.keytype(::Type{IterableObject{C, R, KeysValsIter, NoTokens, D}}) where
{C <: SDMContainer, R, D} = keytype(C)

Base.valtype(::IterableObject{C, R, KeysValsIter, NoTokens, D}) where
{C <: SDMContainer, R, D} = valtype(C)

Base.valtype(::Type{IterableObject{C, R, KeysValsIter, NoTokens, D}}) where
{C <: SDMContainer, R, D} = valtype(C)

Base.IteratorSize(::Type{T} where {T <: SortedContainer}) = HasLength()
Base.IteratorSize(::Type{IterableObject{C, EntireContainer, KV, T, D}}) where
{C, KV, T, D} = HasLength()

Base.IteratorSize(::Type{IterableObject{C, ExclusiveRange, KV, T, D}}) where
{C, KV, T, D} = SizeUnknown()

Base.IteratorSize(::Type{IterableObject{C, InclusiveRange, KV, T, D}}) where
{C, KV, T, D} = SizeUnknown()

Base.length(ito::IterableObject{C, EntireContainer, KV, T, D}) where
{C, KV, T, D} = length(ito.m)


"""
    Base.in(x, iter::SortedContainerIterable)

Returns true if `x` is in `iter`, where `iter` refers to any of the
iterable objects described under [`Base.iterate(iter::SortedContainerIterable)`](@ref),
and `x` is of the appropriate type. For all of the iterables
except the five listed below, the algorithm used is a linear-time
search. For example, the call:

    (k=>v) in exclusive(sd, st1, st2)

where `sd` is a SortedDict, `st1` and `st2` are semitokens, `k` is a
key, and `v` is a value, will loop over all entries in the
dictionary between the two tokens and a compare for equality using
`isequal` between the indexed item and `k=>v`.

The five exceptions are:

```julia
(k=>v) in sd
(k=>v) in smd
k in ss
k in keys(sd)
k in keys(smd)
```

Here, `sd` is a SortedDict, `smd` is a SortedMultiDict, and `ss` is
a SortedSet.

These five invocations of `in` use the index structure of the sorted
container and test equality based on the order object of the keys
rather than `isequal`. Therefore, these five are all faster than
linear-time looping. To force the use of `isequal` test on
the keys rather than the order object (thus slowing the execution
from logarithmic to linear time), replace the above five constructs
with these:

```julia
(k=>v) in collect(sd)
(k=>v) in collect(smd)
k in collect(ss)
k in collect(keys(sd))
k in collect(keys(smd))
```
"""
Base.in(x, m::SortedContainerIterable) =
    invoke(in, Tuple{Any,Any}, x, m)

Base.in(k, ito::IterableObject{C, EntireContainer, KeysIter, NoTokens, D}) where
{C, D} = haskey(ito.m, k)


"""
    haskey(sc::SortedContainer, k)

Return `true` iff key `k` is present in `sc`.  Equivalent
to 
`in(k,sc)` for a SortedSet, or to `in(k,keys(sc))` for
a SortedDict or SortedMultiDict.  Time: O(*c* log *n*)
"""
@inline function Base.haskey(m::SortedContainer, k_) 
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    return exactfound
end


Base.eachindex(sd::SortedDict) = keys(sd)
Base.eachindex(sdm::SortedMultiDict) = onlysemitokens(sdm)
Base.eachindex(ss::SortedSet) = onlysemitokens(ss)


Base.eachindex(ito::IterableObject{C, R, KeysValsIter, NoTokens, D}) where
{C <: SortedDict, R, D} = keys(ito)

Base.eachindex(ito::IterableObject{C, R, KV, NoTokens, D}) where
{C <: SortedMultiDict, R, KV, D} = onlysemitokens(ito)

Base.eachindex(ito::IterableObject{C, R, KV, NoTokens, D}) where
{C <: SortedSet, R, KV, D} = onlysemitokens(ito)


"""
   empty!(m)

Empty a sorted container
"""

Base.empty!(m::SortedContainer) = (empty!(m.bt); m)
Base.length(m::SortedContainer) = length(m.bt.data) - length(m.bt.freedatainds) - 2
Base.isempty(m::SortedContainer) = length(m) == 0


function Base.:(:)(t1::Token, t2::Token)
    t1[1] !== t2[1] &&
        throw(ArgumentError("First and second arguments of colon operator on sorted container tokens must refer to the same container"))
    IterableObject{typeof(t1[1]), InclusiveRange, default_KVIterType(t1[1]), OnlyTokenIter,
                   ForwardIter}(t1[1], InclusiveRange(t1[2].address, t2[2].address))
end


"""
    Base.+(t::Token, j::Integer)
    Base.-(t::Token, j::Integer)
Return the token that is `j` positions ahead (if `+`) or behind (if `-`) of `t`.
Here, `t` is a token for a sorted container and `j` is an integer. 
If `j` is negative, then `+` regresses while `-` advances.
If the operation `t+j` or `t-j` reaches the before-start 
or past-end positions in the container,
then the before-start/past-end tokens are returned (and there is no error).
Time: O(*j*+log *n*), so this function is not optimized for long jumps.
"""
Base.:(+)(t1::Token, numstep::Integer) = numstep >= 0 ? stepforward(t1, numstep) : stepback(t1, -numstep)

Base.:(-)(t1::Token, numstep::Integer) = numstep >= 0 ? stepback(t1, numstep) : stepforward(t1, -numstep)


function stepforward(t1::Token, numstep::Integer)
    m = t1[1]
    j = t1[2].address
    !(j in m.bt.useddatacells) && throw(BoundsError())
    for i = 1 : numstep
        j == 2 && break
        j = nextloc0(m.bt, j)
    end
    (m, IntSemiToken(j))
end

function stepback(t1::Token, numstep::Integer)
    m = t1[1]
    j = t1[2].address
    !(j in m.bt.useddatacells) && throw(BoundsError())
    for i = 1 : numstep
        j == 1 && break
        j = prevloc0(m.bt, j)
    end
    (m, IntSemiToken(j))
end

