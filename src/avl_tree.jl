mutable struct AVLTreeNode{K}
    height::Int8
    leftChild::Union{AVLTreeNode{K}, Nothing}
    rightChild::Union{AVLTreeNode{K}, Nothing}
    data::K

    AVLTreeNode{K}() where K = new{K}(0, nothing, nothing)
    AVLTreeNode{K}(d::K) where K = new{K}(1, nothing, nothing, d)
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

fix_height(node::AVLTreeNode) = 1 + max(get_height(node.leftChild), get_height(node.rightChild))

"""
    left_rotate!(node_x::RBTreeNode)

Performs a left-rotation on `node_x`, updates height of the nodes, and returns the rotated node. 
"""
function left_rotate(z::AVLTreeNode)
    y = z.rightChild
    α = y.leftChild
    y.leftChild = z
    z.rightChild = α
    z.height = fix_height(z)
    y.height = fix_height(y)
    return y
end

"""
    right_rotate!(node_x::RBTreeNode)

Performs a right-rotation on `node_x`, updates height of the nodes, and returns the rotated node. 
"""
function right_rotate(z::AVLTreeNode)
    y = z.leftChild
    α = y.rightChild
    y.rightChild = z
    z.leftChild = α
    z.height = fix_height(z)
    y.height = fix_height(y)
    return y
end

"""
   minimum_node(tree::RBTree, node::RBTreeNode) 

Returns the RBTreeNode with minimum value in subtree of `node`. 
"""
function minimum_node(node::Union{AVLTreeNode, Nothing})
    while node != nothing && node.leftChild != nothing
        node = node.leftChild
    end
    return node
end

"""
    search_node(tree, key)

Returns the last visited node, while traversing through in binary-search-tree fashion looking for `key`.
"""
search_node(tree, key)

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
    haskey(tree, key)

Returns true if `key` is present in the `tree`, else returns false.    
"""
haskey(tree, key)

function haskey(tree::AVLTree{K}, d::K) where K 
    (tree.root == nothing) && return false
    node = search_node(tree, d)
    return (node.data == d)
end

"""
    insert!(tree, key)

Inserts `key` in the `tree` if it is not present.
"""
insert!(tree, key)

function Base.insert!(tree::AVLTree{K}, d::K) where K

    function insert_node(node::Union{AVLTreeNode, Nothing}, key)
        if node == nothing
            return AVLTreeNode{K}(key)
        elseif key < node.data
            node.leftChild = insert_node(node.leftChild, key)
        else
            node.rightChild = insert_node(node.rightChild, key)
        end
        
        node.height = fix_height(node)
        balance = get_balance(node)
        
        if balance > 1
            if key < node.leftChild.data
                return right_rotate(node)

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

"""
    push!(tree, key)

Inserts `key` in the `tree` if it is not present.
"""
function Base.push!(tree::AVLTree{K}, key0) where K
    key = convert(K, key0)
    insert!(tree, key)
end

function Base.delete!(tree::AVLTree{K}, d::K) where K

    function delete_node(node::Union{AVLTreeNode, Nothing}, key)
        if node == nothing || node.data == nothing
            return nothing
        elseif key < node.data
            node.leftChild = delete_node(node.leftChild, key)
        elseif key > node.data
            node.rightChild = delete_node(node.rightChild, key)
        else
            if node.leftChild == nothing
                temp = node.rightChild
                node = nothing
                return temp
            elseif node.rightChild == nothing
                temp = node.leftChild
                node = nothing
                return temp
            else 
                temp = minimum_node(node.rightChild)
                node.data = temp.data
                node.rightChild = delete_node(node.rightChild, temp.data)
            end 
        end

        if node == nothing
            return node
        end

        node.height = fix_height(node)
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
    tree.root = delete_node(tree.root, d)
    tree.count -= 1
    return tree
end
