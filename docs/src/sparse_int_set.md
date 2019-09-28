# DataStructures.SparseIntSet

Implementation of a __Sparse Integer Set__, for background see [Sparse Sets](https://www.computist.xyz/2018/06/sparse-sets.html).
Only positive non-zero `Int`s are allowed inside the set. 
The idea is to have one **packed** `Vector` storing all the `Int`s contained in the set as to allow for fast iteration, and a sparse, paged **reverse** `Vector` with the position of a particular `Int` inside the **packed** `Vector`. This allows for very fast iteration, insertion and deletion of indices.
Most behavior is similar to a normal `IntSet`, however `collect`, `first` and `last` are with respected to the **packed** vector, in which the ordering is not guaranteed. 
The **reverse** `Vector` is paged, meaning that it is a `Vector{Vector{Int}}` where each of the `Vector{Int}`s has the length of one memory page of `Int`s. Every time an index that was not yet in the range of the already present pages, a new one will be created and added to the **reverse**, allowing for dynamical growth. 
If all the indices on a particular page are deleted from the set, it will not automatically get cleaned up for performance reasons. The `cleanup!` method is provided to facilitate the reclaiming of memory of a page when all it's corresponding indices have been deleted from the set.
The `complement` of a `SparseIntSet` is defined with respect to the pages that are in use.
