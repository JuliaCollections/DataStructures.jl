# Disjoint sets

############################################################
#
#   A forest of disjoint sets of integers
#
#   Since each element is an integer, we can use arrays
#   instead of dictionary (for efficiency)
#
#   Disjoint sets over other key types can be implemented
#   based on an IntDisjointSets through a map from the key
#   to an integer index
#
############################################################

_intdisjointsets_bounds_err_msg(T) = "the maximum number of elements in IntDisjointSets{$T} is $(typemax(T))"

"""
    IntDisjointSets{T<:Integer}(n::Integer)

A forest of disjoint sets of integers, which is a data structure
(also called a union–find data structure or merge–find set)
that tracks a set of elements partitioned
into a number of disjoint (non-overlapping) subsets.
"""
mutable struct IntDisjointSets{T<:Integer}
    parents::Vector{T}
    ranks::Vector{T}
    ngroups::T

    # creates a disjoint set comprised of n singletons
    # IntDisjointSets(n::T) where {T<:Integer} = new(collect(Base.OneTo(n)), zeros(T, n), n)
end

IntDisjointSets(n::T) where {T<:Integer} = IntDisjointSets{T}(collect(Base.OneTo(n)), zeros(T, n), n)
IntDisjointSets{T}(n::Integer) where {T<:Integer} = IntDisjointSets{T}(collect(Base.OneTo(T(n))), zeros(T, T(n)), T(n))
Base.length(s::IntDisjointSets) = length(s.parents)

"""
    num_groups(s::IntDisjointSets)

Get a number of groups.
"""
num_groups(s::IntDisjointSets) = s.ngroups
Base.eltype(::Type{IntDisjointSets{T}}) where {T<:Integer} = T

# find the root element of the subset that contains x
# path compression is implemented here
function find_root_impl!(parents::Vector{T}, x::Integer) where {T<:Integer}
    p = parents[x]
    @inbounds if parents[p] != p
        parents[x] = p = _find_root_impl!(parents, p)
    end
    return p
end

# unsafe version of the above
function _find_root_impl!(parents::Vector{T}, x::Integer) where {T<:Integer}
    @inbounds p = parents[x]
    @inbounds if parents[p] != p
        parents[x] = p = _find_root_impl!(parents, p)
    end
    return p
end

"""
    find_root!(s::IntDisjointSets{T}, x::T)

Find the root element of the subset that contains an member x.
Path compression is implemented here.
"""
find_root!(s::IntDisjointSets{T}, x::T) where {T<:Integer} = find_root_impl!(s.parents, x)

"""
    in_same_set(s::IntDisjointSets{T}, x::T, y::T)

Returns `true` if `x` and `y` belong to the same subset in `s` and `false` otherwise.
"""
in_same_set(s::IntDisjointSets{T}, x::T, y::T) where {T<:Integer} = find_root!(s, x) == find_root!(s, y)

"""
    union!(s::IntDisjointSets{T}, x::T, y::T)

Merge the subset containing x and that containing y into one
and return the root of the new set.
"""
function Base.union!(s::IntDisjointSets{T}, x::T, y::T) where {T<:Integer}
    parents = s.parents
    xroot = find_root_impl!(parents, x)
    yroot = find_root_impl!(parents, y)
    xroot != yroot ? root_union!(s, xroot, yroot) : xroot
end

"""
    root_union!(s::IntDisjointSets{T}, x::T, y::T)

Form a new set that is the union of the two sets whose root elements are
x and y and return the root of the new set.
Assume x ≠ y (unsafe).
"""
function root_union!(s::IntDisjointSets{T}, x::T, y::T) where {T<:Integer}
    parents = s.parents
    rks = s.ranks
    @inbounds xrank = rks[x]
    @inbounds yrank = rks[y]

    if xrank < yrank
        x, y = y, x
    elseif xrank == yrank
        rks[x] += one(T)
    end
    @inbounds parents[y] = x
    s.ngroups -= one(T)
    return x
end

"""
    push!(s::IntDisjointSets{T})

Make a new subset with an automatically chosen new element x.
Returns the new element. Throw an `ArgumentError` if the
capacity of the set would be exceeded.
"""
function Base.push!(s::IntDisjointSets{T}) where {T<:Integer}
    l = length(s)
    l < typemax(T) || throw(ArgumentError(_intdisjointsets_bounds_err_msg(T)))
    x = l + one(T)
    push!(s.parents, x)
    push!(s.ranks, zero(T))
    s.ngroups += one(T)
    return x
end

"""
    DisjointSets{T}(xs)

A forest of disjoint sets of arbitrary value type T.

It is a wrapper of IntDisjointSets{Int}, which uses a
dictionary to map the input value to an internal index.
"""
mutable struct DisjointSets{T} <: AbstractSet{T}
    intmap::Dict{T,Int}
    revmap::Vector{T}
    internal::IntDisjointSets{Int}

    DisjointSets{T}() where T = new{T}(Dict{T,Int}(), Vector{T}(), IntDisjointSets(0))
    function DisjointSets{T}(xs) where T    # xs must be iterable
        imap = Dict{T,Int}()
        rmap = Vector{T}()
        n = length(xs)
        sizehint!(imap, n)
        sizehint!(rmap, n)
        id = 0
        for x in xs
            imap[x] = (id += 1)
            push!(rmap,x)
        end
        new{T}(imap, rmap, IntDisjointSets(n))
    end
end

DisjointSets() = DisjointSets{Any}()
DisjointSets(xs::T...) where T = DisjointSets{T}(xs)
DisjointSets{T}(xs::T...) where T = DisjointSets{T}(xs)
DisjointSets(xs) = _DisjointSets(xs, Base.IteratorEltype(xs))
_DisjointSets(xs, ::Base.HasEltype) = DisjointSets{eltype(xs)}(xs)
function _DisjointSets(xs, ::Base.EltypeUnknown)
    T = Base.@default_eltype(xs)
    (isconcretetype(T) || T === Union{}) || return Base.grow_to!(DisjointSets{T}(), xs)
    return DisjointSets{T}(xs)
end

Base.iterate(s::DisjointSets) = iterate(s.revmap)
Base.iterate(s::DisjointSets, i) = iterate(s.revmap, i)

Base.length(s::DisjointSets) = length(s.internal)

"""
    num_groups(s::DisjointSets)

Get a number of groups.
"""
num_groups(s::DisjointSets) = num_groups(s.internal)
Base.eltype(::Type{DisjointSets{T}}) where T = T
Base.empty(s::DisjointSets{T}, ::Type{U}=T) where {T,U} = DisjointSets{U}()
function Base.sizehint!(s::DisjointSets, n::Integer)
    sizehint!(s.intmap, n)
    sizehint!(s.revmap, n)
    return s
end

"""
    find_root!{T}(s::DisjointSets{T}, x::T)

Finds the root element of the subset in `s` which has the element `x` as a member.
"""
find_root!(s::DisjointSets{T}, x::T) where {T} = s.revmap[find_root!(s.internal, s.intmap[x])]

"""
    in_same_set(s::DisjointSets{T}, x::T, y::T)

Returns `true` if `x` and `y` belong to the same subset in `s` and `false` otherwise.
"""
in_same_set(s::DisjointSets{T}, x::T, y::T) where {T} = in_same_set(s.internal, s.intmap[x], s.intmap[y])

"""
    union!(s::DisjointSets{T}, x::T, y::T)

Merge the subset containing x and that containing y into one
and return the root of the new set.
"""
Base.union!(s::DisjointSets{T}, x::T, y::T) where {T} = s.revmap[union!(s.internal, s.intmap[x], s.intmap[y])]

"""
    root_union!(s::DisjointSets{T}, x::T, y::T)

Form a new set that is the union of the two sets whose root elements are
x and y and return the root of the new set.
Assume x ≠ y (unsafe).
"""
root_union!(s::DisjointSets{T}, x::T, y::T) where {T} = s.revmap[root_union!(s.internal, s.intmap[x], s.intmap[y])]

"""
    push!(s::DisjointSets{T}, x::T)

Make a new subset with an automatically chosen new element x.
Returns the new element.
"""
function Base.push!(s::DisjointSets{T}, x::T) where T
    id = push!(s.internal)
    s.intmap[x] = id
    push!(s.revmap,x) # Note, this assumes invariant: length(s.revmap) == id
    return x
end
