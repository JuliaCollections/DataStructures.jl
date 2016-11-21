import Base: haskey, getindex, setindex!

export Tree, EmptyTree, RBNode, RedBlackTree

abstract Tree{K,V}

type EmptyTree{K,V} <: Tree{K,V}
end

type RBNode{K,V} <: Tree{K,V}
    key :: K
    data :: V
    left :: Tree{K,V}
    right :: Tree{K,V}
    red :: Bool
end

type RedBlackTree{K,V}
    root :: Tree{K,V}

    RedBlackTree() = new(EmptyTree{K,V}())
end

isRed(t::EmptyTree) = false

function isRed(t::RBNode)
    t.red == true
end

haskey(t::EmptyTree, key) = false
haskey(t::RedBlackTree, key) = haskey(t.root, key)

function haskey(t::RBNode, key)
    if t.key == key
        true
    elseif key < t.key
        haskey(t.left, key)
    else
        haskey(t.right, key)
    end
end

getindex(t::EmptyTree, k) = throw(KeyError(k))
getindex(t::RedBlackTree, k) = getindex(t.root, k)

function getindex(t::RBNode, k)
    if t.key == key
        t.data
    elseif key < t.key
        getindex(t.left, key)
    else
        getindex(t.right, key)
    end
end

#rotates a right leaning node to left
function rotateLeft(t::RBNode)
    x = t.right
    t.right = x.left
    x.left = t
    x.red = t.red
    t.red = true

    return x
end

#used if both the left child and grand left child are Red
function rotateRight(t::RBNode)
    x = t.left
    t.left = x.right
    x.right = t
    x.red = t.red
    t.red = true

    return x
end

#used if both left and right child are Red
function flipColors(t::RBNode)
    t.red = true
    t.left.red = false
    t.right.red = false
end


setindex!{K,V}(t::EmptyTree{K,V}, k, v) = RBNode{K,V}(k, v, t, t, true)
setindex!(t::RedBlackTree, k, v) = (t.root = setindex!(t.root, k, v))

function setindex!(t::RBNode, k, v)
    if k < t.key
        t.left = setindex!(t.left, k, v)
    elseif k > t.key
        t.right = setindex!(t.right, k, v)
    else
        t.data = v
    end

    if isRed(t.right) &&  !isRed(t.left)        #only right child is Red
        t = rotateLeft(t)
    end

    if isRed(t.left) && isRed(t.left.left)      #both left child and grand left child are Red
        t = rotateRight(t)
    end

    if isRed(t.left) && isRed(t.right)          #both left and right child are Red
        flipColors(t)
    end

    return t
end
