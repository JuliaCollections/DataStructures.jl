const INT_PER_PAGE = div(ccall(:jl_getpagesize, Clong, ()), sizeof(Int))
# we use this to mark pages not in use, it must never be written to.
const NULL_INT_PAGE = Vector{Int}()

mutable struct SparseIntSet
    packed ::Vector{Int}
    reverse::Vector{Vector{Int}}
    counters::Vector{Int}  # counts the number of real elements in each page of reverse.
end

SparseIntSet() = SparseIntSet(Int[], Vector{Int}[], Int[])

SparseIntSet(indices) = union!(SparseIntSet(), indices)

Base.eltype(::Type{SparseIntSet}) = Int

Base.empty(::SparseIntSet) = SparseIntSet()

function Base.empty!(s::SparseIntSet)
    empty!(s.packed)
    empty!(s.reverse)
    empty!(s.counters)
    return s
end

Base.isempty(s::SparseIntSet) = isempty(s.packed)

Base.copy(s::SparseIntSet) = copy!(SparseIntSet(), s)

function Base.copy!(to::SparseIntSet, from::SparseIntSet)
    to.packed = copy(from.packed)
    #we want to keep the null pages === NULL_INT_PAGE
    resize!(to.reverse, length(from.reverse))
    for i in eachindex(from.reverse)
        page = from.reverse[i]
        if page === NULL_INT_PAGE
            to.reverse[i] = NULL_INT_PAGE
        else
            to.reverse[i] = copy(from.reverse[i])
        end
    end
    to.counters = copy(from.counters)
    return to
end

function pageid_offset(s::SparseIntSet, i)
    pageid = div(i - 1, INT_PER_PAGE) + 1
    return pageid, (i - 1) & (INT_PER_PAGE - 1) + 1
end

function Base.in(i, s::SparseIntSet)
    pageid, offset = pageid_offset(s, i)
    if pageid > length(s.reverse)
        return false
    else
        page = @inbounds s.reverse[pageid]
        return page !== NULL_INT_PAGE &&  @inbounds page[offset] != 0
    end
end

Base.length(s::SparseIntSet) = length(s.packed)

@inline function Base.push!(s::SparseIntSet, i::Integer)
    i <= 0 && throw(DomainError("Only positive Ints allowed."))

    pageid, offset = pageid_offset(s, i)
    pages = s.reverse
    plen = length(pages)

    if pageid > plen
        # Create new null pages up to pageid and fresh (zero-filled) one at pageid
        sizehint!(pages, pageid)
        sizehint!(s.counters, pageid)
        for i in 1:pageid - plen - 1
            push!(pages, NULL_INT_PAGE)
            push!(s.counters, 0)
        end
        push!(pages, zeros(Int, INT_PER_PAGE))
        push!(s.counters, 0)
    elseif pages[pageid] === NULL_INT_PAGE
        #assign a page to previous null page
        pages[pageid] = zeros(Int, INT_PER_PAGE)
    end
    page = pages[pageid]
    if page[offset] == 0
        @inbounds page[offset] = length(s) + 1
        @inbounds s.counters[pageid] += 1
        push!(s.packed, i)
        return s
    end
    return s
end

@inline function Base.push!(s::SparseIntSet, is::Integer...)
    for i in is
        push!(s, i)
    end
    return s
end

@inline Base.@propagate_inbounds function Base.pop!(s::SparseIntSet)
    if isempty(s)
        throw(ArgumentError("Cannot pop an empty set."))
    end
    id = pop!(s.packed)
    pageid, offset = pageid_offset(s, id)
    @inbounds s.reverse[pageid][offset] = 0
    @inbounds s.counters[pageid] -= 1
    cleanup!(s, pageid)
    return id
end

@inline Base.@propagate_inbounds function Base.pop!(s::SparseIntSet, id::Integer)
    id < 0 && throw(ArgumentError("Int to pop needs to be positive."))

    @boundscheck if !in(id, s)
        throw(BoundsError(s, id))
    end
    @inbounds begin
        packed_endid = s.packed[end]
        from_page, from_offset = pageid_offset(s, id)
        to_page, to_offset = pageid_offset(s, packed_endid)

        packed_id = s.reverse[from_page][from_offset]
        s.packed[packed_id] = packed_endid
        s.reverse[to_page][to_offset] = s.reverse[from_page][from_offset]
        s.reverse[from_page][from_offset] = 0
        s.counters[from_page] -= 1
        pop!(s.packed)
    end
    cleanup!(s, from_page)
    return id
end

@inline function cleanup!(s::SparseIntSet, pageid::Int)
    if s.counters[pageid] == 0
        s.reverse[pageid] = NULL_INT_PAGE
    end
end

@inline function Base.pop!(s::SparseIntSet, id::Integer, default)
    id < 0 && throw(ArgumentError("Int to pop needs to be positive."))
    return in(id, s) ? (@inbounds pop!(s, id)) : default
end
Base.popfirst!(s::SparseIntSet) = pop!(s, first(s))

@inline Base.iterate(set::SparseIntSet, args...) = iterate(set.packed, args...)

Base.last(s::SparseIntSet) = isempty(s) ? throw(ArgumentError("Empty set has no last element.")) : last(s.packed)

Base.union(s::SparseIntSet, ns) = union!(copy(s), ns)
function Base.union!(s::SparseIntSet, ns)
    for n in ns
        push!(s, n)
    end
    return s
end

Base.intersect(s1::SparseIntSet) = copy(s1)
Base.intersect(s1::SparseIntSet, ss...) = intersect(s1, intersect(ss...))
function Base.intersect(s1::SparseIntSet, ns)
    s = SparseIntSet()
    for n in ns
        n in s1 && push!(s, n)
    end
    return s
end

Base.intersect!(s1::SparseIntSet, ss...) = intersect!(s1, intersect(ss...))

#Is there a more performant way to do this?
Base.intersect!(s1::SparseIntSet, ns) = copy!(s1, intersect(s1, ns))

Base.setdiff(s::SparseIntSet, ns) = setdiff!(copy(s), ns)
function Base.setdiff!(s::SparseIntSet, ns)
    for n in ns
        pop!(s, n, nothing)
    end
    return s
end

function Base.:(==)(s1::SparseIntSet, s2::SparseIntSet)
    length(s1) != length(s2) && return false
    return all(in(s1), s2)
end

Base.issubset(a::SparseIntSet, b::SparseIntSet) = isequal(a, intersect(a, b))

Base.:(<)(a::SparseIntSet, b::SparseIntSet) = ( a<=b ) && !isequal(a, b)
Base.:(<=)(a::SparseIntSet, b::SparseIntSet) = issubset(a, b)

function findfirst_packed_id(i, s::SparseIntSet)
    pageid, offset = pageid_offset(s, i)
    if pageid > length(s.counters) || s.counters[pageid] == 0
        return 0
    end
    @inbounds id = s.reverse[pageid][offset]
    return id
end

Base.collect(s::SparseIntSet) = copy(s.packed)

struct ZippedSparseIntSetIterator{VT,IT}
    valid_sets::VT
    shortest_set::SparseIntSet
    excluded_sets::IT
    function ZippedSparseIntSetIterator(valid_sets::SparseIntSet...; exclude::NTuple{N, SparseIntSet}=()) where{N}
        shortest = valid_sets[findmin(map(length, valid_sets))[2]]
        new{typeof(valid_sets), NTuple{N, SparseIntSet}}(valid_sets, shortest, exclude)
    end
end

function Base.zip(s0::SparseIntSet, s::SparseIntSet...; kwargs...)
    return ZippedSparseIntSetIterator(s0, s...; kwargs...)
end

Base.length(it::ZippedSparseIntSetIterator) = length(it.shortest_set)

# we know it is not in_excluded, as there are no excluded
@inline in_excluded(id, it::ZippedSparseIntSetIterator{VT,Tuple{}}) where {VT} = false

@inline function in_excluded(id, it)
    for e in it.excluded_sets
        if id in e
            return true
        end
    end
    return false
end

@inline function in_valid(id, it)
    for e in it.valid_sets
        if !in(id, e)
            return false
        end
    end
    return true
end

@inline function Base.iterate(it::ZippedSparseIntSetIterator, state=1)
    iterator_length = length(it)
    if state > iterator_length
        return nothing
    end
    for i in state:iterator_length
        @inbounds id = it.shortest_set.packed[i]
        if in_valid(id, it) && !in_excluded(id, it)
            return map(x->findfirst_packed_id(id, x), it.valid_sets), i + 1
        end
    end
    return nothing
end
