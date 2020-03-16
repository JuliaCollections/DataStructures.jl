# Binomial Heap
mutable struct MutableBinomialHeapNode{T} 
    data::T
    degree::Int
    handle::Int
    parent::Union{MutableBinomialHeapNode,Nothing}
    child::Union{MutableBinomialHeapNode,Nothing}
    sibling::Union{MutableBinomialHeapNode,Nothing}
end
MutableBinomialHeapNode(data::T, handle::Int) where T = MutableBinomialHeapNode{T}(data, 0, handle, nothing, nothing, nothing)
#################################################
#
#   heap type and constructors
#
#################################################
mutable struct MutableBinomialHeap{T} <: AbstractHeap{T}
    rootList::Vector{Union{Nothing,MutableBinomialHeapNode{T}}}
    nodecount::Int
    cumm_nodecount::Int
    MutableBinomialHeap{T}() where T = new{T}([], 0, 0)

    function MutableBinomialHeap{T}(xs::AbstractVector{T}) where T
        BinomialHeap = _make_binomial_heap(xs, T)
        new{T}(BinomialHeap.rootList, BinomialHeap.nodecount, BinomialHeap.cumm_nodecount)
    end
    
end
const BinomialHeap{T} = MutableBinomialHeap{T}
BinomialHeap(xs::AbstractVector{T}) where T = MutableBinomialHeap{T}(xs)

struct HeapBoundsError <: Exception
    msg::AbstractString
end

function show(io::IO, _heap::MutableBinomialHeap{T}) where T
    print(io, "MutableBinomialHeap")
    list = _heap.rootList
    n = length(list)
    if n == 0
        print(io, "{$(T)}")
    end
    print(io, "(")
    for i = 1:n
        printTree(io, list[i])
    end
    print(io, ")")
end

function printTree(io::IO, h::Union{MutableBinomialHeapNode{T},Nothing}) where T
    while h !== nothing 
        print(io, h.data)
        print(io, ",")
        printTree(io, h.child) 
        h = h.sibling; 
    end
end
#################################################
#
#   core implementation
#
#################################################
# make Binomial_heap from Vector
function _make_binomial_heap(xs::AbstractVector{T}, Typ::Type{T}) where T
    len = length(xs)
    BinomialHeap = MutableBinomialHeap{Typ}()
    for i = 1:len
        push!(BinomialHeap, xs[i])
    end
    BinomialHeap
end

# This function merge two Binomial Trees. 
function mergeBinomialTrees(b1::MutableBinomialHeapNode{T}, b2::MutableBinomialHeapNode{T}) where T 
    if b1.data > b2.data
        b1, b2 = b2, b1
    end
    b2.parent = b1 
    b2.sibling = b1.child 
    b1.child = b2 
    b1.degree += 1 
    return b1
end
# adjust function rearranges the heap so that 
# heap is in increasing order of degree and 
# no two binomial trees have same degree in this heap 
function adjust(heap::MutableBinomialHeap{T}) where T
    _heap = heap.rootList
    n = length(_heap)
    if n <= 1
        return
    end
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
            temp = mergeBinomialTrees(_heap[i], _heap[j])
            _heap[i] = temp
            @inbounds _heap[j] = nothing
            filter!(e->e ≠ nothing, _heap)
            if k < (length(_heap) + 1)
                k = j + 1 
            end
        end
    end
end

function insertATreeInHeap(_heap::MutableBinomialHeap{T}, tree::MutableBinomialHeapNode{T}) where T 
    temp = MutableBinomialHeap{T}()
    push!(temp.rootList, tree)
    union!(_heap, temp, true)
    adjust(_heap)
    return
end   
function removeMinFromTreeReturnBHeap(tree::MutableBinomialHeapNode{T}) where T 
    heap::Vector{Union{Nothing,MutableBinomialHeapNode{T}}} = []
    temp = tree.child; 
    while temp !== nothing 
        lo = temp 
        temp = temp.sibling 
        lo.sibling = nothing 
        push!(heap, lo)
    end 
    return reverse!(heap) 
end

function extractMin!(heap::MutableBinomialHeap{T}) where T
    _heap = heap.rootList
    new_heap = MutableBinomialHeap{T}()
    lo = MutableBinomialHeap{T}()
    (val, temp) = top_elem_with_handle(heap)
    it = iterate(_heap)
    while it !== nothing
        if it[1] != temp
            push!(new_heap.rootList, it[1])
        end
        it = iterate(_heap, it[2])
    end
    lo.rootList = removeMinFromTreeReturnBHeap(temp)
    new_heap.nodecount = heap.nodecount - 1
    union!(new_heap, lo, false)
    adjust(new_heap)
    heap.rootList = new_heap.rootList
    heap.nodecount -= 1
    return temp.data
end

function findhelper(node::Union{MutableBinomialHeapNode{T},Nothing}, i::Int) where T
    if node === nothing 
        return nothing
    end
    if node.handle == i 
        return node
    end
    res = findhelper(node.child, i)
    if res !== nothing 
        return res
    end
    return findhelper(node.sibling, i)
end
    
function findNode(heap::MutableBinomialHeap{T}, i::Int) where T 
    _heap = heap.rootList
    node = nothing
    n = length(_heap)
    if n == 0
        return nothing
    end
    for j = 1:n
        node = findhelper(_heap[j], i)
        if node !== nothing
            break
        end
    end
    if node === nothing
        throw(HeapBoundsError("attempt to access $(heap.nodecount) MutableBinomialHeap{$(T)} at index [$(heap.nodecount + 1)]"))
    end
    return node
end
function increaseKey!(node::MutableBinomialHeapNode{T}, new_val::T) where T
    node.data = new_val
    child = node.child

    while child !== nothing && node.data > child.data
        node.data, child.data = child.data, node.data
        node.handle, child.handle = child.handle, node.handle
        node = child
        child = child.child
    end
end
function decreaseKey!(heap::MutableBinomialHeap{T}, i::Int, new_val) where T
    new_val = convert(T, new_val)
    node = findNode(heap, i)
    if node === nothing
        return 
    end
    if node.data > new_val
        node.data = new_val
        parent = node.parent
        while parent !== nothing && node.data < parent.data
            node.data, parent.data = parent.data, node.data
            node.handle, parent.handle = parent.handle, node.handle
            node = parent
            parent = parent.parent
        end
    else increaseKey!(node, new_val)
    end
end

function top_elem_with_handle(heap::MutableBinomialHeap{T}) where T 
    _heap = heap.rootList
    if length(_heap) == 0
        return nothing
    end
    it = iterate(_heap)
    @inbounds temp = _heap[1]
    while it !== nothing
        elem, state = it
        if elem.data < temp.data 
            temp = elem 
        end
        it = iterate(_heap, state) 
    end
    return (temp.data, temp)
end

function update_handle(c::Int, h::MutableBinomialHeap)
    node::Union{Nothing,MutableBinomialHeapNode{T}} where T = nothing 
    for i = 1:h.cumm_nodecount
        node = nothing
        try
            node = findNode(h, i)
            node.handle = node.handle + c
        catch _
            continue
        end
    end
end

function union!(h1::MutableBinomialHeap{T}, h2::MutableBinomialHeap{T}, flag::Bool) where T
    _new = MutableBinomialHeap{T}()
    if flag
        update_handle(h1.cumm_nodecount, h2)
    end
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
    adjust(h1)
    return 
end

function push!(_heap::MutableBinomialHeap{T}, key) where T
    handle = _heap.cumm_nodecount + 1
    temp = MutableBinomialHeapNode(convert(T, key), handle)
    insertATreeInHeap(_heap, temp)
    _heap.nodecount = _heap.nodecount + 1
    _heap.cumm_nodecount = _heap.cumm_nodecount + 1
    return temp.handle
end
#################################################
#
#   interfaces
#
#################################################
length(h::MutableBinomialHeap) = h.nodecount

isempty(h::MutableBinomialHeap) = isempty(h.rootList)

"""
union!(h1::MutableBinomialHeap, h2::MutableBinomialHeap)

merges heap `h2` into heap `h1`
"""
union!(h1::MutableBinomialHeap, h2::MutableBinomialHeap) = union!(h1, h2, true)


function sizehint!(h::MutableBinomialHeap, s::Integer)
    sizehint!(h.rootList, s)
    return h
end

@inline top(heap::MutableBinomialHeap) =  top_with_handle(heap)[1]

minimum(heap::MutableBinomialHeap) =  top_with_handle(heap)[1]
"""
top_with_handle(h::MutableBinomialHeap)

Returns the minimum element of the heap `h` and its handle.
"""
function top_with_handle(h::MutableBinomialHeap) 
    (val, node) = top_elem_with_handle(h)
    return (val, node.handle)
end

"""
pop!(h::MutableBinomialHeap)

Returns the minimum element of the heap `h` and its handle and alo deletes it from heap
"""
pop!(h::MutableBinomialHeap{T}) where {T} = extractMin!(h)
popmin!(h::MutableBinomialHeap{T}) where {T} = extractMin!(h)
"""
update!{T}(h::MutableBinomialHeap{T}, i::Int, new_val::T)

Replace the element having handle 'i' in heap `h` with `new_val`.
"""
update!(h::MutableBinomialHeap{T}, i::Int, new_val) where T = decreaseKey!(h, i, new_val)

"""
delete!{T}(h::MutableBinomialHeap{T}, i::Int)

Deletes the element with handle 'i' from heap `h` .
"""
function delete!(heap::MutableBinomialHeap{T}, i::Int) where T 
    n = length(heap.rootList)
    if n == 0
        return nothing
    end
    decreaseKey!(heap, i, typemin(T)) 
    extractMin!(heap)
    return heap
end

setindex!(h::MutableBinomialHeap, v, i::Int) = update!(h, i, v)
getindex(h::MutableBinomialHeap, i::Int) =  findNode(h, i).data
