```@meta
DocTestSetup = :(using DataStructures)
```

# AVL Tree

The `AVLTree` type is an implementation of AVL Tree in Julia. It is a self-balancing binary search tree where balancing occurs based on the difference of height of the left subtree and the right subtree. Operations such as search, insert and delete can be done in `O(log n)` complexity, where `n` is the number of nodes in the `AVLTree`.

Examples:

```jldoctest
julia> tree = AVLTree{Int}();

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
