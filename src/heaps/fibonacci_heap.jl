# Fibonacci heap

mutable struct MutableFibonacciHeapNode{T}
    value::T
    degree::Int
    parent::Union{MutableFibonacciHeapNode, Nothing}
    child::Union{MutableFibonacciHeapNode, Nothing}
    left::Union{MutableFibonacciHeapNode, Nothing}
    right::Union{MutableFibonacciHeapNode, Nothing}
    mark::Bool
    flag::Bool
end

MutableFibonacciHeapNode(data::T) where T = MutableFibonacciHeapNode{T}(data, 0, nothing, nothing, nothing, nothing, false, false)
#################################################
#
#   heap type and constructors
#
#################################################
mutable struct MutableFibonacciHeap{T} <: AbstractMutableHeap{T}
    rootList::Union{MutableFibonacciHeapNode{T}, Nothing}
    minNode::Union{MutableFibonacciHeapNode{T}, Nothing}
    nodeCount::Int

    MutableFibonacciHeap{T}() where T = new{T}(nothing, nothing, 0)

    function MutableFibonacciHeap{T}(xs::AbstractVector{T}) where T
        fiboHeap = _make_fibonacci_heap(xs,T)
        new{T}(fiboHeap.rootList,fiboHeap.minNode,fiboHeap.nodeCount)
    end
    
end
const FibonacciHeap{T} = MutableFibonacciHeap{T}
FibonacciHeap(xs::AbstractVector{T}) where T = FibonacciHeap{T}(xs)
#################################################
#
#   core implementation
#
#################################################
# make fibonacci_heap from Vector
function _make_fibonacci_heap(xs::AbstractVector{T},Typ::Type{T}) where T
    len = length(xs)
    fiboHeap = MutableFibonacciHeap{Typ}()
    for i = 1 : len
        push!(fiboHeap,xs[i])
    end
    fiboHeap
end

# merge a node with the doubly linked root list
function _merge_with_root_list(root::MutableFibonacciHeap{T}, node::MutableFibonacciHeapNode{T}) where T
    if root.rootList == nothing
        root.rootList = node
    else
        node.right = root.rootList.right
        node.left = root.rootList
        root.rootList.right.left = node
        root.rootList.right = node
    end
end
# remove a node from the doubly linked root list
function _remove_from_root_list(root::MutableFibonacciHeap{T}, node::MutableFibonacciHeapNode{T}) where T
    if node == root.rootList
        root.rootList = node.right
    end
    node.left.right = node.right
    node.right.left = node.left
end

# remove a node from the doubly linked child list
function _remove_from_child_list(root::MutableFibonacciHeap{T}, parent::MutableFibonacciHeapNode{T}, node::MutableFibonacciHeapNode{T}) where T
    if parent.child == parent.child.right
        parent.child = nothing
    elseif parent.child == node
        parent.child = node.right
        node.right.parent = parent
    end
    node.left.right = node.right
    node.right.left = node.left
end

# merge a node with the doubly linked child list of a root node
function _merge_with_child_list(root::MutableFibonacciHeap{T}, parent::MutableFibonacciHeapNode{T}, node::MutableFibonacciHeapNode{T}) where T
    if parent.child == nothing
        parent.child = node
    else
        node.right = parent.child.right
        node.left = parent.child
        parent.child.right.left = node
        parent.child.right = node
    end
end

# extract (delete) the min node from the heap in O(log n) time
function extractMin(root::MutableFibonacciHeap)
    minimumNode = root.minNode
    if minimumNode !== nothing
        if minimumNode.child !== nothing
            # attach child nodes to root list
            allChild = aslist(minimumNode.child)
            for child in allChild
                _merge_with_root_list(root, child)
                child.parent = nothing
            end
        end
        
        _remove_from_root_list(root, minimumNode)
        # set new min node in heap
        if minimumNode == minimumNode.right
            root.minNode = root.rootList = nothing
        else
            root.minNode = minimumNode.right
            consolidate(root)
        end
        root.nodeCount -= 1
    end
    return minimumNode.value
end

# actual linking of one node to another in the root list
# while also updating the child linked list
function heaplink(root::MutableFibonacciHeap{T}, y::MutableFibonacciHeapNode{T}, x::MutableFibonacciHeapNode{T}) where T
    _remove_from_root_list(root, y)
    y.left = y.right = y
    _merge_with_child_list(root, x, y)
    x.degree += 1
    y.parent = x
    y.mark = false
end

# combine root nodes of equal degree to consolidate the heap
# by creating a list of unordered binomial trees
function consolidate(root::MutableFibonacciHeap{T}) where T
    nodes = aslist(root.rootList)
    len = length(nodes)
    A = fill!(Vector{Union{MutableFibonacciHeapNode, Nothing}}(undef, Int(round(log(root.nodeCount)) * 2)), nothing)
    for x in nodes
        d = x.degree + 1
        while A[d] !== nothing
            y = A[d]
            if x.value > y.value
                x, y = y, x
            end
            heaplink(root, y, x)
            A[d] = nothing
            d += 1
        end
        A[d] = x
    end
    for nod in A
        if nod !== nothing && nod.value < root.minNode.value
            root.minNode = nod
        end
    end
end


# cut this child node off and bring it up to the root list
function cut(root::MutableFibonacciHeap{T}, x::MutableFibonacciHeapNode{T}, y::MutableFibonacciHeapNode{T}) where T
    _remove_from_child_list(root, y, x)
    y.degree -= 1
    _merge_with_root_list(root, x)
    x.parent = nothing
    x.mark = false
end

# cascading cut of parent node to obtain good time bounds
function cascadingcut(root::MutableFibonacciHeap{T}, y::MutableFibonacciHeapNode{T}) where T
    pNode = y.parent
    if pNode !== nothing
        if y.mark == false
            y.mark = true
        else
            cut(root, y, pNode)
            cascadingcut(root, pNode)
        end
    end
end

# Get list of nodes attached to head (of a circular doubly linked list)
function aslist(head::MutableFibonacciHeapNode)
    nodelist, node, stop = MutableFibonacciHeapNode[], head, head
    flag = false
    while true
        if node == stop
            flag && break
            flag = true
        end
        push!(nodelist, node)
        node = node.right
    end
    return nodelist
end

function Base.show(io::IO, h::MutableFibonacciHeap{T}) where T
    if h.nodeCount == 0
        print(io,"FibonacciHeap{$T}()")
        return
    end
    print(io, "FibonacciHeap([")
    print(io,"$(h.rootList.value)")
    show_heap_helper(io, h.rootList,h)
    print(io,"])")
end


function show_heap_helper(io::IO,rootnode::MutableFibonacciHeapNode{T},h::MutableFibonacciHeap{T}) where T
    node = rootnode
    while node !== nothing
        if node !== h.rootList
            print(io,",$(node.value)")
        end
        if node.child !== nothing
            show_heap_helper(io, node.child,h)
        end
        if node.right == rootnode
            break
        end
        node = node.right
    end
end

function findNode(head::MutableFibonacciHeapNode{T}, key::T) where T
    found::Union{MutableFibonacciHeapNode,Nothing} = nothing
    temp = head
    temp.flag = true
    if temp.value === key
        found = temp; 
        temp.flag = false; 
        return found; 
    end
    if found === nothing
        if temp.child !== nothing
            return findNode(temp.child, key); 
        end
        if (temp.right).flag === false
            return findNode(temp.right, key); 
        end
    end
    temp.flag = false;

end
#################################################
#
#   interfaces
#
#################################################

length(h::MutableFibonacciHeap) = h.nodeCount

isempty(h::MutableFibonacciHeap) = h.nodeCount == 0

# function sizehint!(h::MutableFibonacciHeap, s::Integer)
#     sizehint!(h.nodes, s)
#     sizehint!(h.node_map, s)
#     return h
# end

"""
        top(h::MutableFibonacciHeap)

Returns the value of top element in heap `h`
"""
@inline top(h::MutableFibonacciHeap) = h.minNode.value

"""
        top_with_handle(h::MutableFibonacciHeap)

Returns the top element of the heap `h` and its handle.
"""
@inline minimum(h::MutableFibonacciHeap) = h.minNode.value

@inline top_with_handle(h::MutableFibonacciHeap) = h.minNode

@inline minimum_with_handle(h::MutableFibonacciHeap) = h.minNode
"""
    push!{T}(h::MutableFibonacciHeap{T},data::T)

Insert element into the heap `h` and return its handle.
"""
function push!(root::MutableFibonacciHeap,data::T) where T
    node = MutableFibonacciHeapNode(data)
    node.left = node.right = node
    _merge_with_root_list(root, node)
    if root.minNode === nothing || node.value < root.minNode.value
        root.minNode = node
    end
    root.nodeCount += 1
    return node
end

"""
    pop!(h::MutableFibonacciHeap)

Delete the top element node from heap `h` and return its handle
"""
pop!(root::MutableFibonacciHeap) = extractMin(root)

popmin!(root::MutableFibonacciHeap) = extractMin(root)
"""
    merge!{T}(h1::MutableFibonacciHeap{T}, h2::MutableFibonacciHeap{T})

merge two fibonacci heapsby concatenating the root lists of heap `h1` and `h2`
returns handler to merged list
"""
function merge!(h1::MutableFibonacciHeap{T}, h2::MutableFibonacciHeap{T}) where T
    newh = FibonacciHeap{T}()
    newh.rootList, newh.minNode = h1.rootList, h1.minNode
    last = h2.rootList.left
    h2.rootList.left = newh.rootList.left
    newh.rootList.left.right = h2.rootList
    newh.rootList.left = last
    newh.rootList.left.right = newh.rootList
    if h2.minNode.value < newh.minNode.value
        newh.minNode = h2.minNode
    end
    newh.nodeCount = h1.nodeCount + h2.nodeCount
    return newh
end

"""
    update!{T}(h::MutableFibonacciHeap{T}, x::Any, k::Any}

modify the data of node `x` in the heap `h` to value `k`
"""
function update!(root::MutableFibonacciHeap{T}, oldkey::T, newkey::T) where T
    x = findNode(root.rootList,oldkey)
    if newkey > x.value
        x.value = newkey
        return nothing
    end
    x.value = newkey
    y = x.parent
    if y !== nothing && x.value < y.value
        cut(root, x, y)
        cascadingcut(root, y)
    end
    if x.value < root.minNode.value
        root.minNode = x
    end
end   

"""
    delete!(h::MutableFibonacciHeap, x::Any)

delete node `x` from heap `h`
""" 
function delete!(root::MutableFibonacciHeap{T}, key::T) where T
    node = findNode(root.rootList,key)
    if (parent = node.parent) === nothing
        if node.child !== nothing
            cut(root, node.child, node)
        end
        _remove_from_root_list(root, node)
    else
        _remove_from_child_list(root, parent, node)
    end
    if root.rootList !== nothing
        root.nodeCount -= 1
        root.minNode = root.rootList
        for n in aslist(root.rootList)
            if n !== nothing && n.value < root.minNode.value
                root.minNode = n
            end
        end
    end
end 