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
    function ListNode{T}(data) where T
        node = new{T}(data)
        return node
    end
end

mutable struct MutableLinkedList{T}
    len::Int
    node::ListNode{T}
    function MutableLinkedList{T}() where T
        l = new{T}()
        l.len = 0
        l.node = ListNode{T}()
        l.node.next = l.node
        l.node.prev = l.node
        return l
    end
end

MutableLinkedList() = MutableLinkedList{Any}()

function MutableLinkedList{T}(elts...) where T
    l = MutableLinkedList{T}()
    for elt in elts
        push!(l, elt)
    end
    return l
end

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

function Base.copy(l::MutableLinkedList{T}) where T
    l2 = MutableLinkedList{T}()
    for h in l
        push!(l2, h)
    end
    return l2
end

function Base.getindex(l::MutableLinkedList, idx::Int)
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = l.node
    for i in 1:idx
        node = node.next
    end
    return node.data
end

function Base.getindex(l::MutableLinkedList{T}, r::UnitRange) where T
    @boundscheck 0 < first(r) < last(r) <= l.len || throw(BoundsError(l, r))
    l2 = MutableLinkedList{T}()
    node = l.node
    for i in 1:first(r)
        node = node.next
    end
    len = length(r)
    for j in 1:len
        push!(l2, node.data)
        node = node.next
    end
    l2.len = len
    return l2
end

function Base.setindex!(l::MutableLinkedList{T}, data, idx::Int) where T
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = l.node
    for i in 1:idx
        node = node.next
    end
    node.data = convert(T, data)
    return l
end

function Base.append!(l1::MutableLinkedList{T}, l2::MutableLinkedList{T}) where T
    l1.node.prev.next = l2.node.next
    l2.node.next.prev = l1.node.prev
    l1.len += length(l2)
    return l1
end

function Base.append!(l::MutableLinkedList, elts...)
    for elt in elts
        push!(l, elt)
    end
    return l
end

function Base.delete!(l::MutableLinkedList, idx::Int)
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = l.node
    for i = 1:idx
        node = node.next
    end
    prev = node.prev
    next = node.next
    prev.next = next
    next.prev = prev
    l.len -= 1
    return l
end

function Base.delete!(l::MutableLinkedList, r::UnitRange)
    @boundscheck 0 < first(r) < last(r) <= l.len || throw(BoundsError(l, r))
    node = l.node
    for i in 1:first(r)
        node = node.next
    end
    prev = node.prev
    len = length(r)
    for j in 1:len
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
    node = ListNode{T}(data)
    node.next = l.node
    node.prev = oldlast
    l.node.prev = node
    oldlast.next = node
    l.len += 1
    return l
end

function Base.pushfirst!(l::MutableLinkedList{T}, data) where T
    oldfirst = l.node.next
    node = ListNode{T}(data)
    node.prev = l.node
    node.next = oldfirst
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
    x = node.data
    print(io, "$(typeof(node))($x)")
end

function Base.show(io::IO, l::MutableLinkedList)
    print(io, typeof(l), '(')
    join(io, l, ", ")
    print(io, ')')
end
