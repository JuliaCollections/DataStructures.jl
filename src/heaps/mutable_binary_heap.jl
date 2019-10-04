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

function _heap_bubble_up!(comp::Comp,
    nodes::Vector{MutableBinaryHeapNode{T}}, nodemap::Vector{Int}, nd_id::Int) where {Comp, T}

    @inbounds nd = nodes[nd_id]
    v::T = nd.value

    swapped = true  # whether swap happens at last step
    i = nd_id

    while swapped && i > 1  # nd is not root
        p = i >> 1
        @inbounds nd_p = nodes[p]

        if compare(comp, v, nd_p.value)
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

function _heap_bubble_down!(comp::Comp,
    nodes::Vector{MutableBinaryHeapNode{T}}, nodemap::Vector{Int}, nd_id::Int) where {Comp, T}

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

            if compare(comp, nd_r.value, nd_l.value)
                # consider right child
                if compare(comp, nd_r.value, v)
                    @inbounds nodes[i] = nd_r
                    @inbounds nodemap[nd_r.handle] = i
                    i = ir
                else
                    swapped = false
                end
            else
                # consider left child
                if compare(comp, nd_l.value, v)
                    @inbounds nodes[i] = nd_l
                    @inbounds nodemap[nd_l.handle] = i
                    i = il
                else
                    swapped = false
                end
            end

        else  # contains only left child
            nd_l = nodes[il]
            if compare(comp, nd_l.value, v)
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

function _binary_heap_pop!(comp::Comp,
    nodes::Vector{MutableBinaryHeapNode{T}}, nodemap::Vector{Int}, nd_id::Int=1) where {Comp,T}

    # extract node
    rt = nodes[nd_id]
    v = rt.value
    @inbounds nodemap[rt.handle] = 0

    if length(nodes) == 1
        # clear
        empty!(nodes)
    else
        # move the last node to the position of the removed node
        @inbounds nodes[nd_id] = new_rt = pop!(nodes)
        @inbounds nodemap[new_rt.handle] = nd_id

        if length(nodes) > 1
            if compare(comp, new_rt.value, v)
                _heap_bubble_up!(comp, nodes, nodemap, nd_id)
            else
                _heap_bubble_down!(comp, nodes, nodemap, nd_id)
            end
        end
    end
    v
end

function _make_mutable_binary_heap(comp::Comp, ty::Type{T}, values) where {Comp,T}
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
        _heap_bubble_up!(comp, nodes, nodemap, i)
    end
    return nodes, nodemap
end


#################################################
#
#   Binary Heap type and constructors
#
#################################################

mutable struct MutableBinaryHeap{VT, Comp} <: AbstractMutableHeap{VT,Int}
    comparer::Comp
    nodes::Vector{MutableBinaryHeapNode{VT}}
    node_map::Vector{Int}

    function MutableBinaryHeap{VT, Comp}() where {VT, Comp}
        nodes = Vector{MutableBinaryHeapNode{VT}}()
        node_map = Vector{Int}()
        new{VT, Comp}(Comp(), nodes, node_map)
    end

    function MutableBinaryHeap{VT, Comp}(xs::AbstractVector{VT}) where {VT, Comp}
        nodes, node_map = _make_mutable_binary_heap(Comp(), VT, xs)
        new{VT, Comp}(Comp(), nodes, node_map)
    end
end

const MutableBinaryMinHeap{T} = MutableBinaryHeap{T, LessThan}
const MutableBinaryMaxHeap{T} = MutableBinaryHeap{T, GreaterThan}

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
    _heap_bubble_up!(h.comparer, nodes, nodemap, nd_id)
    i
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

pop!(h::MutableBinaryHeap{T}) where {T} = _binary_heap_pop!(h.comparer, h.nodes, h.node_map)

"""
    update!{T}(h::MutableBinaryHeap{T}, i::Int, v::T)

Replace the element at index `i` in heap `h` with `v`.
This is equivalent to `h[i]=v`.
"""
function update!(h::MutableBinaryHeap{T}, i::Int, v) where T
    nodes = h.nodes
    nodemap = h.node_map
    comp = h.comparer

    nd_id = nodemap[i]
    v0 = nodes[nd_id].value
    x = convert(T, v)
    nodes[nd_id] = MutableBinaryHeapNode(x, i)
    if compare(comp, x, v0)
        _heap_bubble_up!(comp, nodes, nodemap, nd_id)
    else
        _heap_bubble_down!(comp, nodes, nodemap, nd_id)
    end
end

"""
    delete!{T}(h::MutableBinaryHeap{T}, i::Int)

Deletes the element with handle `i` from heap `h` .
"""
function delete!(h::MutableBinaryHeap{T}, i::Int) where T
     nd_id = h.node_map[i]
    _binary_heap_pop!(h.comparer, h.nodes, h.node_map, nd_id)
    h
end

setindex!(h::MutableBinaryHeap, v, i::Int) = update!(h, i, v)
getindex(h::MutableBinaryHeap, i::Int) = h.nodes[h.node_map[i]].value
