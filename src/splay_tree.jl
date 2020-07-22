mutable struct SplayTreeNode{K}
    leftChild::Union{SplayTreeNode{K}, Nothing}
    rightChild::Union{SplayTreeNode{K}, Nothing}
    parent::Union{SplayTreeNode{K}, Nothing}
    dirty::Bool
    data::K

    SplayTreeNode{K}() where K = new{K}(nothing, nothing, nothing, true)
    SplayTreeNode{K}(d::K) where K = new{K}(nothing, nothing, nothing, false, d)
end

SplayTreeNode_or_null{K} = Union{SplayTreeNode{K}, Nothing}

SplayTreeNode(d) = SplayTreeNode{Any}(d)
SplayTreeNode() = SplayTreeNode{Any}()

isdirty(node::SplayTreeNode) = node.dirty

mutable struct SplayTree{K}
    root::SplayTreeNode_or_null{K}

    SplayTree{K}() where K = new{K}(nothing)
end 

SplayTree(d) = SplayTree{Any}(d)
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


function splay!(tree::SplayTree, node_x::SplayTreeNode)
    while !isa(node_x.parent, Nothing)
        parent = node_x.parent
        grand_parent = node_x.parent.parent
        # grand-parent is Null
        if isa(grand_parent, Nothing)
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

function maximum(node::SplayTreeNode)
    while !isa(node.rightChild, Nothing)
        node = node.rightChild
    end
    return node
end

function _join(tree::SplayTree ,s::SplayTreeNode_or_null, t::SplayTreeNode_or_null)
    if isa(s, Nothing)
        return t
    elseif isa(t, Nothing)
        return s
    else
        x = maximum(s)
        splay!(tree, x)
        x.rightChild = t
        t.parent = x
        return x
    end
end

function search_by_node(node::SplayTreeNode_or_null{K}, d::K) where K
    while !isa(node, Nothing)
        if node.data == d
            break
        elseif node.data < d
            if !isa(node.rightChild, Nothing)
                node = node.rightChild
            else
                break
            end
        else
            if isa(node.leftChild, Nothing)
                node = node.leftChild
            else
                break
            end
        end
    end
    return node
end

function search_key(tree::SplayTree{K}, d::K) where K
    node = tree.root
    if isa(node, Nothing)
        return false
    else
        node = search_by_node(node, d)
        isa(node, Nothing) && return false
        is_found = (node.data == d)
        is_found && splay!(tree, node)
        return is_found
    end
end

function delete!(tree::SplayTree{K}, d::K) where K
    node = tree.root
    x = search_by_node(node, d)
    isa(x, Nothing) && return tree
    t = nothing
    s = nothing 
    
    splay!(tree, x)
    
    if !isa(x.rightChild, Nothing)
        t = x.rightChild
        t.parent = nothing
    end

    s = x
    s.rightChild = nothing

    if !isa(s.leftChild, Nothing)
        s.leftChild.parent = nothing
    end

    tree.root = _join(tree, s.leftChild, t)
    return tree
end

function insert!(tree::SplayTree{K}, d::K) where K
    is_present = search_by_node(tree.root, d)
    if !isa(is_present, Nothing) && (is_present.data == d)
        return tree
    end
    # only unique keys are inserted
    node = SplayTreeNode{K}(d)
    y = nothing
    x = tree.root

    while !isa(x, Nothing)
        y = x
        if node.data > x.data
            x = x.rightChild
        else
            x = x.leftChild
        end
    end
    node.parent = y

    if isa(y, Nothing)
        tree.root = node
    elseif node.data < y.data
        y.leftChild = node
    else
        y.rightChild = node
    end
    splay!(tree, node)
    return tree
end