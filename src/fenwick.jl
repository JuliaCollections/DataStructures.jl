"""
    FenwickTree{T}(n)
    
Constructs a [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree) of length `n`.
 
"""
mutable struct FenwickTree{T}
    bi_tree::Vector{T} #bi_tree is shorthand for Binary Indexed Tree, an alternative name for Fenwick Tree
    n::Integer
end

FenwickTree{T}() where T = FenwickTree{T}(0)
FenwickTree{T}(n::Integer) where T = FenwickTree{T}(zeros(T, n), n)

"""
    FenwickTree(arr::AbstractArray) 
    
Constructs a [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree) from `arr`.
 
"""
function FenwickTree(a::AbstractVector{U}) where U
    n = size(a)[1]
    tree = FenwickTree{U}(n)
    @inbounds for i = 1:n
        inc!(tree, i, a[i])
    end
    tree
end

length(ft::FenwickTree{T}) where T = ft.n

"""
    inc!(ft::FenwickTree{T}, ind, val)

Increases the value of the [`FenwickTree`] by `val` from the index `ind` upto the length of the Fenwick Tree.

""" 
function inc!(ft::FenwickTree{T}, ind::Int, val) where T
    val0 = convert(T, val)
    i = ind
    n = ft.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @inbounds while i <= n
        ft.bi_tree[i] += val0
        i += i&(-i)
    end
end

"""
    dec!(ft::FenwickTree{T}, ind, val)

Decreases the value of the [`FenwickTree`] by `val` from the index `ind` upto the length of the Fenwick Tree.

""" 
dec!(ft::FenwickTree{T}, ind::Int, val) where T = inc!(ft, ind, -val)

"""
    inc!(ft::FenwickTree{T}, range::AbstractUnitRange, val)

Increases the value of the [`FenwickTree`] by `val` from the indices in `range`.

"""    
function inc!(ft::FenwickTree{T}, range::AbstractUnitRange, val) where T
    val0 = convert(T, val)
    left, right = range.start, range.stop
    inc!(ft, left, +val0)
    if (right+1 <= length(ft))
        dec!(ft, right+1, val0)
    end
end

"""
    dec!(ft::FenwickTree{T}, range::AbstractUnitRange, val)

Decreases the value of the [`FenwickTree`] by `val` from the indices in `range`.

"""    
dec!(ft::FenwickTree{T}, range::AbstractUnitRange, val) where T = inc!(ft, range, -val)

"""
    prefixsum(ft::FenwickTree{T}, ind)
    
Return the cumulative sum from index 1 upto `ind` of the [`FenwickTree`](@ref)

# Examples
```
julia> f = FenwickTree{Int}(6)
julia> inc!(f, 2, 5)
julia> prefixsum(f, 1)
 0
julia> prefixsum(f, 3)
 5
julia> inc!(f, 1:4, 3)
julia> prefixsum(f, 1)
 3
julia> prefixsum(f, 3)
 8
julia> prefixsum(f, 6)
 5
```
"""
function prefixsum(ft::FenwickTree{T}, ind::Int) where T
    sum = zero(T)
    i = ind
    n = ft.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @inbounds while i > 0 
        sum += ft.bi_tree[i]
        i -= i&(-i)
    end
    sum
end

getindex(ft::FenwickTree{T}, ind::Integer) where T = prefixsum(ft, ind)
