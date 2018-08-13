# DefaultDict and DefaultOrderedDict

A DefaultDict allows specification of a default value to return when a
requested key is not in a dictionary.

While the implementation is slightly different, a `DefaultDict` can be
thought to provide a normal `Dict` with a default value. A
`DefaultOrderedDict` does the same for an `OrderedDict`.

Constructors:

```julia
DefaultDict(default, kv)    # create a DefaultDict with a default value or function,
                            # optionally wrapping an existing dictionary
                            # or array of key-value pairs

DefaultDict{KeyType, ValueType}(default)   # create a DefaultDict with Dict type (KeyType,ValueType)

DefaultOrderedDict(default, kv)     # create a DefaultOrderedDict with a default value or function,
                                    # optionally wrapping an existing dictionary
                                    # or array of key-value pairs

DefaultOrderedDict{KeyType, ValueType}(default) # create a DefaultOrderedDict with Dict type (KeyType,ValueType)
```

All constructors also take a `passkey::Bool=false` keyword argument which determines whether to pass along the `key`
argument when calling the default function. It has no effect when the key is just a value.

Examples using `DefaultDict`:

```@setup DataStructures
using DataStructures
```

```@repl DataStructures
dd = DefaultDict(1)               # create an (Any=>Any) DefaultDict with a default value of 1
```

```@repl DataStructures
dd = DefaultDict{AbstractString, Int}(0)  # create a (AbstractString=>Int) DefaultDict with a default value of 0
```

```@repl DataStructures
d = Dict('a'=>1, 'b'=>2)
dd = DefaultDict(0, d)            # provide a default value to an existing dictionary
d['c']  # should raise a KeyError because 'c' key doesn't exist
dd['c']
```

```@repl DataStructures
dd = DefaultOrderedDict(time)     # call time() to provide the default value for an OrderedDict
dd = DefaultDict(Dict)            # Create a dictionary of dictionaries - Dict() is called to provide the default value
dd = DefaultDict(()->myfunc())    # call function myfunc to provide the default value
```

These all create the same default dict

```@repl DataStructures
dd = DefaultDict{AbstractString, Vector{Int}}(() -> Vector{Int}())
```

```@repl DataStructures
dd = DefaultDict{AbstractString, Vector{Int}}(() -> Int[])
```

```@repl DataStructures
dd = DefaultDict{AbstractString, Vector{Int}}(Vector{Int})

push!(dd["A"], 1)

push!(dd["B"], 2)

dd
```

Create a Dictionary of type `AbstractString=>DefaultDict{AbstractString, Int}`, where the default of the inner set of `DefaultDict`s is zero

```@repl DataStructures
dd = DefaultDict{AbstractString, DefaultDict}(() -> DefaultDict{AbstractString,Int}(0))
```

Use `DefaultDict` to cache an expensive function call, i.e., [memoize](https://en.wikipedia.org/wiki/Memoization)

```@repl DataStructures
dd = DefaultDict{AbstractString, Int}(passkey=true) do key
    len = length(key)
    sleep(len)
    return len
end

dd["hi"]  # slow

dd["ho"]  # slow

dd["hi"]  # fast
```

Note that in the second-last example, we need to use a function to create each new `DefaultDict`.
If we forget, we will end up using the same`DefaultDict` for all default values:

```@repl DataStructures
dd = DefaultDict{AbstractString, DefaultDict}(DefaultDict{AbstractString,Int}(0));
dd["a"]
dd["b"]["a"] = 1
dd["a"]
```
