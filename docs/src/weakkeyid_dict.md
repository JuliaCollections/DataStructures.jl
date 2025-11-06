# WeakKeyIdDict

`WeakKeyIdDict()` constructs a hash table where the keys are weak
references to objects, and thus may be garbage collected even when
referenced in a hash table.  Unlike the Julia-Base `WeakKeyDict`, it uses
object-id for hashing and `===` for comparison, which is often more
appropriate.

```julia
A = [1]
wkid = WeakKeyIdDict(A => 1)
wk   = WeakKeyDict(A => 1)

haskey(wkid, copy(A)) # false
haskey(wk, copy(A)) # true

A = 1
GC.gc() # make sure the [1] is garbage collected
haskey(wkid, A) # false
haskey(wk, A) # false
```
