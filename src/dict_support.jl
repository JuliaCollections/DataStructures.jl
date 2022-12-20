# support functions

using InteractiveUtils: methodswith

function not_iterator_of_pairs(kv)
    return any(x->isempty(methodswith(typeof(kv), x, true)),
               [iterate]) ||
           any(x->!isa(x, Union{Tuple,Pair}), kv)
end
