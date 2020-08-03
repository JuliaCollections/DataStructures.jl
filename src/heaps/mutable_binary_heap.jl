# Binary heap

struct MutableBinaryHeapNode{T}
    value::T
    handle::Int
end

#################################################
#
#   core implementation
#
#################################################

function _heap_bubble_up!(order::Ordering,
    nodes::Vector{MutableBinaryHeapNode{T}}, nodemap::Vector{Int}, nd_id::Int) where {T}

    @inbounds nd = nodes[nd_id]
    v::T = nd.value

    swapped = true  # whether swap happens at last step
    i = nd_id

    while swapped && i > 1  # nd is not root
        p = i >> 1
        @inbounds nd_p = nodes[p]

        if lt(order, v, nd_p.value)
            # move parent downward
            @inbounds nodes[i] = nd_p
            @inbounds nodemap[nd_p.handle] = i
            i = p
        else
            swapped = false
        end
    end

    if i != nd_id
        nodes[i] = nd
        nodemap[nd.handle] = i
    end
end

function _heap_bubble_down!(order::Ordering,
    nodes::Vector{MutableBinaryHeapNode{T}}, nodemap::Vector{Int}, nd_id::Int) where {T}

    @inbounds nd = nodes[nd_id]
    v::T = nd.value

    n = length(nodes)
    last_parent = n >> 1

    swapped = true
    i = nd_id

    while swapped && i <= last_parent
        il = i << 1

        if il < n   # contains both left and right children
            ir = il + 1

            # determine the better child
            @inbounds nd_l = nodes[il]
            @inbounds nd_r = nodes[ir]

            if lt(order, nd_r.value, nd_l.value)
                # consider right child
                if lt(order, nd_r.value, v)
                    @inbounds nodes[i] = nd_r
                    @inbounds nodemap[nd_r.handle] = i
                    i = ir
                else
                    swapped = false
                end
            else
                # consider left child
                if lt(order, nd_l.value, v)
                    @inbounds nodes[i] = nd_l
                    @inbounds nodemap[nd_l.handle] = i
                    i = il
                else
                    swapped = false
                end
            end

        else  # contains only left child
            nd_l = nodes[il]
            if lt(order, nd_l.value, v)
                @inbounds nodes[i] = nd_l
                @inbounds nodemap[nd_l.handle] = i
                i = il
            else
                swapped = false
            end
        end
    end

    if i != nd_id
        @inbounds nodes[i] = nd
        @inbounds nodemap[nd.handle] = i
    end
end

function _binary_heap_pop!(order::Ordering,
    nodes::Vector{MutableBinaryHeapNode{T}}, nodemap::Vector{Int}, nd_id::Int=1) where {T}

    # extract node
    rt = nodes[nd_id]
    v = rt.value
    @inbounds nodemap[rt.handle] = 0

    if length(nodes) == 1
        # clear
        empty!(nodes)
    else
        # move the last node to the position of the removed node
        @inbounds nodes[nd_id] = new_rt = nodes[end]
        pop!(nodes)
        @inbounds nodemap[new_rt.handle] = nd_id

        if length(nodes) > 1
            if lt(order, new_rt.value, v)
                _heap_bubble_up!(order, nodes, nodemap, nd_id)
            else
                _heap_bubble_down!(order, nodes, nodemap, nd_id)
            end
        end
    end
    return v
end

function _make_mutable_binary_heap(order::Ordering, ty::Type{T}, values) where {T}
    # make a static binary index tree from a list of values

    n = length(values)
    nodes = Vector{MutableBinaryHeapNode{T}}(undef, n)
    nodemap = Vector{Int}(undef, n)

    i::Int = 0
    for v in values
        i += 1
        @inbounds nodes[i] = MutableBinaryHeapNode{T}(v, i)
        @inbounds nodemap[i] = i
    end

    for i = 1 : n
        _heap_bubble_up!(order, nodes, nodemap, i)
    end
    return nodes, nodemap
end


#################################################
#
#   Binary Heap type and constructors
#
#################################################

mutable struct MutableBinaryHeap{VT, O<:Ordering} <: AbstractMutableHeap{VT,Int}
    order::O
    nodes::Vector{MutableBinaryHeapNode{VT}}
    node_map::Vector{Int}

    function MutableBinaryHeap{VT}(order::O) where {VT, O<:Ordering}
        nodes = Vector{MutableBinaryHeapNode{VT}}()
        node_map = Vector{Int}()
        new{VT, O}(order, nodes, node_map)
    end

    function MutableBinaryHeap{VT}(order::O, xs::AbstractVector{VT}) where {VT, O<:Ordering}
        nodes, node_map = _make_mutable_binary_heap(order, VT, xs)
        new{VT, O}(order, nodes, node_map)
    end
end

MutableBinaryHeap(order::Ordering, xs::AbstractVector{T}) where T = MutableBinaryHeap{T}(order, xs)

const MutableBinaryMinHeap{T} = MutableBinaryHeap{T, typeof(Forward)}
const MutableBinaryMaxHeap{T} = MutableBinaryHeap{T, typeof(Reverse)}

MutableBinaryMinHeap{T}() where T = MutableBinaryHeap{T}(Forward)
MutableBinaryMaxHeap{T}() where T = MutableBinaryHeap{T}(Reverse)
MutableBinaryMinHeap{T}(xs::AbstractVector{T}) where T = MutableBinaryHeap{T}(Forward, xs)
MutableBinaryMaxHeap{T}(xs::AbstractVector{T}) where T = MutableBinaryHeap{T}(Reverse, xs)
MutableBinaryMinHeap(xs::AbstractVector{T}) where T = MutableBinaryMinHeap{T}(xs)
MutableBinaryMaxHeap(xs::AbstractVector{T}) where T = MutableBinaryMaxHeap{T}(xs)

# deprecated constructors

@deprecate mutable_binary_minheap(::Type{T}) where {T} MutableBinaryMinHeap{T}()
@deprecate mutable_binary_minheap(xs::AbstractVector{T}) where {T} MutableBinaryMinHeap(xs)
@deprecate mutable_binary_maxheap(::Type{T}) where {T} MutableBinaryMaxHeap{T}()
@deprecate mutable_binary_maxheap(xs::AbstractVector{T}) where {T} MutableBinaryMaxHeap(xs)


function show(io::IO, h::MutableBinaryHeap)
    print(io, "MutableBinaryHeap(")
    nodes = h.nodes
    n = length(nodes)
    if n > 0
        print(io, string(nodes[1].value))
        for i = 2 : n
            print(io, ", $(nodes[i].value)")
        end
    end
    print(io, ")")
end


#################################################
#
#   interfaces
#
#################################################

length(h::MutableBinaryHeap) = length(h.nodes)

isempty(h::MutableBinaryHeap) = isempty(h.nodes)

function push!(h::MutableBinaryHeap{T}, v) where T
    nodes = h.nodes
    nodemap = h.node_map
    i = length(nodemap) + 1
    nd_id = length(nodes) + 1
    push!(nodes, MutableBinaryHeapNode(convert(T, v), i))
    push!(nodemap, nd_id)
    _heap_bubble_up!(h.order, nodes, nodemap, nd_id)
    return i
end

function sizehint!(h::MutableBinaryHeap, s::Integer)
    sizehint!(h.nodes, s)
    sizehint!(h.node_map, s)
    return h
end

@inline top(h::MutableBinaryHeap) = h.nodes[1].value

"""
    top_with_handle(h::MutableBinaryHeap)

Returns the element at the top of the heap `h` and its handle.
"""
function top_with_handle(h::MutableBinaryHeap)
    el = h.nodes[1]
    return el.value, el.handle
end

pop!(h::MutableBinaryHeap{T}) where {T} = _binary_heap_pop!(h.order, h.nodes, h.node_map)

"""
    update!{T}(h::MutableBinaryHeap{T}, i::Int, v::T)

Replace the element at index `i` in heap `h` with `v`.
This is equivalent to `h[i]=v`.
"""
function update!(h::MutableBinaryHeap{T}, i::Int, v) where T
    nodes = h.nodes
    nodemap = h.node_map
    order = h.order

    nd_id = nodemap[i]
    v0 = nodes[nd_id].value
    x = convert(T, v)
    nodes[nd_id] = MutableBinaryHeapNode(x, i)
    if lt(order, x, v0)
        _heap_bubble_up!(order, nodes, nodemap, nd_id)
    else
        _heap_bubble_down!(order, nodes, nodemap, nd_id)
    end
end

"""
    delete!{T}(h::MutableBinaryHeap{T}, i::Int)

Deletes the element with handle `i` from heap `h` .
"""
function delete!(h::MutableBinaryHeap{T}, i::Int) where T
     nd_id = h.node_map[i]
    _binary_heap_pop!(h.order, h.nodes, h.node_map, nd_id)
    return h
end

setindex!(h::MutableBinaryHeap, v, i::Int) = update!(h, i, v)
getindex(h::MutableBinaryHeap, i::Int) = h.nodes[h.node_map[i]].value
