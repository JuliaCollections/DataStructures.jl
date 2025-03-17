```@meta
DocTestSetup = :(using DataStructures)
```

# RobinDict

`RobinDict` provides a standard dictionary, conforming to the AbstractDict protocol, which uses the Robin Hood hashing algorithm with backward-shift deletion to provide improved average performance over Dict.

The interface of `RobinDict` replicates that of `Dict`.
This has an ordered version called `OrderedRobinDict`, which replicates the interface of `OrderedDict`.

Examples:

```jldoctest
julia> d = RobinDict{Int, Char}(1 => 'a', 2 => 'b')
RobinDict{Int64, Char} with 2 entries:
  2 => 'b'
  1 => 'a'

julia> d[3] = 'c';

julia> collect(d)
3-element Vector{Pair{Int64, Char}}:
 2 => 'b'
 3 => 'c'
 1 => 'a'

julia> delete!(d, 2);

julia> d[1]
'a': ASCII/Unicode U+0061 (category Ll: Letter, lowercase)

julia> d
RobinDict{Int64, Char} with 2 entries:
  3 => 'c'
  1 => 'a'

julia> pop!(d)
3 => 'c'
```

```@meta
DocTestSetup = nothing
```
