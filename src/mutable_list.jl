mutable struct ListNode{T}
    data::T
    prev::ListNode{T}
    next::ListNode{T}
    function ListNode{T}() where T
        node = new{T}()
        node.next = node
        node.prev = node
        return node
    end
    function ListNode{T}(prev,data,next) where T
        node = new{T}(data)
        node.next = next
        node.prev = prev
        return node
    end
end

mutable struct MutableLinkedList{T}
    len::Int
    node::ListNode{T}
    function MutableLinkedList{T}() where T
        return new{T}(0, ListNode{T}())
    end
end

MutableLinkedList() = MutableLinkedList{Any}()

MutableLinkedList{T}(elts...) where {T} = append!(MutableLinkedList{T}(), elts)

Base.iterate(l::MutableLinkedList) = l.len == 0 ? nothing : (l.node.next.data, l.node.next.next)
Base.iterate(l::MutableLinkedList, n::ListNode) = n === l.node ? nothing : (n.data, n.next)

Base.isempty(l::MutableLinkedList) = l.len == 0
Base.length(l::MutableLinkedList) = l.len
Base.collect(l::MutableLinkedList{T}) where T = T[x for x in l]
Base.eltype(::Type{<:MutableLinkedList{T}}) where T = T
Base.lastindex(l::MutableLinkedList) = l.len

function Base.first(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List is empty"))
    return l.node.next.data
end

function Base.last(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List is empty"))
    return l.node.prev.data
end

Base.:(==)(l1::MutableLinkedList{T}, l2::MutableLinkedList{S}) where {T,S} = false

function Base.:(==)(l1::MutableLinkedList{T}, l2::MutableLinkedList{T}) where T
    length(l1) == length(l2) || return false
    for (i, j) in zip(l1, l2)
        i == j || return false
    end
    return true
end

function Base.map(f::Base.Callable, l::MutableLinkedList{T}) where T
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

function Base.filter(f::Function, l::MutableLinkedList{T}) where T
    l2 = MutableLinkedList{T}()
    for h in l
        if f(h)
            push!(l2, h)
        end
    end
    return l2
end

function Base.reverse(l::MutableLinkedList{T}) where T
    l2 = MutableLinkedList{T}()
    for h in l
        pushfirst!(l2, h)
    end
    return l2
end

Base.copy(l::MutableLinkedList{T}) where T = append!(MutableLinkedList{T}(), l)

function _traverse(l::MutableLinkedList, idx::Int)
    node = l.node
    for _ in 1:idx
        node = node.next
    end
    return node
end

function Base.getindex(l::MutableLinkedList, idx::Int)
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    return _traverse(l, idx).data
end

function Base.getindex(l::MutableLinkedList{T}, r::UnitRange) where T
    @boundscheck 0 < first(r) <= last(r) <= l.len || throw(BoundsError(l, r))
    l2 = MutableLinkedList{T}()
    node = _traverse(l, first(r))
    len = length(r)
    for _ in 1:len
        push!(l2, node.data)
        node = node.next
    end
    return l2
end

function Base.setindex!(l::MutableLinkedList{T}, data, idx::Int) where T
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    _traverse(l, idx).data = convert(T, data)
    return l
end

function Base.append!(l::MutableLinkedList, itr)
    for e in itr
        push!(l, e)
    end
    return l
end

Base.append!(l::MutableLinkedList, elts...) = append!(l, elts)

function Base.delete!(l::MutableLinkedList, idx::Int)
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = _traverse(l, idx)
    prev = node.prev
    next = node.next
    prev.next = next
    next.prev = prev
    l.len -= 1
    return l
end

function Base.delete!(l::MutableLinkedList, r::UnitRange)
    @boundscheck 0 < first(r) <= last(r) <= l.len || throw(BoundsError(l, r))
    node = _traverse(l, first(r))
    prev = node.prev
    len = length(r)
    for _ in 1:len
        node = node.next
    end
    next = node
    prev.next = next
    next.prev = prev
    l.len -= len
    return l
end

function Base.push!(l::MutableLinkedList{T}, data) where T
    oldlast = l.node.prev
    node = ListNode{T}(oldlast, data, l.node)
    l.node.prev = node
    oldlast.next = node
    l.len += 1
    return l
end

function Base.pushfirst!(l::MutableLinkedList{T}, data) where T
    oldfirst = l.node.next
    node = ListNode{T}(l.node, data, oldfirst)
    l.node.next = node
    oldfirst.prev = node
    l.len += 1
    return l
end

function Base.pop!(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List must be non-empty"))
    last = l.node.prev.prev
    data = l.node.prev.data
    last.next = l.node
    l.node.prev = last
    l.len -= 1
    return data
end

function Base.popfirst!(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List must be non-empty"))
    first = l.node.next.next
    data = l.node.next.data
    first.prev = l.node
    l.node.next = first
    l.len -= 1
    return data
end

function Base.show(io::IO, node::ListNode)
    print(io, typeof(node), "(", node.data, ")")
end

function Base.show(io::IO, l::MutableLinkedList)
    print(io, typeof(l), '(')
    join(io, l, ", ")
    print(io, ')')
end
