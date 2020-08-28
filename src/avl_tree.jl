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

AVLTreeNode_or_null{T} = Union{AVLTreeNode{T}, Nothing}

mutable struct AVLTree{T}
    root::AVLTreeNode_or_null{T}
    count::Int

    AVLTree{T}() where T = new{T}(nothing, 0)
end

AVLTree() = AVLTree{Any}()

Base.length(tree::AVLTree) = tree.count

get_height(node::Union{AVLTreeNode, Nothing}) = (node == nothing) ? 0 : node.height

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
compute_height(node::AVLTreeNode) = 1 + max(get_height(node.leftChild), get_height(node.rightChild))

get_subsize(node::AVLTreeNode_or_null) = (node == nothing) ? 0 : node.subsize

# compute the subtree size
function compute_subtree_size(node::AVLTreeNode_or_null)
    if node == nothing
        return 0
    else
        L = get_subsize(node.leftChild)
        R = get_subsize(node.rightChild)
        return (L + R + 1)
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

function Base.haskey(tree::AVLTree{K}, d::K) where K 
    (tree.root == nothing) && return false
    node = search_node(tree, d)
    return (node.data == d)
end

Base.in(key, tree::AVLTree) = haskey(tree, key)

function Base.insert!(tree::AVLTree{K}, d::K) where K

    function insert_node(node::Union{AVLTreeNode, Nothing}, key)
        if node == nothing
            return AVLTreeNode{K}(key)
        elseif key < node.data
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

    haskey(tree, d) && return tree

    tree.root = insert_node(tree.root, d)
    tree.count += 1
    return tree
end

function Base.push!(tree::AVLTree{K}, key0) where K
    key = convert(K, key0)
    insert!(tree, key)
end

function Base.delete!(tree::AVLTree{K}, d::K) where K

    function delete_node!(node::Union{AVLTreeNode, Nothing}, key)
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

    # if the key is not in the tree, do nothing and return the tree
    !haskey(tree, d) && return tree
    
    # if the key is present, delete it from the tree
    tree.root = delete_node!(tree.root, d)
    tree.count -= 1
    return tree
end

"""
    sorted_rank(tree::AVLTree, key)

Returns the rank of `key` present in the `tree`, if it present. A KeyError is thrown if `key` is not present.
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