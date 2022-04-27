mutable struct LinkCutTreeNode{T}
    label::T

    # Splay tree structure of path
    left::Union{LinkCutTreeNode{T}, Nothing}
    right::Union{LinkCutTreeNode{T}, Nothing}
    parent::Union{LinkCutTreeNode{T}, Nothing}

    # Structure of path partition
    path_parent::Union{LinkCutTreeNode{T}, Nothing}

    LinkCutTreeNode{T}(label::T) where T = new{T}(label, nothing, nothing, nothing, nothing)
end


"""
    access!(v)

Update the tree that holds `v` with a "preferred path" from the root to `v`
"""
function access!(v::LinkCutTreeNode)
    splay!(v)

    # remove preferred child
    if v.right !== nothing
        v.right.path_parent = v
        v.right.parent = nothing
    end
    v.right = nothing

    # walk up
    u = v
    while u.path_parent !== nothing
        w = u.path_parent
        splay!(w)
        # set preferred child
        if w.right !== nothing
            w.right.path_parent = w
            w.right.parent = nothing
        end
        w.right = u
        u.parent = w
        u.path_parent = nothing

        u = w
    end

    splay!(v)
end

"""
    link!(v, w)

Make `w` the parent of `v`.
Assumes `w` and `v` are nodes in different trees, and that `v` is a root node.
"""
function link!(v::LinkCutTreeNode, w::LinkCutTreeNode)
    # assumes find_root!(v) !== find_root!(w)

    access!(v)
    if v.left !== nothing
        throw(ArgumentError("First argument must be root of tree"))
    end

    access!(w)

    # Now: w.parent === nothing (w splayed) and
    # w.path_parent === nothing (w accessed - on path from root)

    v.left = w
    w.parent = v
end

"""
    cut!(v)

Separate `v` from its parent
"""
function cut!(v::LinkCutTreeNode)
    access!(v)

    if v.left !== nothing
        v.left.parent = nothing
        v.left = nothing
    end
end

function _find_path_root(v::LinkCutTreeNode)
    while v.left !== nothing
        v = v.left
    end
    return v
end

"""
    find_root!(v)

Return the root node of the tree that holds `v`
"""
function find_root!(v::LinkCutTreeNode)
    access!(v)
    r = _find_path_root(v)
    access!(r)
    return r
end

function rotate_left!(v::LinkCutTreeNode)

    #       v
    #     /   \
    #    /     w
    #   ...  /   \
    #       b     ...

    #       w
    #     /   \
    #    v     \
    #  /   \    ...
    # ...   b

    w = v.right
    b = w.left

    v.right = b
    if b !== nothing
        b.parent = v
    end
    w.parent = v.parent
    if v.parent === nothing
        w.path_parent = v.path_parent
        v.path_parent = nothing
    elseif v === v.parent.left
        v.parent.left = w
    else
        v.parent.right = w
    end
    w.left = v
    v.parent = w
end

function rotate_right!(v::LinkCutTreeNode)

    #       v
    #     /   \
    #    u     \
    #  /   \    ...
    # ...   b

    #       u
    #     /   \
    #    /     v
    #   ...  /   \
    #       b     ...

    u = v.left
    b = u.right

    v.left = b
    if b !== nothing
        b.parent = v
    end
    u.parent = v.parent
    if v.parent === nothing
        u.path_parent = v.path_parent
        v.path_parent = nothing
    elseif v === v.parent.left
        v.parent.left = u
    else
        v.parent.right = u
    end
    u.right = v
    v.parent = u
end

function splay!(v::LinkCutTreeNode)
    while v.parent !== nothing
        p = v.parent
        pp = p.parent

        if pp === nothing
            if p.left === v
                rotate_right!(p)
            else
                rotate_left!(p)
            end
        else
            if v === p.left && p === pp.left
                rotate_right!(pp)
                rotate_right!(p)
            elseif v === p.right && p === pp.right
                rotate_left!(pp)
                rotate_left!(p)
            elseif v === p.right && p === pp.left
                rotate_left!(p)
                rotate_right!(pp)
            else
                rotate_right!(p)
                rotate_left!(pp)
            end
        end
    end
end
