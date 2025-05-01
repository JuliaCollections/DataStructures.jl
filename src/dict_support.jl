# support functions

function not_iterator_of_pairs(kv::T) where T
    return !(Base.isiterable(T)) || # if the object is not iterable, return true, else check the eltype of the iteration
           any(x->!isa(x, Union{Tuple,Pair}), kv)
end
