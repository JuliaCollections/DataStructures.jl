```@meta
DocTestSetup = :(using DataStructures)
```

# Splay Tree

The `SplayTree` type is an implementation of Splay Tree in Julia. It is a self-balancing binary search tree with the additional property that recently accessed elements are quick to access again. Operations such as search, insert and delete can be done in `O(log n)` amortized time, where `n` is the number of nodes in the `SplayTree`.

Examples:

```jldoctest
julia> tree = SplayTree{Int}();

julia> for k in 1:2:20
           push!(tree, k)
       end

julia> haskey(tree, 3)
true

julia> tree[4]
7

julia> for k in 1:2:10
           delete!(tree, k)
       end

julia> haskey(tree, 5)
false
```

```@meta
DocTestSetup = nothing
```
