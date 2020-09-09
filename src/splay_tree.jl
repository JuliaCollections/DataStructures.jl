mutable struct SplayTreeNode{K}
    leftChild::Union{SplayTreeNode{K}, Nothing}
    rightChild::Union{SplayTreeNode{K}, Nothing}
    parent::Union{SplayTreeNode{K}, Nothing}
    data::K

    SplayTreeNode{K}() where K = new{K}(nothing, nothing, nothing)
    SplayTreeNode{K}(d::K) where K = new{K}(nothing, nothing, nothing, d)
end

SplayTreeNode(d) = SplayTreeNode{Any}(d)
SplayTreeNode() = SplayTreeNode{Any}()

mutable struct SplayTree{K}
    root::Union{SplayTreeNode{K}, Nothing}
    count::Int

    SplayTree{K}() where K = new{K}(nothing, 0)
end 

Base.length(tree::SplayTree) = tree.count

SplayTree() = SplayTree{Any}()

function left_rotate!(tree::SplayTree, node_x::SplayTreeNode)
    node_y = node_x.rightChild
    node_x.rightChild = node_y.leftChild
    if node_y.leftChild != nothing
        node_y.leftChild.parent = node_x
    end
    node_y.parent = node_x.parent

    if node_x.parent == nothing
        tree.root = node_y
    elseif (node_x == node_x.parent.leftChild)
        node_x.parent.leftChild = node_y
    else
        node_x.parent.rightChild = node_y
    end
    if node_y != nothing
        node_y.leftChild = node_x
    end
    node_x.parent = node_y
end    

function right_rotate!(tree::SplayTree, node_x::SplayTreeNode)
    node_y = node_x.leftChild
    node_x.leftChild = node_y.rightChild
    if node_y.rightChild != nothing
        node_y.rightChild.parent = node_x
    end
    node_y.parent = node_x.parent
    if node_x.parent == nothing
        tree.root = node_y
    elseif (node_x == node_x.parent.leftChild)
        node_x.parent.leftChild = node_y
    else
        node_x.parent.rightChild = node_y
    end
    node_y.rightChild = node_x
    node_x.parent = node_y
end 

# The splaying operation moves node_x to the root of the tree using the series of rotations.
function splay!(tree::SplayTree, node_x::SplayTreeNode)
    while node_x.parent !== nothing
        parent = node_x.parent
        grand_parent = node_x.parent.parent
        if grand_parent === nothing
            # single rotation
            if node_x == parent.leftChild
                # zig rotation
                right_rotate!(tree, node_x.parent)
            else 
                # zag rotation
                left_rotate!(tree, node_x.parent)
            end
            # double rotation
        elseif node_x == parent.leftChild && parent == grand_parent.leftChild
            # zig-zig rotation
            right_rotate!(tree, grand_parent)
            right_rotate!(tree, parent)
        elseif node_x == parent.rightChild && parent == grand_parent.rightChild
            # zag-zag rotation
            left_rotate!(tree, grand_parent)
            left_rotate!(tree, parent)
        elseif node_x == parent.rightChild && parent == grand_parent.leftChild
            # zig-zag rotation
            left_rotate!(tree, node_x.parent)
            right_rotate!(tree, node_x.parent)
        else
            # zag-zig rotation
            right_rotate!(tree, node_x.parent)
            left_rotate!(tree, node_x.parent)
        end
    end
end

function maximum_node(node::Union{SplayTreeNode, Nothing})
    (node == nothing) && return node
    while node.rightChild != nothing
        node = node.rightChild
    end
    return node
end

# Join operations joins two trees S and T 
# All the items in S are smaller than the items in T.
# This is a two-step process.
# In the first step, splay the largest node in S. This moves the largest node to the root node.
# In the second step, set the right child of the new root of S to T.
function _join!(tree::SplayTree, s::Union{SplayTreeNode, Nothing}, t::Union{SplayTreeNode, Nothing})
    if s === nothing
        return t
    elseif t === nothing
        return s
    else
        x = maximum_node(s)
        splay!(tree, x)
        x.rightChild = t
        t.parent = x
        return x
    end
end

function search_node(tree::SplayTree{K}, d::K) where K
    node = tree.root
    prev = nothing
    while node != nothing && node.data != d
        prev = node
        if node.data < d
            node = node.rightChild
        else
            node = node.leftChild
        end
    end
    return (node == nothing) ? prev : node
end

function Base.haskey(tree::SplayTree{K}, d::K) where K
    node = tree.root
    if node === nothing
        return false
    else
        node = search_node(tree, d)
        (node === nothing) && return false
        is_found = (node.data == d)
        is_found && splay!(tree, node)
        return is_found
    end
end

Base.in(key, tree::SplayTree) = haskey(tree, key)

function Base.delete!(tree::SplayTree{K}, d::K) where K
    node = tree.root
    x = search_node(tree, d)
    (x == nothing) && return tree
    t = nothing
    s = nothing 
    
    splay!(tree, x)
    
    if x.rightChild !== nothing
        t = x.rightChild
        t.parent = nothing
    end

    s = x
    s.rightChild = nothing

    if s.leftChild !== nothing
        s.leftChild.parent = nothing
    end

    tree.root = _join!(tree, s.leftChild, t)
    tree.count -= 1
    return tree
end

function Base.push!(tree::SplayTree{K}, d0) where K
    d = convert(K, d0)
    is_present = search_node(tree, d)
    if (is_present !== nothing) && (is_present.data == d)
        return tree
    end
    # only unique keys are inserted
    node = SplayTreeNode{K}(d)
    y = nothing
    x = tree.root

    while x !== nothing
        y = x
        if node.data > x.data
            x = x.rightChild
        else
            x = x.leftChild
        end
    end
    node.parent = y

    if y === nothing
        tree.root = node
    elseif node.data < y.data
        y.leftChild = node
    else
        y.rightChild = node
    end
    splay!(tree, node)
    tree.count += 1
    return tree
end

function Base.getindex(tree::SplayTree{K}, ind) where K 
    @boundscheck (1 <= ind <= tree.count) || throw(KeyError("$ind should be in between 1 and $(tree.count)"))
    function traverse_tree_inorder(node::Union{SplayTreeNode, Nothing})
        if (node != nothing)
            left = traverse_tree_inorder(node.leftChild)
            right = traverse_tree_inorder(node.rightChild)
            append!(push!(left, node.data), right)
        else
            return K[]
        end
    end
    arr = traverse_tree_inorder(tree.root) 
    return @inbounds arr[ind]
end
