mutable struct ListNode{T}
    data::T
    prev::ListNode{T}
    next::ListNode{T}
    function ListNode{T}() where {T}
        node = new{T}()
        node.next = node.prev = node
        return node
    end
    function ListNode{T}(prev, data, next) where {T}
        node = new{T}(data, prev, next)
        prev.next = next.prev = node
        return node
    end
end

mutable struct MutableLinkedList{T}
    len::Int
    node::ListNode{T}
    function MutableLinkedList{T}() where {T}
        return new{T}(0, ListNode{T}())
    end
end

MutableLinkedList() = MutableLinkedList{Any}()
MutableLinkedList(elts...) = MutableLinkedList{eltype(elts)}(elts...)
MutableLinkedList{T}(elts...) where {T} = append!(MutableLinkedList{T}(), elts)

Base.iterate(l::MutableLinkedList) = l.len == 0 ? nothing : (l.node.next.data, l.node.next.next)
Base.iterate(l::MutableLinkedList, n::ListNode) = n === l.node ? nothing : (n.data, n.next)

Base.isempty(l::MutableLinkedList) = l.len == 0
Base.length(l::MutableLinkedList) = l.len
Base.collect(l::MutableLinkedList{T}) where {T} = T[x for x in l]
Base.eltype(::Type{<:MutableLinkedList{T}}) where {T} = T
Base.lastindex(l::MutableLinkedList) = l.len

_boundscheck(l, idx) = 0 < idx <= l.len || throw(BoundsError(l, idx))

# mend two nodes together
nconnect(a::ListNode{T}, b::ListNode{T}) where {T} = a.next, b.prev = b, a

# traverse to idx either from front or back, depending on whats faster
function ntraverse(l::MutableLinkedList, idx::Int)
    n = length(l)
    node = l.node
    if idx < n ÷ 2
        for _ in 1:idx
            node = node.next
        end
    else
        for _ in 1:(n-idx+1)
            node = node.prev
        end
    end
    return node
end

# remove node from the list, the node itself is unchanged
function nremove(l::MutableLinkedList, node::ListNode)
    nconnect(node.prev, node.next)
    l.len -= 1
    return node
end

# create a new node, insert it after the provided `node` and return it
function ninsert(l::MutableLinkedList{T}, node::ListNode{T}, data) where {T}
    ins = ListNode{T}(node, data, node.next)
    l.len += 1
    return ins
end

function Base.first(l::MutableLinkedList)
    _boundscheck(l, 1)
    return l.node.next.data
end

function Base.last(l::MutableLinkedList)
    _boundscheck(l, length(l))
    return l.node.prev.data
end

Base.:(==)(l1::MutableLinkedList{T}, l2::MutableLinkedList{S}) where {T,S} = false

function Base.:(==)(l1::MutableLinkedList{T}, l2::MutableLinkedList{T}) where {T}
    length(l1) == length(l2) || return false
    for (i, j) in zip(l1, l2)
        i == j || return false
    end
    return true
end

function Base.map(f::Base.Callable, l::MutableLinkedList{T}) where {T}
    if isempty(l) && f isa Function
        S = Core.Compiler.return_type(f, Tuple{T})
        return MutableLinkedList{S}()
    elseif isempty(l) && f isa Type
        return MutableLinkedList{f}()
    else
        S = typeof(f(first(l)))
        l2 = MutableLinkedList{S}()
        for h in l
            el = f(h)
            if el isa S
                push!(l2, el)
            else
                R = typejoin(S, typeof(el))
                l2 = MutableLinkedList{R}(collect(l2)...)
                push!(l2, el)
            end
        end
        return l2
    end
end

function Base.filter(f::Function, l::MutableLinkedList{T}) where {T}
    l2 = MutableLinkedList{T}()
    for h in l
        f(h) && push!(l2, h)
    end
    return l2
end

function Base.reverse(l::MutableLinkedList{T}) where {T}
    l2 = MutableLinkedList{T}()
    for h in l
        pushfirst!(l2, h)
    end
    return l2
end

function Base.filter!(f::Function, l::MutableLinkedList{T}) where {T}
    node = l.node.next
    for _ in 1:length(l)
        f(node.data) || nremove(l, node)
        node = node.next
    end
    return l
end

function Base.reverse!(l::MutableLinkedList)
    node = l.node
    for _ in 1:length(l)+1
        node.next, node.prev = node.prev, node.next
        node = node.prev
    end
    return l
end

Base.copy(l::MutableLinkedList{T}) where {T} = append!(MutableLinkedList{T}(), l)

function Base.getindex(l::MutableLinkedList, idx::Int)
    _boundscheck(l, idx)
    return ntraverse(l, idx).data
end

function Base.getindex(l::MutableLinkedList{T}, r::UnitRange) where {T}
    n = length(r)
    l2 = MutableLinkedList{T}()
    if n > 0
        @boundscheck 0 < first(r) <= last(r) <= l.len || throw(BoundsError(l, r))
        node = ntraverse(l, first(r))
        for _ in 1:n
            push!(l2, node.data)
            node = node.next
        end
    end
    return l2
end

function Base.setindex!(l::MutableLinkedList{T}, data, idx::Int) where {T}
    _boundscheck(l, idx)
    ntraverse(l, idx).data = convert(T, data)
    return l
end

function Base.append!(l::MutableLinkedList, collections...)
    node = l.node.prev
    for c in collections
        for e in c
            node = ninsert(l, node, e)
        end
    end
    return l
end

function Base.prepend!(l::MutableLinkedList, collections...)
    node = l.node
    for c in collections
        for e in c
            node = ninsert(l, node, e)
        end
    end
    return l
end

function Base.deleteat!(l::MutableLinkedList, idx::Int)
    _boundscheck(l, idx)
    nremove(l, ntraverse(l, idx))
    return l
end

function Base.deleteat!(l::MutableLinkedList, r::UnitRange)
    n = length(r)
    if n > 0
        0 < first(r) <= last(r) <= l.len || throw(BoundsError(l, r))
    end
    node = ntraverse(l, first(r))
    for _ in 1:n
        nremove(l, node)
        node = node.next
    end
    return l
end

function Base.push!(l::MutableLinkedList{T}, data) where {T}
    ninsert(l, l.node.prev, data)
    return l
end

function Base.pushfirst!(l::MutableLinkedList{T}, data) where {T}
    ninsert(l, l.node, data)
    return l
end

function Base.pop!(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List must be non-empty"))
    node = l.node.prev
    nremove(l, node)
    return node.data
end

function Base.popfirst!(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List must be non-empty"))
    node = l.node.next
    nremove(l, node)
    return node.data
end

function Base.popat!(l::MutableLinkedList, idx::Int)
    _boundscheck(l, idx)
    node = ntraverse(l, idx)
    nremove(l, node)
    return node.data
end

function Base.popat!(l::MutableLinkedList, idx::Int, default)
    return (0 < idx <= l.len) ? popat!(l, idx) : default
end

function Base.insert!(l::MutableLinkedList{T}, idx::Int, data) where {T}
    # special case length+1 for insert index to allow adding to the end 
    0 < idx <= l.len + 1 || throw(BoundsError(l, idx))
    ninsert(l, ntraverse(l, idx - 1), data)
    return l
end

function Base.splice!(l::MutableLinkedList{T}, idx::Int, ins=T[]) where {T}
    _boundscheck(l, idx)
    node = ntraverse(l, idx)
    data = node.data
    nremove(l, node)
    node = node.prev
    for e in ins
        node = ninsert(l, node, e)
    end
    return data
end

function Base.splice!(l::MutableLinkedList{T}, r::AbstractUnitRange{<:Integer}, ins=T[]) where {T}
    n = length(r)
    if n == 0 && !isempty(ins)
        0 < first(r) <= l.len + 1 || throw(BoundsError(l, r))
    elseif n == 1
        return splice!(l, first(r), ins)
    elseif n > 1
        0 < first(r) <= last(r) <= l.len || throw(BoundsError(l, r))
    end
    l2 = MutableLinkedList{T}()
    # determine nodes to splice
    splice_first_node = splice_last_node = ntraverse(l, first(r)) 
    for _ in 1:(n-1)
        splice_last_node = splice_last_node.next
    end
    # node to insert is ahead of the splice region
    insert_node = splice_first_node.prev  
    if n != 0
        # link the nodes surrounding the splice region
        nconnect(splice_first_node.prev, splice_last_node.next)  
        l.len -= n
        # rewire the spliced region to l2
        nconnect(l2.node, splice_first_node)  
        nconnect(splice_last_node, l2.node) 
        l2.len = n
    end
    for e in ins
        insert_node = ninsert(l, insert_node, e)
    end
    return l2
end

function Base.empty!(l::MutableLinkedList)
    l.node.next = l.node.prev = l.node
    l.len = 0
    return l
end

function Base.show(io::IO, node::ListNode)
    if get(io, :compact, false)
        print(io, node.data)
    else
        print(io, typeof(node), "(", node.data, ")")
    end
end

function Base.show(io::IO, l::MutableLinkedList)
    rows, _ = displaysize(io)
    n = length(l)
    println(io, n, "-element ", typeof(l), ":") # imitate vector
    rows -= 4
    if get(io, :limit, false) && n > rows
        fromstart = cld(rows, 2)
        for i in 1:fromstart
            show(io, l[i])
            print(io, '\n')
        end
        println(io, '⋮')
        fromend = n - fld(rows, 2) + 1
        for i in fromend:n
            show(io, l[i])
            i != n && print(io, '\n')
        end
    else
        for i in 1:n
            show(io, l[i])
            i != n && print(io, '\n')
        end
    end
end
