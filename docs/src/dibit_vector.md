```@meta
DocTestSetup = :(using DataStructures)
```

# DiBitVector

`DiBitVector` provides a memory-efficient vector of elements that represent four different values from `0` to `3`. This structure is comparable to a `BitVector` in its performance and memory characteristics.

Examples:

```jldoctest
julia> v = DiBitVector(4, 0)
4-element DiBitVector:
 0x00
 0x00
 0x00
 0x00

julia> w = DiBitVector(4, 2)
4-element DiBitVector:
 0x02
 0x02
 0x02
 0x02

julia> v[1] = 2
2

julia> v[2:4] .= 2
3-element view(::DiBitVector, 2:4) with eltype UInt8:
 0x02
 0x02
 0x02

julia> v == w
true

julia> pop!(v)
0x02

julia> length(v)
3
```

```@meta
DocTestSetup = nothing
```
