```@meta
DocTestSetup = :(using DataStructures)
```

# Link/Cut Tree

An implementation of the Link/Cut Tree data structure for representing a collection of rooted trees.
This structure supports the operations:
- `link!(v, w)`, join two trees by making `v` (a root node) a child of `w` (an arbitrary node),
- `cut!(v)`, split a tree by disconnecting `v` from its parent,
- `find_root!(v)`, return the root of the tree that contains `v`.

The operations all run in `O(log n)` amortized time.

Examples:

```jldoctest
julia> n1 = LinkCutTreeNode{Int}(1);

julia> n2 = LinkCutTreeNode{Int}(2);

julia> n3 = LinkCutTreeNode{Int}(3);

julia> link!(n2, n1)

julia> link!(n3, n1)

julia> find_root!(n2) === find_root!(n3) === n1
true

julia> cut!(n3)

julia> find_root!(n2) === find_root!(n3)
false

julia> n3 === find_root!(n3)
true
```

```@meta
DocTestSetup = nothing
```
