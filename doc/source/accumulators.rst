.. _ref-accumulators:

--------------------------
Accumulators and Counters
--------------------------

A accumulator, as defined below, is a data structure that maintains an accumulated number for each key. This is a counter when the accumulated values
reflect the counts::

  type Accumulator{K, V<:Number}
      map::Dict{K, V}
  end


There are different ways to construct an accumulator/counter::

  a = accumulator(K, V)    # construct an accumulator with key-type K and
                           # accumulated value type V

  a = accumulator(dict)    # construct an accumulator from a dictionary

  a = counter(K)           # construct a counter, i.e. an accumulator with
                           # key type K and value type Int

  a = counter(dict)        # construct a counter from a dictionary

  a = counter(seq)         # construct a counter by counting keys in a sequence


Usage of an accumulator/counter::

  # let a and a2 be accumulators/counters

  a[x]             # get the current value/count for x.
                   # if x was not added to a, it returns zero(V)

  push!(a, x)       # add the value/count for x by 1
  push!(a, x, v)    # add the value/count for x by v
  push!(a, a2)      # add all counts from a2 to a1

  pop!(a, x)       # remove a key x from a, and returns its current value

  merge(a, a2)     # return a new accumulator/counter that combines the
                   # values/counts in both a and a2
