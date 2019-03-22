import Base.getindex
"""
    FenwickTree{T}(n)
    
Constructs a [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree) of length `n`.
 
"""
mutable struct FenwickTree{T}
    bit::Vector{T}
    n::Integer
end

FenwickTree{T}() where T = FenwickTree{T}(0)
FenwickTree{T}(n::Integer) where T = FenwickTree{T}(zeros(T, n), n)

"""
    FenwickTree(arr::AbstractArray) 
    
Constructs a [`FenwickTree`](https://en.wikipedia.org/wiki/Fenwick_tree) from `arr`.
 
"""
function FenwickTree(a::T) where T <: AbstractVector
    U = eltype(a)
    n = size(a)[1]
    bit = FenwickTree{U}(n)
    @boundscheck for i = 1:n
        update!(bit, i, a[i])
    end
    bit
end

bit(F::FenwickTree{T}) where T = F.bit
length(F::FenwickTree) = F.n

"""
    update!(F::FenwickTree{T}, ind, val::T)

Update the value of the [`FenwickTree`] by `val` from the index `ind` upto the length of the Fenwick Tree.

""" 
function update!(F::FenwickTree{T}, ind::Int, val::T) where T
    i = ind
    n = F.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @boundscheck while i <= n
        F.bit[i] += val
        i += i&(-i)
    end
end

"""
    update!(F::FenwickTree{T}, left, right, val::T)

Update the value of the [`FenwickTree`] by `val` from the index `left` upto the index `right`.

"""    
function update!(F::FenwickTree{T}, left::Int, right::Int, val::T) where T
    update!(F, left, +val)
    update!(F, right+1, -val)
end

"""
    sum(F::FenwickTree{T}, ind)
    
Return the cumulative sum from index 1 upto `ind` of the [`FenwickTree`](@ref)

# Examples
```
julia> f = FenwickTree{Int}(6)
julia> update!(f, 2, 5)
julia> sum(f, 1)
 0
julia> sum(f, 3)
 5
julia> update!(f, 1, 4, 3)
julia> sum(f, 1)
 3
julia> sum(f, 3)
 8
julia> sum(f, 6)
 5
```
"""
function sum(F::FenwickTree{T}, ind::Int) where T
    sum = zero(T)
    i = ind
    n = F.n
    @boundscheck 1 <= i <= n || throw(ArgumentError("$i should be in between 1 and $n"))
    @boundscheck while i > 0 
        sum += F.bit[i]
        i -= i&(-i)
    end
    sum
end

getindex(F::FenwickTree{T}, ind::Integer) where T = sum(F, ind)
