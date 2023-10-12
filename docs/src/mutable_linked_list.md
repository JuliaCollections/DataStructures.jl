# Mutable Linked List

The `MutableLinkedList` type implements a doubly linked list with mutable nodes.
This data structure supports constant-time insertion/removal of elements
at both ends of the list.

Usage:

```julia
l = MutableLinkedList{T}()        # initialize an empty list of type T
l = MutableLinkedList{T}(elts...) # initialize a list with elements of type T
isempty(l)                        # test whether list is empty
empty!(l)                         # empties the list
length(l)                         # get the number of elements in list
collect(l)                        # return a vector consisting of list elements
eltype(l)                         # return type of list
first(l)                          # return value of first element of list
last(l)                           # return value of last element of list
l1 == l2                          # test lists for equality
map(f, l)                         # return list with f applied to elements
filter(f, l)                      # return list of elements where f(el) == true
filter!(f, l)                     # mutating version of `filter(f,l)`
reverse(l)                        # return reversed list
reverse!(l)                       # reverse the list in place
copy(l)                           # return a copy of list
getindex(l, idx)   || l[idx]      # get value at index
getindex(l, range) || l[range]    # get values within range a:b
setindex!(l, data, idx)           # set value at index to data
append!(l, collections...)        # all elements of all collections to l
prepend(l, collections...)        # add all elements of all collections in front of l
delete!(l, idx)                   # delete element at index
delete!(l, range)                 # delete elements within range a:b
push!(l, data)                    # add element to end of list
pushfirst!(l, data)               # add element to beginning of list
pop!(l)                           # remove element from end of list
popfirst!(l)                      # remove element from beginning of list
splice!(l,idx,ins)                # remove element given as `idx` and insert elements of `ins` instead. idx is either an Int or a UnitRange

```

`MutableLinkedList` implements the Iterator interface, iterating over the list
from first to last.
