#A counter type

struct Accumulator{T, V<:Number} <: AbstractDict{T,V}
    map::Dict{T,V}
end

## constructors

Accumulator{T, V}() where {T,V<:Number} = Accumulator{T,V}(Dict{T,V}())

counter(T::Type) = Accumulator{T,Int}()
counter(dct::Dict{T,V}) where {T,V<:Integer} = Accumulator{T,V}(copy(dct))

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
function eltype_for_accumulator(seq::T) where {T<:Base.Generator}
    Base.@default_eltype(seq)
end


copy(ct::Accumulator) = Accumulator(copy(ct.map))

length(a::Accumulator) = length(a.map)

## retrieval

get(ct::Accumulator, x, default) = get(ct.map, x, default)
# need to allow user specified default in order to
# correctly implement "informal" AbstractDict interface

getindex(ct::Accumulator{T,V}, x) where {T,V} = get(ct.map, x, zero(V))

setindex!(ct::Accumulator, x, v) = setindex!(ct.map, x, v)


haskey(ct::Accumulator, x) = haskey(ct.map, x)

keys(ct::Accumulator) = keys(ct.map)

values(ct::Accumulator) = values(ct.map)

sum(ct::Accumulator) = sum(values(ct.map))

## iteration

iterate(ct::Accumulator, s...) = iterate(ct.map, s...)

# manipulation

"""
    inc!(ct, x, [v=1])

Increments the count for `x` by `v` (defaulting to one)
"""
inc!(ct::Accumulator, x, a::Number) = (ct[x] += a)
inc!(ct::Accumulator{T,V}, x) where {T,V} = inc!(ct, x, one(V))

# inc! is preferred over push!, but we need to provide push! for the Bag interpreation
# which is used by classified_collections.jl
push!(ct::Accumulator, x) = inc!(ct, x)
push!(ct::Accumulator, x, a::Number) = inc!(ct, x, a)

# To remove ambiguities related to Accumulator now being a subtype of AbstractDict
push!(ct::Accumulator, x::Pair)  = inc!(ct, x)



"""
    dec!(ct, x, [v=1])

Decrements the count for `x` by `v` (defaulting to one)
"""
dec!(ct::Accumulator, x, a::Number) = (ct[x] -= a)
dec!(ct::Accumulator{T,V}, x) where {T,V} = dec!(ct, x, one(V))

#TODO: once we are done deprecating `pop!` for `reset!` then add `pop!` as an alias for `dec!`

"""
    merge!(ct1, others...)

Merges the other counters into `ctl`,
summing the counts for all elements.
"""
function merge!(ct::Accumulator, other::Accumulator)
    for (x, v) in other
        inc!(ct, x, v)
    end
    ct
end


function merge!(ct1::Accumulator, others::Accumulator...)
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
function merge(ct1::Accumulator, others::Accumulator...)
    ct = copy(ct1)
    merge!(ct,others...)
end

"""
    reset!(ct::Accumulator, x)

Resets the count of `x` to zero.
Returns its former count.
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

struct MultiplicityException{K,V} <: Exception
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
    for k in union(keys(a), keys(b)) # union not interection as we want to check both multiplicties
        va = a[k]
        vb = b[k]
        va >= 0 || throw(MultiplicityException(k, va))
        vb >= 0 || throw(MultiplicityException(k, vb))

        a[k] = min(va, vb)
        drop_nonpositive!(a, k) # Drop any that ended up zero
    end
    return a
end
