# support functions

function not_iterator_of_pairs(kv::T) where T
    return Base.isiterable(kv) &&
           any(x->!isa(x, Union{Tuple,Pair}), kv)
end
