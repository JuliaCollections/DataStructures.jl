.. _ref-trie:

----
Trie
----

An implementation of the `Trie` data structure. This is an associative structure, with `AbstractString` keys::

  t=Trie{Int}()
  t["Rob"]=42
  t["Roger"]=24
  haskey(t,"Rob") #true
  get(t,"Rob",nothing) #42
  keys(t) # "Rob", "Roger"

Constructors::

  Trie(keys, values)                  # construct a Trie with the given keys and values
  Trie(keys)                          # construct a Trie{Void} with the given keys and with values = nothing
  Trie(kvs::AbstractVector{(K, V)})   # construct a Trie from the given vector of (key, value) pairs
  Trie(kvs::Associative{K, V})        # construct a Trie from the given associative structure

This package also provides an iterator ``path(t::Trie, str)`` for looping over all the nodes
encountered in searching for the given string ``str``.
This obviates much of the boilerplate code needed in writing many trie algorithms.
For example, to test whether a trie contains any prefix of a given string,
use::

  seen_prefix(t::Trie, str) = any(v -> v.is_key, path(t, str))
