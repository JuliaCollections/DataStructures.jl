# it has unique keys
# leftChild has keys which are less than the node
# rightChild has keys which are greater than the node
# height stores the height of the subtree.
mutable struct AVLTreeNode{K}
    height::Int8
    leftChild::Union{AVLTreeNode{K}, Nothing}
    rightChild::Union{AVLTreeNode{K}, Nothing}
    subsize::Int32
    data::K

    AVLTreeNode{K}(d::K) where K = new{K}(1, nothing, nothing, 1, d)
end

AVLTreeNode(d) = AVLTreeNode{Any}(d)

Base.setproperty!(x::AVLTreeNode{T}, f::Symbol, v) where {T} =
    setfield!(x, f, v)

AVLTreeNode_or_null{T} = Union{AVLTreeNode{T}, Nothing}

"""
    AVLTree{T}

Construct new `AVLTree` with keys of type `T`.

# Example

```jldoctest
julia> tree = AVLTree{Int64}()
AVLTree{Int64}(nothing, 0)
```
"""
mutable struct AVLTree{T}
    root::AVLTreeNode_or_null{T}
    count::Int

    AVLTree{T}() where T = new{T}(nothing, 0)
end

AVLTree() = AVLTree{Any}()

"""
    length(tree::AVLTree)

Return number of elements in AVL tree `tree`.
"""
Base.length(tree::AVLTree) = tree.count

get_height(node::Union{AVLTreeNode, Nothing}) = (node == nothing) ? Int8(0) : node.height

# balance is the difference of height between leftChild and rightChild of a node.
function get_balance(node::Union{AVLTreeNode, Nothing})
    if node == nothing
        return 0
    else
        return get_height(node.leftChild) - get_height(node.rightChild)
    end
end

# computes the height of the subtree, which basically is
# one added the maximum of the height of the left subtree and right subtree
compute_height(node::AVLTreeNode) = Int8(1) + max(get_height(node.leftChild), get_height(node.rightChild))

get_subsize(node::AVLTreeNode_or_null) = (node == nothing) ? Int32(0) : node.subsize

# compute the subtree size
function compute_subtree_size(node::AVLTreeNode_or_null)
    if node == nothing
        return Int32(0)
    else
        L = get_subsize(node.leftChild)
        R = get_subsize(node.rightChild)
        return (L + R + Int32(1))
    end
end

"""
    left_rotate(node_x::AVLTreeNode)

Performs a left-rotation on `node_x`, updates height of the nodes, and returns the rotated node.
"""
function left_rotate(z::AVLTreeNode)
    y = z.rightChild
    α = y.leftChild
    y.leftChild = z
    z.rightChild = α
    z.height = compute_height(z)
    y.height = compute_height(y)
    z.subsize = compute_subtree_size(z)
    y.subsize = compute_subtree_size(y)
    return y
end

"""
    right_rotate(node_x::AVLTreeNode)

Performs a right-rotation on `node_x`, updates height of the nodes, and returns the rotated node.
"""
function right_rotate(z::AVLTreeNode)
    y = z.leftChild
    α = y.rightChild
    y.rightChild = z
    z.leftChild = α
    z.height = compute_height(z)
    y.height = compute_height(y)
    z.subsize = compute_subtree_size(z)
    y.subsize = compute_subtree_size(y)
    return y
end

"""
    minimum_node(tree::AVLTree, node::AVLTreeNode)

Returns the AVLTreeNode with minimum value in subtree of `node`.
"""
function minimum_node(node::Union{AVLTreeNode, Nothing})
    while node != nothing && node.leftChild != nothing
        node = node.leftChild
    end
    return node
end

function search_node(tree::AVLTree{K}, d::K) where K
    prev = nothing
    node = tree.root
    while node != nothing && node.data != nothing && node.data != d

        prev = node
        if d < node.data
            node = node.leftChild
        else
            node = node.rightChild
        end
    end

    return (node == nothing) ? prev : node
end

"""
    haskey(tree::AVLTree{K}, k::K) where K

Verify if AVL tree `tree` contains the key `k`. Analogous to [`in(key, tree::AVLTree)`](@ref).
"""
function Base.haskey(tree::AVLTree{K}, k::K) where K
    (tree.root == nothing) && return false
    node = search_node(tree, k)
    return (node.data == k)
end

"""
    in(key, tree::AVLTree)

`In` infix  operator for `key` and `tree` types. Analogous to [`haskey(tree::AVLTree{K}, k::K) where K`](@ref).
"""
Base.in(key, tree::AVLTree) = haskey(tree, key)

function insert_node(node::Nothing, key::K) where K
    return AVLTreeNode{K}(key)
end

function insert_node(node::AVLTreeNode{K}, key::K) where K
    if key < node.data
        node.leftChild = insert_node(node.leftChild, key)
    else
        node.rightChild = insert_node(node.rightChild, key)
    end

    node.subsize = compute_subtree_size(node)
    node.height = compute_height(node)
    balance = get_balance(node)

    if balance > 1
        if key < node.leftChild.data
            return right_rotate(node)
        else
            node.leftChild = left_rotate(node.leftChild)
            return right_rotate(node)
        end
    end

    if balance < -1
        if key > node.rightChild.data
            return left_rotate(node)
        else
            node.rightChild = right_rotate(node.rightChild)
            return left_rotate(node)
        end
    end

    return node
end

function Base.insert!(tree::AVLTree{K}, d::K) where K
    haskey(tree, d) && return tree

    tree.root = insert_node(tree.root, d)
    tree.count += 1
    return tree
end

"""
    push!(tree::AVLTree{K}, key) where K

Insert `key` in AVL tree `tree`.
"""
function Base.push!(tree::AVLTree{K}, key) where K
    key0 = convert(K, key)
    insert!(tree, key0)
end

function delete_node!(node::AVLTreeNode{K}, key::K) where K
    if key < node.data
        node.leftChild = delete_node!(node.leftChild, key)
    elseif key > node.data
        node.rightChild = delete_node!(node.rightChild, key)
    else
        if node.leftChild == nothing
            result = node.rightChild
            return result
        elseif node.rightChild == nothing
            result = node.leftChild
            return result
        else
            result = minimum_node(node.rightChild)
            node.data = result.data
            node.rightChild = delete_node!(node.rightChild, result.data)
        end
    end

    node.subsize = compute_subtree_size(node)
    node.height = compute_height(node)
    balance = get_balance(node)

    if balance > 1
        if get_balance(node.leftChild) >= 0
            return right_rotate(node)
        else
            node.leftChild = left_rotate(node.leftChild)
            return right_rotate(node)
        end
    end

    if balance < -1
        if get_balance(node.rightChild) <= 0
            return left_rotate(node)
        else
            node.rightChild = right_rotate(node.rightChild)
            return left_rotate(node)
        end
    end

    return node
end

"""
    delete!(tree::AVLTree{K}, k::K) where K

Delete key `k` from `tree` AVL tree.
"""
function Base.delete!(tree::AVLTree{K}, k::K) where K
    # if the key is not in the tree, do nothing and return the tree
    !haskey(tree, k) && return tree

    # if the key is present, delete it from the tree
    tree.root = delete_node!(tree.root, k)
    tree.count -= 1
    return tree
end

"""
    sorted_rank(tree::AVLTree{K}, key::K) where K

Returns the rank of `key` present in the `tree`, if it present. A `KeyError` is thrown if `key`
is not present.

# Examples

```jldoctest
julia> tree = AVLTree{Int}();

julia> for k in 1:2:20
           push!(tree, k)
       end

julia> sorted_rank(tree, 17)
9
```
"""
function sorted_rank(tree::AVLTree{K}, key::K) where K
    !haskey(tree, key) && throw(KeyError(key))
    node = tree.root
    rank = 0
    while node.data != key
        if (node.data < key)
            rank += (1 + get_subsize(node.leftChild))
            node = node.rightChild
        else
            node = node.leftChild
        end
    end
    rank += (1 + get_subsize(node.leftChild))
    return rank
end

"""
    getindex(tree::AVLTree{K}, ind::Integer) where K

Considering the elements of `tree` sorted, returns the `ind`-th element in `tree`. Search
operation is performed in \$O(\\log n)\$ time complexity.

# Examples

```jldoctest
julia> tree = AVLTree{Int}()
AVLTree{Int64}(nothing, 0)

julia> for k in 1:2:20
           push!(tree, k)
       end

julia> tree[4]
7

julia> tree[8]
15
```
"""
function Base.getindex(tree::AVLTree{K}, ind::Integer) where K
    @boundscheck (1 <= ind <= tree.count) || throw(BoundsError("$ind should be in between 1 and $(tree.count)"))
    function traverse_tree(node::AVLTreeNode_or_null, idx)
        if (node != nothing)
            L = get_subsize(node.leftChild)
            if idx <= L
                return traverse_tree(node.leftChild, idx)
            elseif idx == L + 1
                return node.data
            else
                return traverse_tree(node.rightChild, idx - L - 1)
            end
        end
    end
    value = traverse_tree(tree.root, ind)
    return value
end
