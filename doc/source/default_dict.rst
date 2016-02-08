.. _ref-default-dict:

----------------------------------
DefaultDict and DefaultOrderedDict
----------------------------------

A DefaultDict allows specification of a default value to return when a requested key is not in a dictionary.

While the implementation is slightly different, a ``DefaultDict`` can be thought to provide a normal ``Dict``
with a default value.  A ``DefaultOrderedDict`` does the same for an ``OrderedDict``.

Constructors::

  DefaultDict(default, kv)    # create a DefaultDict with a default value or function,
                              # optionally wrapping an existing dictionary
                              # or array of key-value pairs

  DefaultDict(KeyType, ValueType, default)   # create a DefaultDict with Dict type (KeyType,ValueType)

  DefaultOrderedDict(default, kv)     # create a DefaultOrderedDict with a default value or function,
                                      # optionally wrapping an existing dictionary
                                      # or array of key-value pairs

  DefaultOrderedDict(KeyType, ValueType, default) # create a DefaultOrderedDict with Dict type (KeyType,ValueType)


Examples using ``DefaultDict``::

  dd = DefaultDict(1)               # create an (Any=>Any) DefaultDict with a default value of 1
  dd = DefaultDict(AbstractString, Int, 0)  # create a (AbstractString=>Int) DefaultDict with a default value of 0

  d = ['a'=>1, 'b'=>2]
  dd = DefaultDict(0, d)            # provide a default value to an existing dictionary
  dd['c'] == 0                      # true
  #d['c'] == 0                      # false

  dd = DefaultOrderedDict(time)     # call time() to provide the default value for an OrderedDict
  dd = DefaultDict(Dict)            # Create a dictionary of dictionaries
                                    # Dict() is called to provide the default value
  dd = DefaultDict(()->myfunc())    # call function myfunc to provide the default value

  # These all create the same default dict
  dd = DefaultDict(AbstractString, Vector{Int},
                           () -> Vector{Int}())
  dd = DefaultDict(AbstractString, Vector{Int}, () -> Int[])

  # dd = DefaultDict(AbstractString, Vector{Int},     # **Note! Julia v0.4 and later only!
  #                  Vector{Int})             # the second Vector{Int} is called as a function

  push!(dd["A"], 1)
  push!(dd["B"], 2)

  julia> dd
  DefaultDict{AbstractString,Array{Int64,1},Function} with 2 entries:
    "B" => [2]
    "A" => [1]

  # create a Dictionary of type AbstractString=>DefaultDict{AbstractString, Int}, where the default of the
  # inner set of DefaultDicts is zero
  dd = DefaultDict(AbstractString, DefaultDict, () -> DefaultDict(AbstractString,Int,0))

```

Note that in the last example, we need to use a function to create each new ``DefaultDict``.
If we forget, we will end up using the same ``DefaultDict`` for all default values::

  julia> dd = DefaultDict(AbstractString, DefaultDict, DefaultDict(AbstractString,Int,0));

  julia> dd["a"]
  DefaultDict{AbstractString,Int64,Int64,Dict{K,V}}()

  julia> dd["b"]["a"] = 1
  1

  julia> dd["a"]
  ["a"=>1]
