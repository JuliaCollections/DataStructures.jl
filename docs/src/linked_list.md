# Linked List

A list of sequentially linked nodes. This allows efficient insertion of
nodes to the front of the list:

```julia
julia> l1 = nil()
nil()

julia> l2 = cons(1, l1)
list(1)

julia> l3 = list(2, 3)
list(2, 3)

julia> l4 = cat(l1, l2, l3)
list(1, 2, 3)

julia> l5 = map((x) -> x*2, l4)
list(2, 4, 6)

julia> for i in l5; print(i); end
246
```
