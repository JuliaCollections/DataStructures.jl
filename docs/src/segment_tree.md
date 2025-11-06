# SegmentTree

The Segment tree is a data structure implicitly representing an array with a reduce operation. It has two operations.
set_range Sets the value of the array from a to b.
get_range calculates the reduced value of the sub-array from element a to element b, using the provided operation.
The array is implicit.

# Constructor

The recommended way is to use the constructor function as follow

```julia
function SegmentTree(type::Type, size, op; iterated_op=nothing, identity=nothing)
# type: the type of the argument.
# size: the array size.
# op: the function taking two arguments of type specified, outputting one answer of that type. (function (type,type)->type)
# Must be associative. That is, op(op(a,b),c) must be equal to op(a, op(b,c)) for every a, b, and c. 
# 
# iterated_op: optional function, taking two arguments, equivalent to reducing the same value to a single value
# For example, the iterated_op of +(addition) would be *(multiplication) and the iterated_op of *(multiplication) would be ^(exponentiation).
# If not provided and specialized repeat_op not possible, it would fall back to using the "exponentiation by squaring" rule.
# function iterated_op(base, n) 
# identity: the element with the property op(a, identity) == op(identity, a) == a for all a.
# If not provided, and no specialized identity is made,
# a singleton struct called "artificial_identity" will be used and the operations will be altered slightly to handle these cases.
# That means that the value stored would be a union of the type you specified and this special type.
# If the identity is not of bits type (can be tested with isbits), must instead be represented via a function ()->identity.

#Implicitly sets the array to identity for every element.
```
# API
The recommended API uses. Other methods implement the inner working of the data structure and should not be used.
```julia
function get_range(X::SegmentTree,low,high)
#returns reduce(op, array[low:high]) implicitly. O(logn) complexity where n is the size of the array.
function set_range!(X::SegmentTree, low, high, value)
#Equivalent to setting every element of the array from array[low] to array[high] to value "value". O(logn) complexity.
```

# Correctness
This was tested on multiple test cases.

# Benchmark
This segment tree has a slower, but still acceptable performance on set_range! compared to my old c++ code,
but a very fast get_range performance. 

# Abstract Segment trees
This file provides a baseline abstract Segment tree as a baseline structure for those who want to make their own variants.
Please note that since the segment tree is not a single algorithm, but a set of algorithms, there will be many variants supporting different operations
with varying complexity. The author simply provides one basic variant of it, but feel free to extend the code.

