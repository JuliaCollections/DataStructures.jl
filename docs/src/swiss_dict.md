```@meta
DocTestSetup = :(using DataStructures)
```

# SwissDict

`SwissDict` provides a standard dictionary, conforming to the AbstractDict protocol, which is inspired from SwissTable developed by Google. This provides improved performance over Dict at extremely high Load Factor.

The interface of `SwissDict` replicates that of `Dict`.

Examples:

```jldoctest
julia> d = SwissDict(1 => 'a', 2 => 'b')
SwissDict{Int64,Char} with 2 entries:
  1 => 'a'
  2 => 'b'

julia> d[3] = 'c';

julia> collect(d)
3-element Array{Pair{Int64,Char},1}:
 1 => 'a'
 2 => 'b'
 3 => 'c'

julia> delete!(d, 2);

julia> d[1]
'a': ASCII/Unicode U+0061 (category Ll: Letter, lowercase)

julia> d
SwissDict{Int64,Char} with 2 entries:
  1 => 'a'
  3 => 'c'

julia> pop!(d)
1 => 'a'
```

```@meta
DocTestSetup = nothing
```
