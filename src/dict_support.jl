# support functions

function not_iterator_of_pairs(kv::T) where T
    # if the object is not iterable, return true, else check the eltype of the iteration
    Base.isiterable(T) || return true 
    # else, check if we can check `eltype`:
    if Base.IteratorEltype(kv) isa Base.HasEltype
        typ = eltype(kv)
        if !(typ == Any)
            return !(typ <: Union{<: Tuple, <: Pair})
        end
    end
    # we can't check eltype, or eltype is not useful, 
    # so brute force it.
    return any(x->!isa(x, Union{Tuple,Pair}), kv)
end
