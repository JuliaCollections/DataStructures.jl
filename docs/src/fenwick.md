# Fenwick Tree

The `FenwickTree` type is data structures which is used for handling increment and decrement to prefix-sums of an array efficiently.

Usage:

```julia
FenwickTree{T}(n) # Constructs a Fenwick Tree of length `n`
FenwickTree{T}(counts)  # Constructs a Fenwick Tree from an array of `counts`
inc!(ft, ind, val)  # Increases the value of the FenwickTree `ft` by `val` from the index `ind` upto the length of `ft`
dec!(ft, ind, val)  # Decreases the value of the FenwickTree `ft` by `val` from the index `ind` upto the length of `ft`
incdec!(ft, left, right, val)  # Increases the value of the FenwickTree `ft` by `val` from the indices from `left` and decreases it from the `right`
prefixsum(ft, ind)  # Return the cumulative sum from index 1 upto `ind` of the FenwickTree `ft`
```

Examples:

```julia
julia> f = FenwickTree{Int}(6)
julia> inc!(f, 2, 5)
julia> prefixsum(f, 1)
 0
julia> prefixsum(f, 3)
 5
```
