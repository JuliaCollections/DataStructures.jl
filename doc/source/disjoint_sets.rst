.. _ref-disjoint-sets:

--------------
Disjoint Sets
--------------

Some algorithms, such as finding connected components in undirected graph and Kruskal's method of finding minimum spanning tree, require a data structure that can efficiently represent a collection of disjoint subsets.
A widely used data structure for this purpose is the *Disjoint set forest*.

Usage::

  a = IntDisjointSets(10)      # creates a forest comprised of 10 singletons
  union!(a, 3, 5)             # merges the sets that contain 3 and 5 into one
  in_same_set(a, x, y)        # determines whether x and y are in the same set
  elem = push!(a)             # adds a single element in a new set; returns the new element
                              # (this operation is often called MakeSet)


One may also use other element types::

  a = DisjointSets{AbstractString}(["a", "b", "c", "d"])
  union!(a, "a", "b")
  in_same_set(a, "c", "d")
  push!(a, "f")


Note that the internal implementation of ``IntDisjointSets`` is based on vectors, and is very efficient. ``DisjointSets{T}`` is a wrapper of ``IntDisjointSets``, which uses a dictionary to map input elements to an internal index.
