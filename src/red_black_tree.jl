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

function Base.isequal(x::RBTreeNode{K}, y::RBTreeNode{K})where K
   return (x.color == y.color && x.data == y.data)
end

Base.:(==)(x::RBTreeNode{K}, y::RBTreeNode{K}) where K = isequal(x, y)

Base.:(!=)(x::RBTreeNode{K}, y::RBTreeNode{K}) where K = !isequal(x, y)

function create_null_node(K::Type)
    node = RBTreeNode{K}()
    node.color = false
    return node
end 

mutable struct RBTree{K}
    root::RBTreeNode{K}
    Nil::RBTreeNode{K}

    function RBTree{K}() where K 
        new{K}(create_null_node(K), create_null_node(K))
    end
end

RBTree() = RBTree{Any}()

function search_node(tree::RBTree{K}, d::K) where K
    node = tree.root
    while node != tree.Nil && d != node.data
        if d < node.data
            node = node.leftChild
        else
            node = node.rightChild
        end
    end
    return node
end

function search_key(tree::RBTree{K}, d::K) where K 
    node = search_node(tree, d)
    return (node.data == d)
end

function insert_node!(tree::RBTree, node::RBTreeNode)
    node_y = nothing
    node_x = tree.root

    while node_x != tree.Nil
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

function left_rotate!(tree::RBTree, node_x::RBTreeNode)
    node_y = node_x.rightChild
    node_x.rightChild = node_y.leftChild
    if node_y.leftChild != tree.Nil
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

function right_rotate!(tree::RBTree, node_x::RBTreeNode)
    node_y = node_x.leftChild
    node_x.leftChild = node_y.rightChild
    if node_y.rightChild != tree.Nil
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

function fix_insert!(tree::RBTree, node::RBTreeNode)
    parent = nothing
    grand_parent = nothing
    # for root node, we need to change the color to black
    # other nodes, we need to maintain the property such that
    # no two adjacent nodes are red in color
    while  node != tree.root && node.parent.color
        parent = node.parent
        grand_parent = parent.parent
        
        # parent is the leftChild of grand_parent
        if (parent == grand_parent.leftChild)
            uncle = grand_parent.rightChild

            # uncle is red in color
            if (uncle.color)
                grand_parent.color = true
                parent.color = false
                uncle.color = false
                node = grand_parent
            # uncle is black in color
            else 
                # node is rightChild of it's parent
                if (node == parent.rightChild)
                    node = parent
                    left_rotate!(tree, node)
                end
                # node is leftChild of it's parent
                node.parent.color = false
                node.parent.parent.color = true
                right_rotate!(tree, node.parent.parent)
            end
        # parent is the rightChild of grand_parent
        else 
            uncle = grand_parent.leftChild

            # uncle is red in color
            if (uncle.color)
                grand_parent.color = true
                parent.color = false
                uncle.color = false
                node = grand_parent
            # uncle is black in color
            else 
                # node is leftChild of it's parent
                if (node == parent.leftChild)
                    node = parent
                    right_rotate!(tree, node)
                end
                # node is rightChild of it's parent
                node.parent.color = false
                node.parent.parent.color = true
                left_rotate!(tree, node.parent.parent)
            end
        end
    end
    tree.root.color = false
end


function Base.insert!(tree::RBTree{K}, d::K) where K
    # if the key exists in the tree, no need to insert 
    search_key(tree, d) && return tree
    # search_key(tree, d) && return tree
    # insert, if not present in the tree
    node = RBTreeNode{K}(d)
    node.leftChild = node.rightChild = tree.Nil
    
    insert_node!(tree, node)
    
    if node.parent == nothing
        node.color = false
    elseif node.parent.parent == nothing
        ;
    else
        fix_insert!(tree, node)
    end
    return tree
end

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
    return tree
end

# transplant u in the tree by v 
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

function minimum_node(tree::RBTree, node::RBTreeNode)
    while node.leftChild != tree.Nil
        node = node.leftChild
    end
    return node
end

function Base.delete!(tree::RBTree{K}, d::K) where K
    z = tree.Nil
    node = tree.root

    while node != tree.Nil
        if node.data == d
            z = node
        end

        if d < node.data
            node = node.leftChild
        else
            node = node.rightChild
        end
    end

    (z == tree.Nil) && throw(KeyError(d))
    
    y = z
    y_original_color = y.color
    x = RBTreeNode{K}()
    if z.leftChild == tree.Nil
        x = z.rightChild
        rb_transplant(tree, z, z.rightChild)
    elseif z.rightChild == tree.Nil
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
end