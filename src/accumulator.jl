#A counter type

"""
    Accumulator{T, V<:Number}

A accumulator is a data structure that maintains an accumulated total for each key.
The particular case where those totals are integers is a counter.
"""
struct Accumulator{T, V <: Number} <: AbstractDict{T, V}
    map::Dict{T, V}
end

## constructors

Accumulator{T, V}() where {T, V <: Number} = Accumulator{T, V}(Dict{T, V}())
Accumulator(map::AbstractDict) = Accumulator(Dict(map))
Accumulator(ps::Pair...) = Accumulator(Dict(ps))

counter(T::Type) = Accumulator{T, Int}()
counter(dct::AbstractDict{T, V}) where {T, V<:Integer} = Accumulator{T, V}(Dict(dct))

"""
    counter(seq)

Returns an `Accumulator` object containing the elements from `seq`.
"""
function counter(seq)
    ct = counter(eltype_for_accumulator(seq))
    for x in seq
        inc!(ct, x)
    end
    return ct
end

eltype_for_accumulator(seq::T) where T = eltype(T)
function eltype_for_accumulator(seq::Base.Generator)
    Base.@default_eltype(seq)
end


Base.copy(ct::Accumulator) = Accumulator(copy(ct.map))

Base.length(a::Accumulator) = length(a.map)

## retrieval

Base.get(ct::Accumulator, x, default) = get(ct.map, x, default)
# need to allow user specified default in order to
# correctly implement "informal" AbstractDict interface

Base.getindex(ct::Accumulator{T,V}, x) where {T,V} = get(ct.map, x, zero(V))

Base.setindex!(ct::Accumulator, x, v) = setindex!(ct.map, x, v)


Base.haskey(ct::Accumulator, x) = haskey(ct.map, x)

Base.values(ct::Accumulator) = values(ct.map)

Base.sum(ct::Accumulator) = sum(values(ct.map))

## iteration

Base.iterate(ct::Accumulator, s...) = iterate(ct.map, s...)

# manipulation

"""
    inc!(ct::Accumulator, x, [v=1])

Increments the count for `x` by `v` (defaulting to one)
"""
inc!(ct::Accumulator, x, v::Number) = (ct[x] += v)
inc!(ct::Accumulator{T, V}, x) where {T, V} = inc!(ct, x, one(V))

# inc! is preferred over push!, but we need to provide push! for the Bag interpreation
# which is used by classified_collections.jl
Base.push!(ct::Accumulator, x) = inc!(ct, x)
Base.push!(ct::Accumulator, x, a::Number) = inc!(ct, x, a)

# To remove ambiguities related to Accumulator now being a subtype of AbstractDict
Base.push!(ct::Accumulator, x::Pair)  = inc!(ct, x)


"""
    dec!(ct::Accumulator, x, [v=1])

Decrements the count for `x` by `v` (defaulting to one)
"""
dec!(ct::Accumulator, x, v::Number) = (ct[x] -= v)
dec!(ct::Accumulator{T,V}, x) where {T,V} = dec!(ct, x, one(V))

#TODO: once we are done deprecating `pop!` for `reset!` then add `pop!` as an alias for `dec!`

"""
    merge!(ct1::Accumulator, others...)

Merges the other counters into `ctl`,
summing the counts for all elements.
"""
function Base.merge!(ct::Accumulator, other::Accumulator)
    for (x, v) in other
        inc!(ct, x, v)
    end
    return ct
end


function Base.merge!(ct1::Accumulator, others::Accumulator...)
    for ct in others
        merge!(ct1,ct)
    end
    return ct1
end


"""
     merge(counters...)

Creates a new counter with total counts equal to the sum of the counts in the counters given as arguments.

See also merge!
"""
function Base.merge(ct1::Accumulator, others::Accumulator...)
    ct = copy(ct1)
    merge!(ct,others...)
end

"""
    reset!(ct::Accumulator, x)

Remove a key `x` from an accumulator, and return its current value
"""
reset!(ct::Accumulator{<:Any,V}, x) where V = haskey(ct.map, x) ? pop!(ct.map, x) : zero(V)

"""
     nlargest(acc::Accumulator, [n])

Returns a sorted vector of the `n` most common elements, with their counts.
If `n` is omitted, the full sorted collection is returned.

This corresponds to Python's `Counter.most_common` function.

Example
```
julia> nlargest(counter("abbbccddddda"))

4-element Array{Pair{Char,Int64},1}:
 'd'=>5
 'b'=>3
 'c'=>2
 'a'=>2


julia> nlargest(counter("abbbccddddda"),2)

2-element Array{Pair{Char,Int64},1}:
 'd'=>5
 'b'=>3

```
"""
nlargest(acc::Accumulator) = sort!(collect(acc), by=last, rev=true)
nlargest(acc::Accumulator, n) = partialsort!(collect(acc), 1:n, by=last, rev=true)


"""
     nsmallest(acc::Accumulator, [n])

Returns a sorted vector of the `n` least common elements, with their counts.
If `n` is omitted, the full sorted collection is returned.

This is the opposite of the `nlargest` function.
For obvious reasons this will not include zero counts for items not encountered.
(unless those elements are added to he accumulator directly, eg via `acc[foo]=0)
"""
nsmallest(acc::Accumulator) = sort!(collect(acc), by=last, rev=false)
nsmallest(acc::Accumulator, n) = partialsort!(collect(acc), 1:n, by=last, rev=false)


###########################################################
## Multiset operations

struct MultiplicityException{K, V} <: Exception
    k::K
    v::V
end

function Base.showerror(io::IO, err::MultiplicityException)
    print(io, "When using an `Accumulator` as a multiset, all elements must have positive multiplicity")
    print(io, " element `$(err.k)` has multiplicity $(err.v)")
end

drop_nonpositive!(a::Accumulator, k) = (a[k] > 0 || delete!(a.map, k))


function Base.setdiff(a::Accumulator, b::Accumulator)
    ret = copy(a)
    for (k, v) in b
        v > 0 || throw(MultiplicityException(k, v))
        dec!(ret, k, v)
        drop_nonpositive!(ret, k)
    end
    return ret
end

Base.issubset(a::Accumulator, b::Accumulator) = all(b[k] >= v for (k, v) in a)

Base.union(a::Accumulator, b::Accumulator, c::Accumulator...) = union(union(a,b), c...)
Base.union(a::Accumulator, b::Accumulator) = union!(copy(a), b)
function Base.union!(a::Accumulator, b::Accumulator)
    for (kb, vb) in b
        va = a[kb]
        vb >= 0 || throw(MultiplicityException(kb, vb))
        va >= 0 || throw(MultiplicityException(kb, va))
        a[kb] = max(va, vb)
    end
    return a
end


Base.intersect(a::Accumulator, b::Accumulator, c::Accumulator...) = insersect(intersect(a,b), c...)
Base.intersect(a::Accumulator, b::Accumulator) = intersect!(copy(a), b)
function Base.intersect!(a::Accumulator, b::Accumulator)
    for k in union(keys(a), keys(b)) # union not interection as we want to check both multiplicities
        va = a[k]
        vb = b[k]
        va >= 0 || throw(MultiplicityException(k, va))
        vb >= 0 || throw(MultiplicityException(k, vb))

        a[k] = min(va, vb)
        drop_nonpositive!(a, k) # Drop any that ended up zero
    end
    return a
end
function Base.show(io::IO, acc::Accumulator{T,V}) where {T,V}
    l = length(acc)
    if l>0
        print(io, "Accumulator(")
    else
        print(io,"Accumulator{$T,$V}(")
    end
    for (count, (k, v)) in enumerate(acc)
        print(io, k, " => ", v)
        if count < l
            print(io, ", ")
        end
    end
    print(io, ")")
end
