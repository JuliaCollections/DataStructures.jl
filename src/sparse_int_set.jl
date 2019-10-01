import Base: @propagate_inbounds, zip

const INT_PER_PAGE = div(ccall(:jl_getpagesize, Clong, ()), sizeof(Int))
const NULL_INT_PAGE = Vector{Int}()

#TODO: Batch creation and allocation
mutable struct SparseIntSet
    packed ::Vector{Int}
    reverse::Vector{Vector{Int}}
    counters::Vector{Int}  # counts the number of real elements in each page of reverse. 
end

SparseIntSet() = SparseIntSet(Int[], Vector{Int}[], Int[])

SparseIntSet(indices) = union!(SparseIntSet(), indices)

eltype(::Type{SparseIntSet}) = Int

empty(::SparseIntSet) = SparseIntSet()

function empty!(s::SparseIntSet)
    empty!(s.packed)
    empty!(s.reverse)
    empty!(s.counters)
    return s
end

isempty(s::SparseIntSet) = isempty(s.packed)

copy(s::SparseIntSet) = copy!(SparseIntSet(), s)

function copy!(to::SparseIntSet, from::SparseIntSet)
    to.packed = copy(from.packed)
    to.reverse = deepcopy(from.reverse)
    to.counters = copy(from.counters)
    return to
end

function pageid_offset(s::SparseIntSet, i)
    pageid = div(i - 1, INT_PER_PAGE) + 1
    return pageid, (i - 1) & (INT_PER_PAGE - 1) + 1
end

function in(i, s::SparseIntSet)
    pageid, offset = pageid_offset(s, i)
    isassigned(s.reverse, pageid) && @inbounds s.reverse[pageid][offset] != 0
end

length(s::SparseIntSet) = length(s.packed)

function push!(s::SparseIntSet, i::Integer)
    i <= 0 && throw(DomainError("Only positive Ints allowed."))

    pageid, offset = pageid_offset(s, i)
    pages = s.reverse
    plen = length(pages)

    if pageid > plen
        #create new null pages up to pageid and a virgin one at pageid
        sizehint!(pages, pageid)
        sizehint!(s.counters, pageid)
        for i = 1:pageid - plen - 1
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

push!(s::SparseIntSet, is::Integer...) = (for i in is; push!(s, i); end; return s)

@propagate_inbounds function pop!(s::SparseIntSet)
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

@propagate_inbounds function pop!(s::SparseIntSet, id::Integer)
    id < 0 && throw(ArgumentError("Int to pop needs to be positive."))

    @boundscheck if !in(id, s)
        throw(BoundsError(s, id))
    end
    @inbounds begin
        packed_endid           = s.packed[end] 
        from_page, from_offset = pageid_offset(s, id)
        to_page, to_offset     = pageid_offset(s, packed_endid)

        packed_id                         = s.reverse[from_page][from_offset]
        s.packed[packed_id]               = packed_endid
        s.reverse[to_page][to_offset]     = s.reverse[from_page][from_offset]
        s.reverse[from_page][from_offset] = 0
        s.counters[from_page] -= 1
        pop!(s.packed)
    end
    cleanup!(s, from_page)
    return id
end

function cleanup!(s::SparseIntSet, pageid::Int)
    if s.counters[pageid] == 0
        s.reverse[pageid] = NULL_INT_PAGE
    end
end

function pop!(s::SparseIntSet, id::Integer, default)
    id < 0 && throw(ArgumentError("Int to pop needs to be positive."))
    return in(id, s) ? (@inbounds pop!(s, id)) : default
end
popfirst!(s::SparseIntSet) = pop!(s, first(s))

iterate(set::SparseIntSet, args...) = iterate(set.packed, args...) 

last(s::SparseIntSet) = isempty(s) ? throw(ArgumentError("Empty set has no last element.")) : last(s.packed)

union(s::SparseIntSet, ns) = union!(copy(s), ns)
function union!(s::SparseIntSet, ns)
    for n in ns
        push!(s, n)
    end
    return s
end

intersect(s1::SparseIntSet) = copy(s1)
intersect(s1::SparseIntSet, ss...) = intersect(s1, intersect(ss...))
function intersect(s1::SparseIntSet, ns)
    s = SparseIntSet()
    for n in ns
        n in s1 && push!(s, n)
    end
    return s
end

intersect!(s1::SparseIntSet, ss...) = intersect!(s1, intersect(ss...))

#Is there a more performant way to do this?
intersect!(s1::SparseIntSet, ns) = copy!(s1, intersect(s1, ns))

setdiff(s::SparseIntSet, ns) = setdiff!(copy(s), ns)
function setdiff!(s::SparseIntSet, ns)
    for n in ns
        pop!(s, n, nothing)
    end
    return s
end

function ==(s1::SparseIntSet, s2::SparseIntSet)
    length(s1) != length(s2) && return false
    return all(in(s1), s2)
end

issubset(a::SparseIntSet, b::SparseIntSet) = isequal(a, intersect(a, b))

complement(a::SparseIntSet) = complement!(SparseIntSet(), a)
function complement!(b::SparseIntSet, a::SparseIntSet)
    empty!(b)
    for i in eachindex(a.reverse)
        if a.reverse[i] === NULL_INT_PAGE
            new_ids = ((i - 1) * INT_PER_PAGE + 1) : (i * INT_PER_PAGE)
            append!(b.packed, new_ids)
            if i > length(b.reverse)
                push!(b.reverse, collect(new_ids)) 
                push!(b.counters, INT_PER_PAGE)
            else
                b.reverse[i] = collect(new_ids)
                b.counters[i] = INT_PER_PAGE
            end
        else
            for offset in 1:INT_PER_PAGE
                if a.reverse[i][offset] == 0
                    push!(b, INT_PER_PAGE*(i-1) + offset)
                end
            end
        end
    end
    return b
end
#Can this be optimized?
complement!(a::SparseIntSet) = copy!(a, complement(a))

<(a::SparseIntSet, b::SparseIntSet) = ( a<=b ) && !isequal(a, b)
<=(a::SparseIntSet, b::SparseIntSet) = issubset(a, b)

function findfirst_packed_id(i, s::SparseIntSet)
    pageid, offset = pageid_offset(s, i)
    if isassigned(s.reverse, pageid)
        @inbounds id = s.reverse[pageid][offset]
        return id
    end
    return 0
end

function cleanup!(s::SparseIntSet)
    last_page_id = findlast(!iszero, s.counters)
    if last_page_id === nothing
        return empty!(s)
    elseif any(iszero, s.counters)
        # shrink anything off the end
        resize!(s.counters, last_page_id)
        resize!(s.reverse, last_page_id)

        # Now we need to undef any page in `reverse` that is empty.
        # so we are allocating new pages, and then will copy it across.
        # since can't assign `undef` directly.
        new_pages = Vector{Vector{Int}}(undef, last_page_id)
        for i in eachindex(s.reverse)
            isused =  s.counters[i] !== 0 && isassigned(s.reverse, i)
            if isused
                new_pages[i] = s.reverse[i]
            end
        end
        s.reverse .= new_pages
        return s
    end
end


collect(s::SparseIntSet) = s.packed

mutable struct ZippedSparseIntSetIterator{VT,IT}
    current_id::Int
    valid_sets::VT
    shortest_set::SparseIntSet
    excluded_sets::IT
    function ZippedSparseIntSetIterator(valid_sets::SparseIntSet...;exclude::NTuple{N, SparseIntSet}=()) where{N}
        shortest = valid_sets[findmin(map(x->length(x), valid_sets))[2]]
        new{typeof(valid_sets), typeof(exclude)}(zero(eltype(shortest)), valid_sets, shortest, exclude)
    end
end

zip(s::SparseIntSet...;kwargs...) = ZippedSparseIntSetIterator(s...;kwargs...)

@inline length(it::ZippedSparseIntSetIterator) = length(it.shortest_set)

# we know it is not in_excluded, as there are no excluded
in_excluded(id, it::ZippedSparseIntSetIterator{VT,Tuple{}}) where {VT} = false

function in_excluded(id, it)
    for e in it.excluded_sets
        if id in e
            return true
        end
    end
    return false
end

@inline function id_tids(it, state)
    id = it.shortest_set.packed[state]
    return id, map(x -> findfirst_packed_id(id, x), it.valid_sets)
end

@propagate_inbounds function iterate(it::ZippedSparseIntSetIterator, state=1)
    if state > length(it)
        return nothing
    end
    id, tids = id_tids(it, state)
    while any(iszero, tids) || in_excluded(id, it)
        state += 1
        if state > length(it)
            return nothing
        end

        id, tids = id_tids(it, state)
    end
    it.current_id = id
    return tids, state + 1
end
