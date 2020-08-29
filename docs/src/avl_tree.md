```@meta
DocTestSetup = :(using DataStructures)
```

# AVL Tree

The `AVLTree` type is an implementation of AVL Tree in Julia. It is a self-balancing binary search tree where balancing occurs based on the difference of height of the left subtree and the right subtree. Operations such as search, insert and delete can be done in `O(log n)` complexity, where `n` is the number of nodes in the `AVLTree`. Order-statistics on the keys can also be done in `O(log n)`.

Examples:

```jldoctest
julia> tree = AVLTree{Int}();

julia> for k in 1:2:20
           push!(tree, k)
       end

julia> haskey(tree, 3)
true

julia> tree[4] # time complexity of this operation is O(log n)
7

julia> for k in 1:2:10
           delete!(tree, k)
       end

julia> haskey(tree, 5)
false

julia> sorted_rank(tree, 17) # used for finding rank of the key
4
```

```@meta
DocTestSetup = nothing
```
