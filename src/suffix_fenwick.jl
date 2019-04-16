mutable struct SuffixFenwickTree{T}
    bi_tree::Vector{T} #bi_tree is shorthand for Binary Indexed Tree, an alternative name for SuffixFenwick Tree
    n::Int
end

"""
    SuffixFenwickTree{T}(n)
    
Constructs a [`SuffixFenwickTree`](https://stackoverflow.com/questions/21995930/dynamic-i-e-variable-size-fenwick-tree) of length `n`.
 
"""
SuffixFenwickTree{T}(n::Integer) where T = SuffixFenwickTree{T}(zeros(T, n), n)

"""
    SuffixFenwickTree(counts::AbstractArray) 
    
Constructs a `SuffixFenwickTree` from an array of `counts`
 
"""
function SuffixFenwickTree(a::AbstractVector{U}) where U
    n = length(a)
    tree = SuffixFenwickTree{U}(n)
    @inbounds for i = 1:n
        inc!(tree, i, a[i])
    end
    tree
end

length(sft::SuffixFenwickTree) = sft.n

"""
    inc!(sft::SuffixFenwickTree{T}, ind, val)

Increases the value of the [`SuffixFenwickTree`] by `val` from the index `ind` upto the beginning of the SuffixFenwick Tree.

""" 
function inc!(sft::SuffixFenwickTree{T}, ind::Integer, val = 1) where T
    val0 = convert(T, val)
    i = ind
    n = sft.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @inbounds while i > 0
        sft.bi_tree[i] += val0
        i -= i&(-i)
    end
end

"""
    dec!(sft::SuffixFenwickTree, ind, val)

Decreases the value of the [`SuffixFenwickTree`] by `val` from the index `ind` upto the length of the SuffixFenwick Tree.

""" 
dec!(sft::SuffixFenwickTree, ind::Integer, val = 1 ) = inc!(sft, ind, -val)

"""
    suffixsum(sft::SuffixFenwickTree{T}, ind)
    
Return the cumulative sum from `ind` upto length of the [`SuffixFenwickTree`](@ref)

# Examples
```
julia> f = SuffixFenwickTree{Int}(6)
julia> inc!(f, 2, 5)
julia> suffixsum(f, 1)
 5
julia> suffixsum(f, 3)
 0
```
"""
function suffixsum(sft::SuffixFenwickTree{T}, ind::Integer) where T
    sum = zero(T)
    i = ind
    n = sft.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @inbounds while i <= n
        sum += sft.bi_tree[i]
        i += i&(-i)
    end
    sum
end

getindex(sft::SuffixFenwickTree{T}, ind::Integer) where T = suffixsum(sft, ind)

function resize!(sft::SuffixFenwickTree{T}, size::Integer) where T
    @boundscheck size > 0 || throw(ArgumentError("size should be greater than 0"))
    n0 = sft.n
    resize!(sft.bi_tree, size)
    sft.n = size
    z = zero(T)
    @inbounds for i = n0+1: size
        sft.bi_tree[i] = z
    end
    sft
end
