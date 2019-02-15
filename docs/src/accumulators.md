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

inc!(a, x)       # increment the value/count for x by 1
inc!(a, x, v)    # increment the value/count for x by v

dec!(a, x)       # decrement the value/count for x by 1
dec!(a, x, v)    # decrement the value/count for x by v

reset!(a, x)     # remove a key x from a, and return its current value

merge!(a, a2)    # add all counts from a2 to a1
merge(a, a2)     # return a new accumulator/counter that combines the
                 # values/counts in both a and a2
                 # `a[v] + a2[v]` over all `v` in the universe
```

`merge` is the multiset sum operation (sometimes written ⊎).

## Use as a multiset

An `Accumulator{T, <:Integer} where T` such as is returned by `counter`,
is a [multiset](https://en.wikipedia.org/wiki/Multiset) or Bag, of objects of type `T`.
If the count type is not an integer but a more general real number, then this is a form of fuzzy multiset.
We support a number of operations supporting the use of `Accumulator`s as multisets.


Note that these operations will throw an error if the accumulator has negative or zero counts for any items.

```julia

setdiff(a1, a2)          # The opposite of `merge` (i.e. multiset sum),
                         # returns a new multiset with the count of items in `a2` removed from `a1`, down to a minimum of zero
                         # `max(a1[v] - a2[v], 0)` over all `v` in the universe


union(a1, a2)            # multiset union (sometimes called maximum, or lowest common multiple)
                         # returns a new multiset with the counts being the higher of those in `a1` or `a2`.
                         # `max(a1[v], a2[v])` over all `v` in the universe

intersect(a1, a2)        # multiset intersection (sometimes called infimum or greatest common divisor)
                         # returns a new multiset with the counts being the lowest of those in `a1` or `a2`.
                         # Note that this means things not occurring in both with be removed (count zero).
                         # `min(a1[v], a2[v])` over all `v` in the universe
```
