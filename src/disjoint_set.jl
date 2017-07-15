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

type IntDisjointSets{T<:Union{Void, Int}}
    parents::Vector{Int}
    ranks::Vector{Int}
    sizes::Vector{T}
    ngroups::Int

    # creates a disjoint set comprised of n singletons
    IntDisjointSets{T}(n::Integer) where {T<:Int} = new(collect(1:n), zeros(Int, n), ones(Int, n), n)
    IntDisjointSets{T}(n::Integer) where {T<:Void} = new(collect(1:n), zeros(Int, n), Vector{Void}(), n)
end
IntDisjointSets(n::Integer) = IntDisjointSets{Int}(n)

length(s::IntDisjointSets) = length(s.parents)
num_groups(s::IntDisjointSets) = s.ngroups


# find the root element of the subset that contains x
# path compression is implemented here
#

function find_root_impl!(parents::Array{Int}, x::Integer)
    p = parents[x]
    @inbounds if parents[p] != p
        parents[x] = p = _find_root_impl!(parents, p)
    end
    p
end

# unsafe version of the above
function _find_root_impl!(parents::Array{Int}, x::Integer)
    @inbounds p = parents[x]
    @inbounds if parents[p] != p
        parents[x] = p = _find_root_impl!(parents, p)
    end
    p
end

find_root(s::IntDisjointSets, x::Integer) = find_root_impl!(s.parents, x)

"""
    in_same_set(s::IntDisjointSets, x::Integer, y::Integer)

Returns `true` if `x` and `y` belong to the same subset in `s` and `false` otherwise.
"""
in_same_set(s::IntDisjointSets, x::Integer, y::Integer) = find_root(s, x) == find_root(s, y)

# merge the subset containing x and that containing y into one
# and return the root of the new set.
function union!(s::IntDisjointSets, x::Integer, y::Integer)
    parents = s.parents
    xroot = find_root_impl!(parents, x)
    yroot = find_root_impl!(parents, y)
    xroot != yroot ?  root_union!(s, xroot, yroot) : xroot
end

# form a new set that is the union of the two sets whose root elements are
# x and y and return the root of the new set
# assume x ≠ y (unsafe)
function root_union!(s::IntDisjointSets{<:Void}, x::Integer, y::Integer)
    parents = s.parents
    rks = s.ranks
    @inbounds xrank = rks[x]
    @inbounds yrank = rks[y]

    if xrank < yrank
        x, y = y, x
    elseif xrank == yrank
        rks[x] += 1
    end
    @inbounds parents[y] = x
    @inbounds s.ngroups -= 1
    x
end

function root_union!(s::IntDisjointSets{<:Int}, x::Integer, y::Integer)
    parents = s.parents
    rks = s.ranks
    @inbounds xrank = rks[x]
    @inbounds yrank = rks[y]

    if xrank < yrank
        x, y = y, x
    elseif xrank == yrank
        rks[x] += 1
    end
    @inbounds parents[y] = x
    @inbounds s.sizes[x] += s.sizes[y]
    @inbounds s.ngroups -= 1
    x
end

# make a new subset with an automatically chosen new element x
# returns the new element
#
function push!(s::IntDisjointSets{<:Void})
    x = length(s) + 1
    push!(s.parents, x)
    push!(s.ranks, 0)
    s.ngroups += 1
    return x
end

function push!(s::IntDisjointSets{<:Int})
    x = length(s) + 1
    push!(s.parents, x)
    push!(s.ranks, 0)
    push!(s.sizes, 1)
    s.ngroups += 1
    return x
end

# get size of set containing element x
#
get_size(s::IntDisjointSets{<:Int}, x::Integer) = s.sizes[find_root(s, x)]
get_size(s::IntDisjointSets{<:Void}, x::Integer) = throw(ErrorException("DisjointSets wasn't initialized with store_size = true"))


############################################################
#
#  A forest of disjoint sets of arbitrary value type T
#
#  It is a wrapper of IntDisjointSets, which uses a
#  dictionary to map the input value to an internal index
#
############################################################

@compat type DisjointSets{T, S<:Union{Void, Int}}
    intmap::Dict{T,Int}
    revmap::Vector{T}
    internal::IntDisjointSets{S}

    function (::Type{DisjointSets{T, S}}){T, S}(xs)    # xs must be iterable
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
        new{T, S}(imap, rmap, IntDisjointSets{S}(n))
    end
end

length(s::DisjointSets) = length(s.internal)
num_groups(s::DisjointSets) = num_groups(s.internal)

"""
    find_root{T}(s::DisjointSets{T}, x::T)

Finds the root element of the subset in `s` which has the element `x` as a member.
"""
find_root{T}(s::DisjointSets{T}, x::T) = s.revmap[find_root(s.internal, s.intmap[x])]

in_same_set{T}(s::DisjointSets{T}, x::T, y::T) = in_same_set(s.internal, s.intmap[x], s.intmap[y])

union!{T}(s::DisjointSets{T}, x::T, y::T) = s.revmap[union!(s.internal, s.intmap[x], s.intmap[y])]

root_union!{T}(s::DisjointSets{T}, x::T, y::T) = s.revmap[root_union!(s.internal, s.intmap[x], s.intmap[y])]

function push!{T}(s::DisjointSets{T}, x::T)
    id = push!(s.internal)
    s.intmap[x] = id
    push!(s.revmap,x) # Note, this assumes invariant: length(s.revmap) == id
    x
end

get_size{T}(s::DisjointSets{T}, x::Integer) = get_size(s.internal, s.intmap[x])
