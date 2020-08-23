```@meta
DocTestSetup = :(using DataStructures)
```

# Red Black Tree

The `RBTree` type is an implementation of Red Black Tree in Julia. It is a self-balancing binary search tree with an extra bit of information, the color, in each of its node. Operations such as search, insert and delete can be done in `O(log n)` complexity, where `n` is the number of nodes in the `RBTree`.

Examples:

```jldoctest
julia> tree = RBTree{Int}();

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
