mutable struct ListNode{T}
    data::T
    prev::ListNode{T}
    next::ListNode{T}
    function ListNode{T}() where T
        node = new{T}()
        node.prev = node
        node.next = node
        return node
    end
    function ListNode{T}(data) where T
        node = new{T}(data)
        return node
    end
end

mutable struct MutableLinkedList{T}
    len::Int
    front::ListNode{T}
    back::ListNode{T}
    function MutableLinkedList{T}() where T
        l = new{T}()
        l.len = 0
        l.front = ListNode{T}()
        l.back = ListNode{T}()
        l.front.next = l.back
        l.back.prev = l.front
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

iterate(l::MutableLinkedList) = begin
    l.len == 0 ? nothing : (l.front.next.data, l.front.next.next)
end
iterate(l::MutableLinkedList, n::ListNode) = begin
    n.next == n ? nothing : (n.data, n.next)
end

isempty(l::MutableLinkedList) = l.len == 0
length(l::MutableLinkedList) = l.len
collect(l::MutableLinkedList{T}) where T = T[x for x in l]
eltype(l::MutableLinkedList{T}) where T = T
function first(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List is empty"))
    return l.front.next.data
end
function last(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List is empty"))
    return l.back.prev.data
end

==(l1::MutableLinkedList{T}, l2::MutableLinkedList{S}) where {T,S} = false

function ==(l1::MutableLinkedList{T}, l2::MutableLinkedList{T}) where T
    length(l1) == length(l2) || return false
    for (i, j) in zip(l1, l2)
        i == j || return false
    end
    return true
end

function map(f::Base.Callable, l::MutableLinkedList{T}) where T
    if isempty(l) && f isa Function
        S = Core.Compiler.return_type(f, (T,))
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

function filter(f::Function, l::MutableLinkedList{T}) where T
    l2 = MutableLinkedList{T}()
    for h in l
        if f(h)
            push!(l2, h)
        end
    end
    return l2
end

function reverse(l::MutableLinkedList{T}) where T
    l2 = MutableLinkedList{T}()
    for h in l
        pushfirst!(l2, h)
    end
    return l2
end

function copy(l::MutableLinkedList{T}) where T
    l2 = MutableLinkedList{T}()
    for h in l
        push!(l2, h)
    end
    return l2
end

function getindex(l::MutableLinkedList, idx::Int)
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = l.front
    for i = 1:idx
        node = node.next
    end
    return node.data
end

function setindex!(l::MutableLinkedList{T}, data, idx::Int) where T
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = l.front
    for i = 1:idx
        node = node.next
    end
    node.data = convert(T, data)
    return l
end

function append!(l1::MutableLinkedList{T}, l2::MutableLinkedList{T}) where T
    l1.back.prev.next = l2.front.next
    l2.front.next.prev = l1.back.prev
    l1.len += length(l2)
    return l1
end

function append!(l::MutableLinkedList, elts...)
    for elt in elts
        push!(l, elt)
    end
    l.len += length(elts)
    return l
end

function delete!(l::MutableLinkedList, idx::Int)
    @boundscheck 0 < idx <= l.len || throw(BoundsError(l, idx))
    node = l.front
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

function delete!(l::MutableLinkedList, r::UnitRange)
    @boundscheck 0 < first(r) < last(r) <= l.len || throw(BoundsError(l, r))
    node = l.front
    for i = 1:first(r)
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

function push!(l::MutableLinkedList{T}, data) where T
    last = l.back.prev
    node = ListNode{T}(data)
    node.next = l.back
    node.prev = last
    l.back.prev = node
    last.next = node
    l.len += 1
    return l
end

function pushfirst!(l::MutableLinkedList{T}, data) where T
    first = l.front.next
    node = ListNode{T}(data)
    node.prev = l.front
    node.next = first
    l.front.next = node
    first.prev = node
    l.len += 1
    return l
end

function pop!(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List must be non-empty"))
    last = l.back.prev.prev
    data = l.back.prev.data
    last.next = l.back
    l.back.prev = last
    l.len -= 1
    return data
end

function popfirst!(l::MutableLinkedList)
    isempty(l) && throw(ArgumentError("List must be non-empty"))
    first = l.front.next.next
    data = l.front.next.data
    first.prev = l.front
    l.front.next = first
    l.len -= 1
    return data
end

function show(io::IO, node::ListNode)
    x = node.data
    print(io, "$(typeof(node))($x)")
end

function show(io::IO, l::MutableLinkedList)
    print(io, typeof(l), '(')
    join(io, l, ", ")
    print(io, ')')
end
