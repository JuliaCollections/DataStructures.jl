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

type IntDisjointSets
    parents::Vector{Int}
    ranks::Vector{Int}
    ngroups::Int

    # creates a disjoint set comprised of n singletons
    IntDisjointSets(n::Integer) = new(collect(1:n), zeros(Int, n), n)
end

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

in_same_set(s::IntDisjointSets, x::Integer, y::Integer) = find_root(s, x) == find_root(s, y)

# merge the subset containing x and that containing y into one
#
function union!(s::IntDisjointSets, x::Integer, y::Integer)
    parents = s.parents
    xroot = find_root_impl!(parents, x)
    yroot = find_root_impl!(parents, y)

    if xroot != yroot
        rks = s.ranks
        @inbounds xrank = rks[xroot]
        @inbounds yrank = rks[yroot]

        if xrank < yrank
            @inbounds parents[xroot] = yroot
        else
            @inbounds parents[yroot] = xroot
            if xrank == yrank
                rks[xroot] += 1
            end
        end
        @inbounds s.ngroups -= 1
    end
end

# make a new subset with an automatically chosen new element x
# returns the new element
#
function push!(s::IntDisjointSets)
    x = length(s) + 1
    push!(s.parents, x)
    push!(s.ranks, 0)
    s.ngroups += 1
    return x
end


############################################################
#
#  A forest of disjoint sets of arbitrary value type T
#
#  It is a wrapper of IntDisjointSets, which uses a
#  dictionary to map the input value to an internal index
#
############################################################

type DisjointSets{T}
    intmap::Dict{T,Int}
    internal::IntDisjointSets

    function DisjointSets(xs)    # xs must be iterable
        imap = Dict{T,Int}()
        n = length(xs)
        sizehint!(imap, n)
        id = 0
        for x in xs
            imap[x] = (id += 1)
        end
        new(imap, IntDisjointSets(n))
    end
end

length(s::DisjointSets) = length(s.internal)
num_groups(s::DisjointSets) = num_groups(s.internal)

find_root{T}(s::DisjointSets{T}, x::T) = find_root(s.internal, s.intmap[x])

in_same_set{T}(s::DisjointSets{T}, x::T, y::T) = in_same_set(s.internal, s.intmap[x], s.intmap[y])

function union!{T}(s::DisjointSets{T}, x::T, y::T)
    union!(s.internal, s.intmap[x], s.intmap[y])
end

function push!{T}(s::DisjointSets{T}, x::T)
    id = push!(s.internal)
    s.intmap[x] = id
end
