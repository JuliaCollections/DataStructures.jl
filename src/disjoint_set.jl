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
    IntDisjointSets(n::Integer) = new([1:n], zeros(Int, n), n)
end

length(s::IntDisjointSets) = length(s.parents)
num_groups(s::IntDisjointSets) = s.ngroups


# find the root element of the subset that contains x
# path compression is implemented here
#
function find_root(s::IntDisjointSets, x::Integer)
    p::Int = s.parents[x]
    if p != x
        p = s.parents[x] = find_root(s, p)
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
        xrank = rks[xroot]
        yrank = rks[yroot]
        
        if xrank < yrank
            s.parents[xroot] = yroot
        else
            s.parents[yroot] = xroot
            if xrank == yrank
                s.ranks[xroot] += 1
            end
        end
        s.ngroups -= 1
    end
end


