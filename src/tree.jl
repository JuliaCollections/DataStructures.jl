abstract Tree{K,V}

type EmptyTree{K,V} <: Tree{K,V}
end

type BinaryTreeNode{K,V} <: Tree{K,V}
    key::  K
    data:: V
    left:: Tree{K,V}
    right::Tree{K,V}
end

type BinaryTree{K,V}
    root:: Tree{K,V}

    BinaryTree() = new(EmptyTree{K,V}())
end

haskey(t::EmptyTree, key) = false
haskey(t::BinaryTree, key) = haskey(t.root, key)

function haskey(t::BinaryTreeNode, key)
    if t.key == key
        true
    elseif key < t.key
        haskey(t.left, key)
    else
        haskey(t.right, key)
    end
end

getindex(t::EmptyTree, k) = throw(KeyError(k))
getindex(t::BinaryTree, k) = t.root[k]

function getindex(t::BinaryTreeNode, key)
    if t.key == key
        t.data
    elseif key < t.key
        t.left[key]
    else
        t.right[key]
    end
end

setindex!{K,V}(t::EmptyTree{K,V}, v, k) = BinaryTreeNode{K,V}(k, v, t, t)
setindex!(t::BinaryTree, v, k) = (t.root = setindex!(t.root, v, k); t)

function setindex!(t::BinaryTreeNode, v, k)
    if t.key == k
        t.data = v
    elseif k < t.key
        t.left = setindex!(t.left, v, k)
    else
        t.right = setindex!(t.right, v, k)
    end
    t
end

delete!(t::EmptyTree, k) = throw(KeyError(k))
delete!(t::BinaryTree, k) = (t.root = delete!(t.root, k); t)

function delete!(t::BinaryTreeNode, k)
    if t.key == k
        if isa(t.right,EmptyTree)
            t = t.left
        elseif isa(t.left,EmptyTree)
            t = t.right
        else
            r = t.right
            t = t.left
            treeinsert!(t, r)
        end
    elseif k < t.key
        t.left = delete!(t.left, k)
    else
        t.right = delete!(t.right, k)
    end
    t
end

treeinsert!(t::EmptyTree, r::BinaryTreeNode) = r

function treeinsert!(t::BinaryTreeNode, r::BinaryTreeNode)
    if r.key < t.key
        t.left = treeinsert!(t.left, r)
    else
        t.right = treeinsert!(t.right, r)
    end
    t
end
