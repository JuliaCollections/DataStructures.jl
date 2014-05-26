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

type IntWrapper val::Int end

immutable IntDisjointSets
    parents::Vector{Int}
    ranks::Vector{Int}
    ngroups::IntWrapper

    # creates a disjoint set comprised of n singletons
    IntDisjointSets(n::Integer) = new([1:n], zeros(Int, n), IntWrapper(n))
end

length(s::IntDisjointSets) = length(s.parents)
num_groups(s::IntDisjointSets) = s.ngroups.val


# find the root element of the subset that contains x
# path compression is implemented here
#
function find_root(s::IntDisjointSets, x::Integer)
    @inbounds p::Int = s.parents[x]
    @inbounds if s.parents[p] != p
        s.parents[x] = p = find_root(s, p)
    end
    p
end

in_same_set(s::IntDisjointSets, x::Integer, y::Integer) = find_root(s, x) == find_root(s, y)

# merge the subset containing x and that containing y into one
#
function union!(s::IntDisjointSets, x::Integer, y::Integer)
    xroot = find_root(s, x)
    yroot = find_root(s, y)
    if xroot != yroot
        rks::Vector{Int} = s.ranks
        @inbounds xrank::Int = rks[xroot]
        @inbounds yrank::Int = rks[yroot]

        if xrank < yrank
            @inbounds s.parents[xroot] = yroot
        else
            @inbounds s.parents[yroot] = xroot
            if xrank == yrank
                s.ranks[xroot] += 1
            end
        end
        @inbounds s.ngroups.val -= 1
    end
end

# make a new subset with a given new element x
#
function push!(s::IntDisjointSets, x::Integer)
    push!(s.parents, x)
    push!(s.ranks, 0)
    @inbounds s.ngroups.val += 1
end

# make a new subset with an automatically chosen new element x
# returns the new element
#
function push!(s::IntDisjointSets)
    x = length(s) + 1
    push!(s, x)
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

immutable DisjointSets{T}
    intmap::Dict{T,Int}
    internal::IntDisjointSets

    function DisjointSets(xs)    # xs must be iterable
        imap = Dict{T,Int}()
        n = length(xs)
        sizehint(imap, n)
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

