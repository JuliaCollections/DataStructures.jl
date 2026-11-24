mutable struct BTreeNode{K}
    leaf::Bool
    keys::Vector{K}
    child::Vector{BTreeNode{K}}

    BTreeNode{K}(isleaf::Bool) where K = new{K}(isleaf, Vector{K}(), Vector())
end

BTreeNode(isleaf::Bool) = BTreeNode{Any}(isleaf)

# `root` is the root of BTree of order `t`
mutable struct BTree{K} 
    root::BTreeNode{K}
    t::Int

    BTree{K}(t::Integer) where K = new{K}(BTreeNode{K}(true), t)
end

BTree(t::Integer) = BTree{Any}(t)

function Base.insert!(tree::BTree{K}, key::K) where K
    root = tree.root
    if length(root.keys) == (2* tree.t) - 1
        temp = BTreeNode{K}(false)
        tree.root = temp
        insert!(temp.child, 1, root)
        split_child!(tree, temp, 1)
        insert_non_full!(tree, temp, key)
    else
        insert_non_full!(tree, root, key)
    end
end

function split_child!(tree::BTree{K}, x::BTreeNode{K}, i::Integer) where K
    t = tree.t
    y = x.child[i]
    z = BTreeNode{K}(y.leaf)
    insert!(x.child, i+1, z)
    insert!(x.keys, i, y.keys[t])
    z.keys = y.keys[t+1:end]
    y.keys = y.keys[1:t-1]
    if !y.leaf
        z.child = y.child[t+1:end]
        y.child = y.child[1:t-1]
    end
end

_growend!(a::Vector, delta::Integer) =
           ccall(:jl_array_grow_end, Cvoid, (Any, UInt), a, delta)

function insert_non_full!(tree::BTree{K}, x::BTreeNode{K}, k::K) where K
    i = length(x.keys)
    if x.leaf
        _growend!(x.keys, 1)
        @inbounds while i > 0 && k < x.keys[i]
            x.keys[i+1] = x.keys[i]
            i -= 1
        end
        x.keys[i+1] = k
    else
        @inbounds while i > 0 && k < x.keys[i]
            i -= 1
        end
        i += 1
        if length(x.child[i].keys) == (2 * tree.t) - 1
            split_child!(tree, x, i)
            (k > x.keys[i]) && (i += 1)
        end
        insert_non_full!(tree, x.child[i], k)
    end
end

function search_key(tree::BTree{K}, k::K) where K
    function search_tree_helper(x::BTreeNode, k)
        i = 1
        n = length(x.keys)
        # binary search can be used to speed up if `t` is large
        @inbounds while i <= n && k > x.keys[i]
            i += 1
        end
        @inbounds if i <= n && k == x.keys[i]
            return k
        elseif x.leaf
            return nothing
        else 
            return search_tree_helper(x.child[i], k)
        end
    end
    ki = search_tree_helper(tree.root, k)
    return !isa(ki, Nothing)
end

function delete_internal_node(tree::BTree{K}, x::BTreeNode{K}, k::K, i::Integer) where K
    t = tree.t
    if x.leaf
        @inbounds if x.keys[i] == k
            deleteat!(x.keys, i)
        end
        return
    end

    if length(x.child[i].keys) >= t:
        x.keys[i] = delete_predecessor(tree, x.child[i])
        return
    elseif length(x.child[i+1].keys) >= t:
        x.keys[i] = delete_successor(tree, x.child[i+1])
        return
    else
        delete_merge(tree, x, i, i+1)
        delete_internal_node(tree, x.child[i], k, t)
        return
    end
end

function print_tree(tree::BTree)

    function traverse_tree(x::BTreeNode, lvl)
        println("Level ", lvl, " ", x.keys, " isleaf ", x.leaf)
        lvl += 1
        if !isempty(x.child)
            for y in x.child
                traverse_tree(y, lvl)
            end
        end
    end

    traverse_tree(tree.root, 1)
end
