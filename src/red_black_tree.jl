# it has unique keys
# leftChild has keys which are less than the node
# rightChild has keys which are greater than the node
# color is true if it's a Red Node, else it's false
mutable struct RBTreeNode{K}
    color::Bool
    data::Union{K, Nothing}
    leftChild::Union{Nothing, RBTreeNode{K}}
    rightChild::Union{Nothing, RBTreeNode{K}}
    parent::Union{Nothing, RBTreeNode{K}}

    RBTreeNode{K}() where K = new{K}(true, nothing, nothing, nothing, nothing)

    RBTreeNode{K}(d::K) where K = new{K}(true, d, nothing, nothing, nothing)
end

RBTreeNode() = RBTreeNode{Any}()
RBTreeNode(d) = RBTreeNode{Any}(d)

function create_null_node(K::Type)
    node = RBTreeNode{K}()
    node.color = false
    return node
end

mutable struct RBTree{K}
    root::RBTreeNode{K}
    nil::RBTreeNode{K}
    count::Int

    function RBTree{K}() where K
        rb = new()
        rb.nil = create_null_node(K)
        rb.root = rb.nil
        rb.count = 0
        return rb
    end
end

RBTree() = RBTree{Any}()

Base.length(tree::RBTree) = tree.count

"""
    search_node(tree, key)

Returns the last visited node, while traversing through in binary-search-tree fashion looking for `key`.
"""
search_node(tree, key)

function search_node(tree::RBTree{K}, d::K) where K
    node = tree.root
    while node !== tree.nil && d != node.data
        if d < node.data
            node = node.leftChild
        else
            node = node.rightChild
        end
    end
    return node
end

"""
    haskey(tree, key)

Returns true if `key` is present in the `tree`, else returns false.
"""
function Base.haskey(tree::RBTree{K}, d::K) where K
    node = search_node(tree, d)
    return (node.data == d)
end

"""
    insert_node!(tree::RBTree, node::RBTreeNode)

Inserts `node` at proper location by traversing through the `tree` in a binary-search-tree fashion.
"""
function insert_node!(tree::RBTree, node::RBTreeNode)
    node_y = nothing
    node_x = tree.root

    while node_x !== tree.nil
        node_y = node_x
        if node.data < node_x.data
            node_x = node_x.leftChild
        else
            node_x = node_x.rightChild
        end
    end

    node.parent = node_y
    if node_y == nothing
        tree.root = node
    elseif node.data < node_y.data
        node_y.leftChild = node
    else
        node_y.rightChild = node
    end
end

"""
    left_rotate!(tree::RBTree, node_x::RBTreeNode)

Performs a left-rotation on `node_x` and updates `tree.root`, if required.
"""
function left_rotate!(tree::RBTree, node_x::RBTreeNode)
    node_y = node_x.rightChild
    node_x.rightChild = node_y.leftChild
    if node_y.leftChild !== tree.nil
        node_y.leftChild.parent = node_x
    end
    node_y.parent = node_x.parent
    if (node_x.parent == nothing)
        tree.root = node_y
    elseif (node_x == node_x.parent.leftChild)
        node_x.parent.leftChild = node_y
    else
        node_x.parent.rightChild = node_y
    end
    node_y.leftChild = node_x
    node_x.parent = node_y
end

"""
    right_rotate!(tree::RBTree, node_x::RBTreeNode)

Performs a right-rotation on `node_x` and updates `tree.root`, if required.
"""
function right_rotate!(tree::RBTree, node_x::RBTreeNode)
    node_y = node_x.leftChild
    node_x.leftChild = node_y.rightChild
    if node_y.rightChild !== tree.nil
        node_y.rightChild.parent = node_x
    end
    node_y.parent = node_x.parent
    if (node_x.parent == nothing)
        tree.root = node_y
    elseif (node_x == node_x.parent.leftChild)
        node_x.parent.leftChild = node_y
    else
        node_x.parent.rightChild = node_y
    end
    node_y.rightChild = node_x
    node_x.parent = node_y
end

"""
   fix_insert!(tree::RBTree, node::RBTreeNode)

This method is called to fix the property of having no two adjacent nodes of red color in the `tree`.
"""
function fix_insert!(tree::RBTree, node::RBTreeNode)
    parent = nothing
    grand_parent = nothing
    # for root node, we need to change the color to black
    # other nodes, we need to maintain the property such that
    # no two adjacent nodes are red in color
    while  node != tree.root && node.parent.color
        parent = node.parent
        grand_parent = parent.parent

        if (parent == grand_parent.leftChild) # parent is the leftChild of grand_parent
            uncle = grand_parent.rightChild

            if (uncle.color) # uncle is red in color
                grand_parent.color = true
                parent.color = false
                uncle.color = false
                node = grand_parent
            else  # uncle is black in color
                if (node == parent.rightChild) # node is rightChild of its parent
                    node = parent
                    left_rotate!(tree, node)
                end
                # node is leftChild of its parent
                node.parent.color = false
                node.parent.parent.color = true
                right_rotate!(tree, node.parent.parent)
            end
        else # parent is the rightChild of grand_parent
            uncle = grand_parent.leftChild

            if (uncle.color) # uncle is red in color
                grand_parent.color = true
                parent.color = false
                uncle.color = false
                node = grand_parent
            else  # uncle is black in color
                if (node == parent.leftChild) # node is leftChild of its parent
                    node = parent
                    right_rotate!(tree, node)
                end
                # node is rightChild of its parent
                node.parent.color = false
                node.parent.parent.color = true
                left_rotate!(tree, node.parent.parent)
            end
        end
    end
    tree.root.color = false
end

"""
    insert!(tree, key)

Inserts `key` in the `tree` if it is not present.
"""
function Base.insert!(tree::RBTree{K}, d::K) where K
    # if the key exists in the tree, no need to insert
    haskey(tree, d) && return tree

    # insert, if not present in the tree
    node = RBTreeNode{K}(d)
    node.leftChild = node.rightChild = tree.nil

    insert_node!(tree, node)

    if node.parent == nothing
        node.color = false
    elseif node.parent.parent == nothing
        ;
    else
        fix_insert!(tree, node)
    end
    tree.count += 1
    return tree
end

"""
    push!(tree, key)

Inserts `key` in the `tree` if it is not present.
"""
function Base.push!(tree::RBTree{K}, key0) where K
    key = convert(K, key0)
    insert!(tree, key)
end

"""
    delete_fix(tree::RBTree, node::Union{RBTreeNode, Nothing})

This method is called when a black node is deleted because it violates the black depth property of the RBTree.
"""
function delete_fix(tree::RBTree, node::Union{RBTreeNode, Nothing})
    while node != tree.root && !node.color
         if node == node.parent.leftChild
            sibling = node.parent.rightChild
            if sibling.color
                sibling.color = false
                node.parent.color = true
                left_rotate!(tree, node.parent)
                sibling = node.parent.rightChild
            end

            if !sibling.rightChild.color && !sibling.leftChild.color
                sibling.color = true
                node = node.parent
            else
                if !sibling.rightChild.color
                    sibling.leftChild.color = false
                    sibling.color = true
                    right_rotate!(tree, sibling)
                    sibling = node.parent.rightChild
                end

                sibling.color = node.parent.color
                node.parent.color = false
                sibling.rightChild.color = false
                left_rotate!(tree, node.parent)
                node = tree.root
            end
        else
            sibling = node.parent.leftChild
            if sibling.color
                sibling.color = false
                node.parent.color = true
                right_rotate!(tree, node.parent)
                sibling = node.parent.leftChild
            end

            if !sibling.rightChild.color && !sibling.leftChild.color
                sibling.color = true
                node = node.parent
            else
                if !sibling.leftChild.color
                    sibling.rightChild.color = false
                    sibling.color = true
                    left_rotate!(tree, sibling)
                    sibling = node.parent.leftChild
                end

                sibling.color = node.parent.color
                node.parent.color = false
                sibling.leftChild.color = false
                right_rotate!(tree, node.parent)
                node = tree.root
            end
        end
    end
    node.color = false
    return nothing
end

"""
    rb_transplant(tree::RBTree, u::Union{RBTreeNode, Nothing}, v::Union{RBTreeNode, Nothing})

Replaces `u` by `v` in the `tree` and updates the `tree` accordingly.
"""
function rb_transplant(tree::RBTree, u::Union{RBTreeNode, Nothing}, v::Union{RBTreeNode, Nothing})
    if u.parent == nothing
        tree.root = v
    elseif u == u.parent.leftChild
        u.parent.leftChild = v
    else
        u.parent.rightChild = v
    end
    v.parent = u.parent
end

"""
   minimum_node(tree::RBTree, node::RBTreeNode)

Returns the RBTreeNode with minimum value in subtree of `node`.
"""
function minimum_node(tree::RBTree, node::RBTreeNode)
    (node === tree.nil) && return node
    while node.leftChild !== tree.nil
        node = node.leftChild
    end
    return node
end

"""
    delete!(tree::RBTree, key)

Deletes `key` from `tree`, if present, else returns the unmodified tree.
"""
function Base.delete!(tree::RBTree{K}, d::K) where K
    z = tree.nil
    node = tree.root

    while node !== tree.nil
        if node.data == d
            z = node
        end

        if d < node.data
            node = node.leftChild
        else
            node = node.rightChild
        end
    end

    (z === tree.nil) && return tree

    y = z
    y_original_color = y.color
    x = RBTreeNode{K}()
    if z.leftChild === tree.nil
        x = z.rightChild
        rb_transplant(tree, z, z.rightChild)
    elseif z.rightChild === tree.nil
        x = z.leftChild
        rb_transplant(tree, z, z.leftChild)
    else
        y = minimum_node(tree, z.rightChild)
        y_original_color = y.color
        x = y.rightChild

        if y.parent == z
            x.parent = y
        else
            rb_transplant(tree, y, y.rightChild)
            y.rightChild = z.rightChild
            y.rightChild.parent = y
        end

        rb_transplant(tree, z, y)
        y.leftChild = z.leftChild
        y.leftChild.parent = y
        y.color = z.color
    end

    !y_original_color && delete_fix(tree, x)
    tree.count -= 1
    return tree
end

Base.in(key, tree::RBTree) = haskey(tree, key)

"""
    getindex(tree, ind)

Gets the key present at index `ind` of the tree. Indexing is done in increasing order of key.
"""
function Base.getindex(tree::RBTree{K}, ind) where K
    @boundscheck (1 <= ind <= tree.count) || throw(ArgumentError("$ind should be in between 1 and $(tree.count)"))
    function traverse_tree_inorder(node::RBTreeNode{K}) where K
        if (node !== tree.nil)
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
