mutable struct GenericFenwickTree{F, T}
    bi_tree::Vector{T}
    function GenericFenwickTree{F, T}(n::Integer) where {F, T}
        new{F, T}(zeros(T, n))
    end
    function GenericFenwickTree{F}(a::AbstractVector{U}) where {F, U}
        n = length(a)
        gft = GenericFenwickTree{F, U}(n)
        @inbounds for i = 1:n
            inc!(gft, i, a[i])
        end
        return gft
    end
end

"""
    FenwickTree{T}(n::Integer)

About [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree).

"""
const FenwickTree{T} = GenericFenwickTree{:prefix, T}

"""
    SuffixFenwickTree{T}
    
About [`SuffixFenwickTree`](https://stackoverflow.com/questions/21995930/dynamic-i-e-variable-size-fenwick-tree).
 
"""
const SuffixFenwickTree{T} = GenericFenwickTree{:suffix, T}

length(gft::GenericFenwickTree) = length(gft.bi_tree)
Base.eltype(::Type{GenericFenwickTree{F, T}}) where {F, T} = T

"""
    inc!(ft::FenwickTree{T}, ind::Integer, val)

Increases the value of the [`FenwickTree`] by `val` from the index `ind` upto the length of the Fenwick Tree.

"""
function inc!(ft::FenwickTree{T}, ind::Integer, val = one(T)) where T
    n = length(ft)
    @boundscheck 1 <= ind <= n || throw(ArgumentError("$ind should be between 1 and $n"))
    @inbounds while ind <= n
        ft.bi_tree[ind] += val
        ind += ind&(-ind)
    end
end

"""
    inc!(sft::SuffixFenwickTree{T}, ind, val)

Increases the value of the [`SuffixFenwickTree`] by `val` from the index `ind` upto the beginning of the SuffixFenwick Tree.

""" 
function inc!(sft::SuffixFenwickTree{T}, ind::Integer, val = one(T)) where T
    n = length(sft)
    @boundscheck 1 <= ind <= n || throw(ArgumentError("$ind should be between 1 and $n"))
    @inbounds while ind > 0
        sft.bi_tree[ind] += val
        ind -= ind&(-ind)
    end
end

"""
    dec!(gft::GenericFenwickTree{F, T}, ind::Integer, val = one(T))

Decreases the value of the [`GenericFenwickTree`] by `val` from the index `ind`, as per dispatch.

"""
dec!(gft::GenericFenwickTree{F, T}, ind::Integer, val = one(T)) where {F, T} = inc!(gft, ind, -val)

"""
    incdec!(gft::GenericFenwickTree{F, T}, start::Integer, stop::Integer, val = one(T))

Increases the value of the [`GenericFenwickTree`] by `val` from `start`, and decreases the value from `stop`, as per dispatch.

"""
function incdec!(gft::GenericFenwickTree{F, T}, start::Integer, stop::Integer, val = one(T)) where {F, T}
    inc!(gft, start, val)
    dec!(gft, stop, val)
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
    n = length(ft)
    @boundscheck 1 <= ind <= n || throw(ArgumentError("$ind should be between 1 and $n"))
    sum = zero(T)
    @inbounds while ind > 0
        sum += ft.bi_tree[ind]
        ind -= ind&(-ind)
    end
    return sum
end

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
    n = length(sft)
    @boundscheck 1 <= ind <= n || throw(ArgumentError("$ind should be between 1 and $n"))
    sum = zero(T)
    @inbounds while ind <= n
        sum += sft.bi_tree[ind]
        ind += ind&(-ind)
    end
    return sum
end

getindex(ft::FenwickTree{T}, ind::Integer) where T = prefixsum(ft, ind)
getindex(sft::SuffixFenwickTree{T}, ind::Integer) where T = suffixsum(sft, ind)

function resize!(sft::SuffixFenwickTree{T}, size::Int) where T
    @boundscheck size > 0 || throw(ArgumentError("size should be greater than 0"))
    n0 = length(sft)
    resize!(sft.bi_tree, size)
    z = zero(T)
    @inbounds for i = n0+1: size
        sft.bi_tree[i] = z
    end
    return sft
end