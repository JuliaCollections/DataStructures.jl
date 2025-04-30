# support functions

function not_iterator_of_pairs(kv::T) where T
    return Base.hasmethod(Base.iterate, Tuple{T}) &&
           any(x->!isa(x, Union{Tuple,Pair}), kv)
end
