# Stack and Queue

The `Stack` and `Queue` types are a light-weight wrapper of a deque
type, which respectively provide interfaces for LIFO and FIFO access.

Usage of Stack:

```julia
s = Stack{Int}()                # create a stack
isempty(s)                      # check whether the stack is empty
length(s)                       # get the number of elements
eltype(s)                       # get the type of elements
push!(s, 1)                     # push back a item
first(s)                        # get an item from the top of stack
pop!(s)                         # get and remove a first item
empty!(s)                       # make a stack empty
iterate(s::Stack)               # Get a LIFO iterator of a stack
Iterators.reverse(s::Stack{T})  # Get a FILO iterator of a stack
s1 == s2                        # check whether the two stacks are same
```

Usage of Queue:

```julia
q = Queue{Int}()
enqueue!(q, x)
x = first(q)
x = last(q)
x = dequeue!(q)
```

Both `Stack` and `Queue` implement the Iterator interface; iterating
over `Stack` returns items in FILO order and iterating over `Queue`
returns items in FIFO order. There is also a `reverse_iter` function
implemented for both which returns items in the reverse order for each
type (i.e. FIFO for `Stack` and LIFO for `Queue`).
