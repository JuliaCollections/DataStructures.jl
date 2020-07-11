# Trie

An implementation of the Trie data structure. This is an associative
structure, with AbstractString keys:

```julia
t = Trie{Int}()
t["Rob"] = 42
t["Roger"] = 24
haskey(t, "Rob")  # true
get(t, "Rob", nothing)  # 42
keys(t)  # "Rob", "Roger"
keys(subtrie(t, "Ro"))  # "b", "ger"
```

Constructors:

```julia
Trie(keys, values)                  # construct a Trie with the given keys and values
Trie(keys)                          # construct a Trie{Void} with the given keys and with values = nothing
Trie(kvs::AbstractVector{(K, V)})   # construct a Trie from the given vector of (key, value) pairs
Trie(kvs::AbstractDict{K, V})       # construct a Trie from the given associative structure
```

This package also provides an iterator `partial_path(t::Trie, str)` for looping
over all the nodes encountered in searching for the given string `str`.
This obviates much of the boilerplate code needed in writing many trie
algorithms. For example, to test whether a trie contains any prefix of a
given string, use:

```julia
seen_prefix(t::Trie, str) = any(v -> v.is_key, partial_path(t, str))
```
