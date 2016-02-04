.. _ref-stack-queue:

-----------------
Stack and Queue
-----------------

The ``Stack`` and ``Queue`` types are a light-weight wrapper of a deque type, which respectively provide interfaces for FILO and FIFO access.

Usage of Stack::

  s = Stack(Int)
  push!(s, x)
  x = top(s)
  x = pop!(s)

Usage of Queue::

  q = Queue(Int)
  enqueue!(q, x)
  x = front(q)
  x = back(q)
  x = dequeue!(q)
