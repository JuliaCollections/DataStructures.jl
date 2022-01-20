# Sorted Containers

```@meta
CurrentModule = DataStructures
```

Three sorted containers are provided: SortedDict, SortedMultiDict and
SortedSet. _SortedDict_ is similar to the built-in Julia type `Dict`
with the additional feature that the keys are stored in sorted order and
can be efficiently iterated in this order. SortedDict is a subtype of
AbstractDict. It is generally slower than `Dict` because looking up a key
requires an O(log _n_) tree search rather than an expected O(1)
hash-table lookup time of `Dict`. SortedDict is a parameterized type
with three parameters, the key type `K`, the value type `V`, and the
ordering type `O`. SortedSet has only keys; it is an alternative to the
built-in `Set` container and is a subtype of AbstractSet.
Internally, SortedSet is implemented as a
SortedDict in which the value type is `Nothing`. Finally, SortedMultiDict
is similar to SortedDict except that each key can be associated with
multiple values. The key=>value pairs in a SortedMultiDict are stored
according to the sorted order for keys, and key=>value pairs with the
same key are stored in order of insertion.

The containers internally use a 2-3 tree, which is a kind of balanced
tree and is described in data structure textbooks.

The containers require two functions to compare keys: a _less-than_ and
_equals_ function. With the default ordering argument, the comparison
functions are `isless(key1,key2)` (true when `key1 < key2`) and
`isequal(key1,key2)` (true when `key1 == key2`) where `key1` and `key2`
are keys. More details are provided below.

## Tokens for Sorted Containers

The sorted containers support an object for indexing called a
_token_ defined as a two-entry tuple and aliased as `SortedDictToken`,
`SortedMultiDictToken`, or `SortedSetToken`.
A token is the address of a single data item in the
container and can be dereferenced in time O(1).

The first entry of a token tuple is the container as a whole, and the
second refers to the particular item. The second part is called a
_semitoken_. The type of the semitoken is `IntSemiToken`.

A restriction for the sorted containers is that `IntSemiToken`
cannot used as the key-type. This is because ambiguity would
result between the two subscripting calls `sc[k]` and `sc[st]` described
below. In the rare scenario that a sorted container whose key-type is
`IntSemiToken` is required, a workaround is to wrap the key inside
another immutable structure.

The notion of token is similar to the concept of iterators used by C++
standard containers. Tokens can be explicitly advanced or regressed
through the data in the sorted order; they are implicitly advanced or
regressed via iteration defined below.

A token may take two special values: the _before-start_ value and the
_past-end_ value. These values act as lower and upper bounds on the
actual data. The before-start token can be advanced, while the past-end
token can be regressed. A dereferencing operation on either leads to an
error.

In the current implementation, semitokens are internally stored as
integers. Users should regard these integers as opaque
since future versions of the package may change the internal indexing
scheme.
In certain situations it may be more costly to operate on tokens than
semitokens because the first entry of a token (i.e., the container)
is not a bits-type.
If code profiling indicates that statements using tokens are allocating memory,
then it may be advisable to rewrite the application code using semitokens
more than tokens.

## Complexity of Sorted Containers

In the list of functions below, the running time of the various
operations is provided. In these running times, _n_ denotes the
size (number of items) in the container,
and _c_ denotes the time needed to compare two keys.



## Constructors for Sorted Containers

### `SortedDict` constructors

```@docs
SortedDict{K,V,Ord}(o::Ord=Forward) where {K, V, Ord <: Ordering}
```


```@docs
SortedDict(o::Ord=Forward) where {Ord <: Ordering}
```

```@docs
SortedDict(iter, o::Ord=Forward) where {Ord <: Ordering}
```

```@docs
SortedDict(ps::Pair...)
```

```@docs
SortedDict{K,V}(::Val{true}, iterable) where {K,V}
```


### `SortedMultiDict` constructors

```@docs
SortedMultiDict{K,V,Ord}(o::Ord=Forward) where {K, V, Ord <: Ordering}
```

```@docs
SortedMultiDict(o::Ord=Forward) where {Ord <: Ordering}

```

```@docs
SortedMultiDict(ps::Pair...)
```

```@docs
SortedMultiDict(iter, o::Ord=Forward) where {Ord <: Ordering}
```

```@docs
SortedMultiDict{K,V}(::Val{true}, iterable) where {K,V}
```

### `SortedSets` constructors
```@docs
SortedSet{K,Ord}(o::Ord=Forward) where {K, Ord<:Ordering}
```

```@docs
SortedSet(o::Ord=Forward) where {Ord <: Ordering}
```

```@docs
SortedSet(o::Ordering, iter)
```
```@docs
SortedSet{K}(::Val{true}, iterable) where {K}
```


## Navigating the Containers

```@docs
Base.getindex(sd::SortedDict, k)
```

```@docs
Base.getindex(m::SortedDict, st::IntSemiToken)
```

```@docs
Base.setindex!(m::SortedDict, newvalue, st::IntSemiToken)
```

```@docs
Base.setindex!(sd::SortedDict, newvalue, k)

```

```@docs
deref(token::Token)
```


```@docs
deref_key(token::Token)
```
```@docs
deref_value(token::Token)
```

```@docs
Base.firstindex(m::SortedContainer)
```

```@docs
Base.lastindex(m::SortedContainer)
```

```@docs
token_firstindex(m::SortedContainer)
```

```@docs
token_lastindex(m::SortedContainer)
```

```@docs
Base.first(sc::SortedContainer)
```

```@docs
Base.last(sc::SortedContainer)
```

```@docs
pastendsemitoken(sc::SortedContainer)
```
```@docs
beforestartsemitoken(sc::SortedContainer)
```

```@docs
pastendtoken(sc::SortedContainer)
```


```@docs
beforestarttoken(sc::SortedContainer)
```

```@docs
advance(token::Token)
```

```@docs
regress(token::Token)

```

```@docs
+(t::Token, k::Integer)

```

```@docs
Base.searchsortedfirst(m::SortedContainer, k)
```

```@docs
Base.searchsortedlast(m::SortedContainer, k)
```

```@docs
searchsortedafter(m::SortedContainer, k)
```

```@docs
searchequalrange(smd::SortedMultiDict, k)
```

```@docs
findkey(m::SortedSet, k)
```

```@docs
findkey(sd::SortedDict, k)
```

## Inserting & Deleting in Sorted Containers


```@docs
ss_push!(ss::SortedSet, k)
```

```@docs
sd_push!(sd::SortedDict, p::Pair)
```

```@docs
smd_push!(smd::SortedMultiDict, p::Pair)
```

```@docs
Base.push!(ss::SortedSet, k)
```

```@docs
Base.push!(sd::SortedDict, p::Pair)
```

```@docs
Base.push!(smd::SortedMultiDict, p::Pair)
```

```@docs
Base.delete!(token::Token) 
```

```@docs
Base.delete!(ss::SortedSet, k)
```

```@docs
Base.delete!(sc::SortedDict, k)
```
```@docs
Base.popfirst!(ss::SortedSet)
```
```@docs
poplast!(ss::SortedSet)
```

```@docs
Base.pop!(ss::SortedSet, k)
```

```@docs
Base.pop!(sd::SortedDict, k)
```

## Token Manipulation

```@docs
compare(m::SortedContainer, s::IntSemiToken, t::IntSemiToken)
```

```@docs
status(token::Token) 
```


## Iteration Over Sorted Containers

```@docs
    Base.iterate(sci::SortedContainerIterable)
```

## `in` function

```@docs
Base.in(k,m::SortedSet)
```

```@docs
Base.in(p::Pair, sd::SortedDict)
```

```@docs
Base.in(p::Pair, smd::SortedMultiDict)
```


```@docs
Base.in(x, iter::SortedContainerIterable)
```

## Misc. Functions


    Base.isempty(m::SortedContainer)
    Base.empty!(m::SortedContainer)
    Base.empty(m::SortedContainer)
    Base.length(m::SortedContainer)
    Base.eltype(m::SortedContainer)
    Base.keytype(m::SortedContainer)
    Base.valtype(m::SortedContainer)
    Base.eltype(m::SortedContainerIteration)
    Base.keytype(m::SortedContainerIteration)
    Base.valtype(m::SortedContainerIteration)
    
    
These functions from `Base` are all applicable to sorted containers
with the obvious meaning.  The `eltype`, `keytype`, and `valtype` functions
may be applied either to the object `m` or its type.
Note that `keytype` and `valtype` are
applicable only to SortedDict and SortedMultiDict, or to
pairs iterations over SortedDict or SortedMultiDict.
Time: O(1)


```@docs
ordtype(sc::SortedContainer)
```

```@docs
orderobject(sc::SortedContainer)
```

```@docs
Base.haskey(sc::SortedContainer, k)
```

```@docs
Base.get(sd::SortedDict,k,v)
```

```@docs
Base.get!(sd::SortedDict,k,v)
```

```@docs
Base.getkey(sd::SortedDict,k,defaultk)
```

```@docs
Base.isequal(ss1::SortedSet{K,Ord}, ss2::SortedSet{K,Ord}) where {K, Ord <: Ordering}
```

```@docs
Base.isequal(sc1::SortedDict{K,V,Ord}, sc2::SortedDict{K,V,Ord}) where {K, V, Ord <: Ordering}
```

```@docs
Base.isequal(smd1::SortedMultiDict{K,V,Ord}, smd2::SortedMultiDict{K,V,Ord}) where {K, V, Ord <: Ordering}

```

```@docs
packcopy(sc::SortedSet)
```

```@docs
packdeepcopy(sc::SortedSet)
```

```@docs
Base.merge(sd::SortedDict{K,V,Ord}, d1::AbstractDict{K,V}...) where {K,V,Ord <: Ordering}
```

```@docs
Base.merge!(sd::SortedDict{K,V,Ord}, d1::AbstractDict{K,V}...) where {K,V,Ord <: Ordering}
```

```@docs
Base.merge(smd::SortedMultiDict, iter...)
```

```@docs
Base.merge!(smd::SortedMultiDict, iter...)
```




## Set operations

The SortedSet container supports the following set operations. Note that
in the case of intersect, symdiff and setdiff, the two SortedSets should
have the same key and ordering object. If they have different key or
ordering types, no error message is produced; instead, the built-in
default versions of these functions (that can be applied to `Any`
iterables and that return arrays) are invoked.

```@docs
Base.union!(ss::SortedSet, iterable...)
```

```@docs
Base.union(ss::SortedSet, iterable...)
```

```@docs
Base.intersect(ss::SortedSet, others...)
```

```@docs
Base.symdiff(ss1::SortedSet, iterable)

```

```@docs
Base.setdiff(ss1::SortedSet{K,Ord}, ss2::SortedSet{K,Ord}) where {K, Ord<:Ordering}
```

```@docs
Base.setdiff!(m1::SortedSet, iterable)
```

```@docs
Base.issubset(iterable, ss::SortedSet)
```

## Ordering of keys

As mentioned earlier, the default ordering of keys uses `isless` and
`isequal` functions. If the default ordering is used, it is a
requirement of the container that `isequal(a,b)` is true if and only if
`!isless(a,b)` and `!isless(b,a)` are both true. This relationship
between `isequal` and `isless` holds for common built-in types, but it
may not hold for all types, especially user-defined types. If it does
not hold for a certain type, then a custom ordering argument must be
defined as discussed in the next few paragraphs.

The name for the default ordering (i.e., using `isless` and `isequal`)
is `Forward`. Note: this is the name of the ordering object; its type is
`ForwardOrdering.` Another possible ordering object is `Reverse`, which
reverses the usual sorted order. This name must be imported
`import Base.Reverse` if it is used.

As an example of a custom ordering, suppose the keys are of type
`String`, and the user wishes to order the keys ignoring case: _APPLE_,
_berry_ and _Cherry_ would appear in that order, and _APPLE_ and _aPPlE_
would be indistinguishable in this ordering.

The simplest approach is to define an ordering object of the form
`Lt(my_isless)`, where `Lt` is a built-in type (see `ordering.jl`) and
`my_isless` is the user's comparison function. In the above example, the
ordering object would be:

```julia
Lt((x,y) -> isless(lowercase(x),lowercase(y)))
```

The ordering object is indicated in the above list of constructors in
the `o` position (see above for constructor syntax).

This approach may suffer from a performance hit because higher performance
may be possible if an equality method is also available as well as a
less-than method.
A more complicated but higher-performance method to implement
a custom ordering is as follows. First, the user creates a singleton
type that is a subtype of `Ordering` as follows:

```julia
struct CaseInsensitive <: Ordering
end
```

Next, the user defines a method named `lt` for less-than in this
ordering:

```julia
lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))
```

The first argument to `lt` is an object of the `CaseInsensitive` type
(there is only one such object since it is a singleton type). The
container also needs an equal-to function; the default is:

```julia
eq(o::Ordering, a, b) = !lt(o, a, b) && !lt(o, b, a)
```


The user can also customize this
function with a more efficient implementation. In the above example, an
appropriate customization would be:

```julia
eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))
```

Note: the user-defined `eq` and `lt` functions must be compatible in the sense
that `!lt(o, a, b) && !lt(o, b, a)` if and only if 
`eq(o, a, b)`.


Finally, the user specifies the unique element of `CaseInsensitive`,
namely the object `CaseInsensitive()`, as the ordering object to the
`SortedDict`, `SortedMultiDict` or `SortedSet` constructor.

For the above code to work, the module must make the following
declarations, typically near the beginning:

```julia
import Base.Ordering
import Base.lt
import DataStructures.eq
```

## Cautionary note on mutable keys

As with ordinary
Dicts, keys for the sorted containers can be either mutable or
immutable. In the case of mutable keys, it is important that the keys
not be mutated once they are in the container else the indexing
structure will be corrupted. (The same restriction applies to Dict.) For
example, suppose `sd` has type `SortedDict{Vector{Int},Int,ForwardOrdering}`, in 
other words, keys of type `Vector{Int}`, values of type `Int`, and 
lexicographic ordering (default ordering of vectors).  Then the
following sequence of statements leaves `sd` in a corrupted state:

```julia
k = [1,2,3]
sd[k] = 19
k[1] = 7
```

## Performance of Sorted Containers

The sorted containers are currently not optimized for cache performance.

