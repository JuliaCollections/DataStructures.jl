```@meta
DocTestSetup = :(using DataStructures)
```

# Trie

An implementation of the Trie data structure. This is an associative
structure, with iterable keys:

```jldoctest
julia> t = Trie{Char,Int}();


julia> t["Rob"] = 42;


julia> t["Roger"] = 24;


julia> haskey(t, "Rob")
true

julia> get(t, "Rob", nothing)
42

julia> keys(t)
2-element Vector{String}:
 "Roger"
 "Rob"

julia> keys(subtrie(t, "Ro"))
2-element Vector{String}:
 "ger"
 "b"
```

Note that the keys don't need to be `String`s:

```jldoctest
julia> t = Trie{Int,Char}();

julia> t[1:3] = 'a';

julia> t[[2,3,5]] = 'b';

julia> keys(t)
2-element Vector{Vector{Int64}}:
 [2, 3, 5]
 [1, 2, 3]
```

Constructors:

```julia
Trie(keys, values)                  # construct a Trie with the given keys and values
Trie(keys)                          # construct a Trie{K,Nothing} with the given keys and with values = nothing
Trie(kvs::AbstractVector{(K, V)})   # construct a Trie from the given vector of (key, value) pairs
Trie(kvs::AbstractDict{K, V})       # construct a Trie from the given associative structure
```

This package also provides an iterator `partial_path(t::Trie, prefix)` for looping
over all the nodes encountered in searching for the given `prefix`.
This obviates much of the boilerplate code needed in writing many trie
algorithms. For example, to test whether a trie contains any prefix of a
given string `str`, use:

```julia
seen_prefix(t::Trie, str) = any(v -> v.is_key, partial_path(t, str))
```

`find_prefixes` can be used to find all keys which are prefixes of the given string.

```jldoctest
julia> t = Trie(["A", "ABC", "ABCD", "BCE"]);

julia> find_prefixes(t, "ABCDE")
3-element Vector{String}:
 "A"
 "ABC"
 "ABCD"
```

```@meta
DocTestSetup = nothing
```
