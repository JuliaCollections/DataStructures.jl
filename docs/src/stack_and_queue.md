# Stack and Queue

The `Stack` and `Queue` types are a light-weight wrapper of a deque
type, which respectively provide interfaces for LIFO and FIFO access.

Usage of Stack:

```julia
s = Stack{Int}()
push!(s, x)
x = top(s)
x = pop!(s)
```

Usage of Queue:

```julia
q = Queue{Int}()
enqueue!(q, x)
x = front(q)
x = back(q)
x = dequeue!(q)
```

Both `Stack` and `Queue` implement the Iterator interface; iterating
over `Stack` returns items in FILO order and iterating over `Queue`
returns items in FIFO order. There is also a `reverse_iter` function
implemented for both which returns items in the reverse order for each
type (i.e. FIFO for `Stack` and LIFO for `Queue`).
