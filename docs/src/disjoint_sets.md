# Disjoint-Sets

Some algorithms, such as finding connected components in undirected
graph and Kruskal's method of finding minimum spanning tree, require a
data structure that can efficiently represent a collection of disjoint
subsets. A widely used data structure for this purpose is the *Disjoint
set forest* (disjoint sets).

Usage:

```julia
a = IntDisjointSet(10)  # creates a forest comprised of 10 singletons
union!(a, 3, 5)          # merges the sets that contain 3 and 5 into one and returns the root of the new set
root_union!(a, x, y)     # merges the sets that have root x and y into one and returns the root of the new set
find_root!(a, 3)         # finds the root element of the subset that contains 3
in_same_set(a, x, y)     # determines whether x and y are in the same set
elem = push!(a)          # adds a single element in a new set; returns the new element
                         # (this operation is often called MakeSet)
num_groups(a)            # returns the number of sets
```

One may also use other element types:

```julia
a = DisjointSet{AbstractString}(["a", "b", "c", "d"])
union!(a, "a", "b")
in_same_set(a, "c", "d")
push!(a, "f")
```

Note that the internal implementation of `IntDisjointSet` is based on
vectors, and is very efficient. `DisjointSet{T}` is a wrapper of
`IntDisjointSet`, which uses a dictionary to map input elements to an
internal index. Note for `DisjointSet`, `union!`, `root_union!` and
`find_root!` return the index of the root.
