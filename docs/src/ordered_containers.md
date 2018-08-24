# OrderedDicts and OrderedSets

`OrderedDicts` are simply dictionaries whose entries have a particular
order. For `OrderedDicts` (and `OrderedSets`), order refers to
_insertion order_, which allows deterministic iteration over the
dictionary or set:

```julia
d = OrderedDict{Char,Int}()
for c in 'a':'e'
    d[c] = c-'a'+1
end
collect(d) # => [('a',1),('b',2),('c',3),('d',4),('e',5)]

s = OrderedSet(π,e,γ,catalan,φ)
collect(s) # => [π = 3.1415926535897...,
           #     e = 2.7182818284590...,
           #     γ = 0.5772156649015...,
           #     catalan = 0.9159655941772...,
           #     φ = 1.6180339887498...]
```

All standard `Dict` functions are available for `OrderedDicts`, and
all `Set` operations are available for `OrderedSets`.

Note that to create an `OrderedSet` of a particular type, you must specify
the type in curly-braces:

```julia
# create an OrderedSet of Strings
strs = OrderedSet{AbstractString}()
```
