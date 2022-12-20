struct FenwickTree{T}
    bi_tree::Vector{T} #bi_tree is shorthand for Binary Indexed Tree, an alternative name for Fenwick Tree
    n::Int
end

"""
    FenwickTree{T}(n::Integer)

Constructs a [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree) of length `n`.

"""
FenwickTree{T}(n::Integer) where T = FenwickTree{T}(zeros(T, n), n)

"""
    FenwickTree(counts::AbstractArray)

Constructs a [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree) from an array of `counts`

"""
function FenwickTree(a::AbstractVector{U}) where U
    n = length(a)
    tree = FenwickTree{U}(n)
    @inbounds for i = 1:n
        inc!(tree, i, a[i])
    end
    tree
end

Base.length(ft::FenwickTree) = ft.n
Base.eltype(::Type{FenwickTree{T}}) where T = T

"""
    inc!(ft::FenwickTree{T}, ind::Integer, val)

Increases the value of the [`FenwickTree`] by `val` from the index `ind` upto the length of the Fenwick Tree.

"""
function inc!(ft::FenwickTree{T}, ind::Integer, val = 1) where T
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
    dec!(ft::FenwickTree, ind::Integer, val)

Decreases the value of the [`FenwickTree`] by `val` from the index `ind` upto the length of the Fenwick Tree.

"""
dec!(ft::FenwickTree, ind::Integer, val = 1 ) = inc!(ft, ind, -val)

"""
    incdec!(ft::FenwickTree{T}, left::Integer, right::Integer, val)

Increases the value of the [`FenwickTree`] by `val` from the indices from `left` and decreases it from the `right`.

"""
function incdec!(ft::FenwickTree{T}, left::Integer, right::Integer, val = one(T)) where T
    val0 = convert(T, val)
    inc!(ft, left, val0)
    dec!(ft, right, val0)
end

"""
    prefixsum(ft::FenwickTree{T}, ind::Integer)

Return the cumulative sum from index 1 upto `ind` of the [`FenwickTree`](@ref)

# Examples
```
julia> f = FenwickTree{Int}(6)
julia> inc!(f, 2, 5)
julia> prefixsum(f, 1)
 0
julia> prefixsum(f, 3)
 5
```
"""
function prefixsum(ft::FenwickTree{T}, ind::Integer) where T
    sum = zero(T)
    ind < 1 && return sum
    i = ind
    n = ft.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @inbounds while i > 0
        sum += ft.bi_tree[i]
        i -= i&(-i)
    end
    sum
end

Base.getindex(ft::FenwickTree{T}, ind::Integer) where T = prefixsum(ft, ind)
