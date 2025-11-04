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

s = OrderedSet([π,e,γ,catalan,φ])
collect(s) # => [π = 3.1415926535897...,
           #     e = 2.7182818284590...,
           #     γ = 0.5772156649015...,
           #     catalan = 0.9159655941772...,
           #     φ = 1.6180339887498...]
```

All standard `Dict` functions are available for `OrderedDicts`, and
all `Set` operations are available for `OrderedSets`. A point to be careful about is that equality does not respect order. That is, 
```julia
A1 = OrderedSet(["a", "b"])
A2 = OrderedSet(["b", "a"])
A1 == A2 # true
collect(A1) == collect(A2) # false

B1 = OrderedDict("a" => 1, "b" => 2)
B2 = OrderedDict("b" => 2, "a" => 1)
B1 == B2 # true
collect(B1) == collect(B2) # false
```

Note that to create an `OrderedSet` of a particular type, you must specify
the type in curly-braces:

```julia
# create an OrderedSet of Strings
strs = OrderedSet{AbstractString}()
```

