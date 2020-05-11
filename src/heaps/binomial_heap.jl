# Binomial Heap
mutable struct MutableBinomialHeapNode{T} 
    data::T
    degree::Int
    handle::Int
    parent::Union{MutableBinomialHeapNode,Nothing}
    child::Union{MutableBinomialHeapNode, Nothing}
    sibling::Union{MutableBinomialHeapNode, Nothing}
end
MutableBinomialHeapNode(data::T, handle::Int) where T = MutableBinomialHeapNode{T}(data, 0, handle, nothing, nothing, nothing)
#################################################
#
#   heap type and constructors
#
#################################################
mutable struct MutableBinomialHeap{T} <: AbstractHeap{T}
    rootList::Vector{Union{Nothing, MutableBinomialHeapNode{T}}}
    nodecount::Int
    cumm_nodecount::Int

    function MutableBinomialHeap{T}() where T 
        return new{T}(Vector{MutableBinomialHeapNode{T}}(), 0, 0)
    end

    MutableBinomialHeap(xs::AbstractVector{T}) where T = MutableBinomialHeap{T}(xs::AbstractVector{T})

    function MutableBinomialHeap{T}(xs::AbstractVector{T}) where T
        BinomialHeap = _make_binomial_heap(xs)
        new{T}(BinomialHeap.rootList, BinomialHeap.nodecount, BinomialHeap.cumm_nodecount)
    end  
end

struct HeapBoundsError <: Exception
    a::Type
    i::Int
    HeapBoundsError(@nospecialize(a), i) = new(a,i)
end

function Base.summary(io::IO, ty::Type, i::Int )
    print(io,i-1)
    print(io," element")
    print(io," MutableBinomialHeap{$ty}")
end

function Base.showerror(io::IO, ex::HeapBoundsError)
    print(io, "HeapBoundsError")
    if isdefined(ex, :a)
        print(io, ": attempt to access ")
        if isdefined(ex, :i)
            summary(io, ex.a, ex.i)
            print(io, " at index [")
            print(io, ex.i)
            print(io, ']')
        end
    end
end

function show(io::IO, _heap::MutableBinomialHeap{T}) where T
    print(io, "MutableBinomialHeap")
    list = _heap.rootList
    n = length(list)
    nodecount = _heap.nodecount
    if n == 0
        print(io, "{$(T)}()")
        return
    end
    print(io, "([")
    counter = 0
    for node in list
        counter = show_tree(io, node, nodecount, counter)
    end
    print(io, "])")
end

function show_tree(io::IO, h::Union{MutableBinomialHeapNode{T}, Nothing}, nodecount, counter) where T
    while h !== nothing 
        show(io, h.data)
        counter+=1
        if counter < nodecount
            print(io, ", ")
        end
        counter = show_tree(io, h.child,nodecount,counter) 
        h = h.sibling; 
    end
    return counter
end
#################################################
#
#   core implementation
#
#################################################
# make Binomial_heap from Vector
function _make_binomial_heap(xs)
    T = eltype(xs)
    binomial_heap = MutableBinomialHeap{T}()
    for x in xs
        push!(binomial_heap, x)
    end
    return binomial_heap
end

# This function merge two Binomial Trees. 
function merge_binomial_trees!(b1::MutableBinomialHeapNode{T}, b2::MutableBinomialHeapNode{T}) where T 
    if b1.data > b2.data
        b1, b2 = b2, b1
    end
    b2.parent = b1 
    b2.sibling = b1.child 
    b1.child = b2 
    b1.degree += 1 
    return b1
end

# adjust! function rearranges the heap so that 
# heap is in increasing order of degree and 
# no two binomial trees have same degree in this heap 
function adjust!(heap::MutableBinomialHeap)
    _heap = heap.rootList
    n = length(_heap)
    n <= 1 && return
    i = 1
    if n == 2
        j = 2
        k = n + 1
    else
        j = i + 1
        k = j + 1
    end
    while i <= length(_heap)
        current_size = length(_heap) + 1
        if j >= current_size
            i += 1
        elseif _heap[i].degree < _heap[j].degree
            i += 1
            j += 1
            if k !== current_size
                k += 1
            end
        elseif (k < current_size)  && (_heap[i].degree == _heap[j].degree) && (_heap[i].degree == _heap[k].degree)
            i += 1
            j += 1
            k += 1  
        elseif _heap[i].degree == _heap[j].degree
            merged_trees = merge_binomial_trees!(_heap[i], _heap[j])
            _heap[i] = merged_trees
            deleteat!(_heap, j)
            if k < (length(_heap) + 1)
                k = j + 1 
            end 
        end
    end
end

function _insert_tree_in_heap!(_heap::MutableBinomialHeap{T}, tree::MutableBinomialHeapNode{T}) where T 
    sub_heap = MutableBinomialHeap{T}()
    push!(sub_heap.rootList, tree)
    _union!(_heap, sub_heap, true)
    adjust!(_heap)
    return
end 

function _remove_min_from_tree!(tree::MutableBinomialHeapNode{T}) where T 
    heap = Union{Nothing, MutableBinomialHeapNode{T}}[]
    iterator_node = tree.child; 
    while iterator_node !== nothing 
        lo = iterator_node 
        iterator_node = iterator_node.sibling 
        lo.sibling = nothing 
        push!(heap, lo)
    end 
    return reverse!(heap) 
end

function extract_min!(heap::MutableBinomialHeap{T}) where T
    _heap = heap.rootList
    new_heap = MutableBinomialHeap{T}()
    lo = MutableBinomialHeap{T}()
    top_node = top_element_node(heap)
    for node in _heap
        node != top_node && push!(new_heap.rootList, node)
    end
    lo.rootList = _remove_min_from_tree!(top_node)
    new_heap.nodecount = heap.nodecount - 1
    _union!(new_heap, lo, false)
    adjust!(new_heap)
    heap.rootList = new_heap.rootList
    heap.nodecount -= 1
    return top_node.data
end

function find_helper(node::Union{MutableBinomialHeapNode{T}, Nothing}, i::Int) where T
    node === nothing && return nothing
    node.handle == i && return node
    res = find_helper(node.child, i)
    res !== nothing && return res
    return find_helper(node.sibling, i)
end
    
function find_node(heap::MutableBinomialHeap{T}, i::Int) where T
    _heap = heap.rootList
    node = nothing
    length(_heap) == 0 && return nothing
    node = nothing
    for sub in _heap
        node = find_helper(sub, i)
        node !== nothing && break
    end
    if node !== nothing
        return node
    end
    throw(HeapBoundsError(T,i))
end

function increase_key!(node::MutableBinomialHeapNode{T}, new_val::T) where T
    node.data = new_val
    child = node.child
    while child !== nothing && node.data > child.data
        # swap node and child
        node.data, child.data = child.data, node.data
        node.handle, child.handle = child.handle, node.handle
        node = child
        child = child.child
    end
end

function decrease_key!(heap::MutableBinomialHeap{T}, i::Int, new_val) where T
    new_val = convert(T, new_val)
    node = find_node(heap, i)
    node === nothing && throw(HeapBoundsError(T,i))
    if node.data > new_val
        node.data = new_val
        parent = node.parent
        while parent !== nothing && node.data < parent.data
            # swap node and parent
            node.data, parent.data = parent.data, node.data
            node.handle, parent.handle = parent.handle, node.handle
            node = parent
            parent = parent.parent
        end
    else increase_key!(node, new_val)
    end
end

function top_element_node(heap::MutableBinomialHeap)
    _heap = heap.rootList
    length(_heap) == 0 && return nothing
    it = iterate(_heap)
    if it === nothing
        throw(HeapBoundsError(eltype(heap),heap.nodecount))
    end
    @inbounds top_node = _heap[1]
    while it !== nothing
        elem, state = it
        if elem.data < top_node.data 
            top_node = elem 
        end
        it = iterate(_heap, state) 
    end
    return top_node
end

function update_handle!(c::Int, h::MutableBinomialHeap)
    node::Union{Nothing, MutableBinomialHeapNode{T}} where T = nothing 
    for i = 1:h.cumm_nodecount
        node = nothing
        try
            node = find_node(h, i)
            node.handle = node.handle + c
        catch _
            continue
        end
    end
end

# update_handle_flag determines how _union! is used
# When explicitly called to merge two binomial heaps it is set true.
function _union!(h1::MutableBinomialHeap{T}, h2::MutableBinomialHeap{T}, update_handle_flag::Bool) where T
    _new = MutableBinomialHeap{T}()
    update_handle_flag && update_handle!(h1.cumm_nodecount, h2)
    l1 = h1.rootList
    l2 = h2.rootList
    h1.nodecount += h2.nodecount
    h1.cumm_nodecount += h2.cumm_nodecount
    iter1 = iterate(l1)
    iter2 = iterate(l2)
    while (iter1 !== nothing && iter2 !== nothing)
        (elem1, state1) = iter1
        (elem2, state2) = iter2
        if( elem1.degree <= elem2.degree) 
            push!(_new.rootList, elem1)
            iter1 = iterate(l1, state1)
        else
            push!(_new.rootList, elem2)
            iter2 = iterate(l2, state2)
        end
    end
    while (iter1 !== nothing)
        (elem1, state1) = iter1 
        push!(_new.rootList, elem1) 
        iter1 = iterate(l1, state1) 
    end
    while (iter2 !== nothing)
        (elem2, state2) = iter2
        push!(_new.rootList, elem2)
        iter2 = iterate(l2, state2)
    end
    h1.rootList = _new.rootList
    adjust!(h1)
    return 
end

function push!(_heap::MutableBinomialHeap{T}, key) where T
    handle = _heap.cumm_nodecount + 1
    new_node = MutableBinomialHeapNode(convert(T, key), handle)
    _insert_tree_in_heap!(_heap, new_node)
    _heap.nodecount = _heap.nodecount + 1
    _heap.cumm_nodecount = _heap.cumm_nodecount + 1
    return new_node.handle
end
#################################################
#
#   interfaces
#
#################################################
length(h::MutableBinomialHeap) = h.nodecount

isempty(h::MutableBinomialHeap) = isempty(h.rootList)

"""
_union!(h1::MutableBinomialHeap, h2::MutableBinomialHeap)

merges heap `h2` into heap `h1`
"""
_union!(h1::MutableBinomialHeap, h2::MutableBinomialHeap) = _union!(h1, h2, true)


function sizehint!(h::MutableBinomialHeap, s::Integer)
    sizehint!(h.rootList, s)
    return h
end

@inline top(heap::MutableBinomialHeap) =  top_with_handle(heap)[1]

@inline minimum(heap::MutableBinomialHeap) =  top_with_handle(heap)[1]

"""
top_with_handle(h::MutableBinomialHeap)

Returns the minimum element of the heap `h` and its handle.
"""
function top_with_handle(h::MutableBinomialHeap) 
    node = top_element_node(h)
    return (node.data, node.handle)
end

"""
pop!(h::MutableBinomialHeap)

Returns the minimum element of the heap `h` and its handle and alo deletes it from heap
"""
pop!(h::MutableBinomialHeap{T}) where {T} = extract_min!(h)

popmin!(h::MutableBinomialHeap{T}) where {T} = extract_min!(h)

"""
update!{T}(h::MutableBinomialHeap{T}, i::Int, new_val::T)

Replace the element having handle 'i' in heap `h` with `new_val`.
"""
update!(h::MutableBinomialHeap{T}, i::Int, new_val) where T = decrease_key!(h, i, new_val)

"""
delete!{T}(h::MutableBinomialHeap{T}, i::Int)

Deletes the element with handle 'i' from heap `h` .
"""
function delete!(heap::MutableBinomialHeap{T}, i::Int) where T 
    n = length(heap.rootList)
    n == 0 && return nothing
    decrease_key!(heap, i, typemin(T)) 
    extract_min!(heap)
    return heap
end

setindex!(h::MutableBinomialHeap, v, i::Int) = update!(h, i, v)

function getindex(h::MutableBinomialHeap{T}, i::Int) where T 
    x = find_node(h, i)
    x != nothing ? x.data : throw(HeapBoundsError(T,i))
end


