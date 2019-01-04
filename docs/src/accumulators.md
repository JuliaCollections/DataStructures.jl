# Accumulators and Counters

A accumulator, as defined below, is a data structure that maintains an
accumulated number for each key. This is a counter when the accumulated
values reflect the counts:

```julia
struct Accumulator{K, V<:Number}
    map::Dict{K, V}
end
```

## Constructors

There are different ways to construct an accumulator/counter:

```julia
a = Accumulator{K, V}()  # construct an accumulator with key-type K and
                         # accumulated value type V

a = Accumulator(dict)    # construct an accumulator from a dictionary

a = counter(K)           # construct a counter, i.e. an accumulator with
                         # key type K and value type Int

a = counter(dict)        # construct a counter from a dictionary

a = counter(seq)         # construct a counter by counting keys in a sequence

a = counter(gen)         # construct a counter by counting keys in a generator
```

## Usage
Usage of an accumulator/counter:

```julia
# let a and a2 be accumulators/counters

a[x]             # get the current value/count for x,
                 # if x was not added to a, it returns zero.

a[x] = v         # sets the current value/count for `x` to `v`


inc!(a, x)      # increment the value/count for x by 1
inc!(a, x, v)   # increment the value/count for x by v

dec!(a, x)      # decrement the value/count for x by 1
dec!(a, x, v)   # decrement the value/count for x by v

reset!(a, x)       # remove a key x from a, and return its current value

merge!(a, a2)    # add all counts from a2 to a1
merge(a, a2)     # return a new accumulator/counter that combines (sums) the
                 # values/counts in both a and a2.
```


