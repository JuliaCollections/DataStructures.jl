# support functions

# _tablesz and hashindex are defined in Base, but are not exported,
# so they are redefined here.
_tablesz(x::Integer) = x < 16 ? 16 : one(x)<<((sizeof(x)<<3)-leading_zeros(x-1))
hashindex(key, sz) = (reinterpret(Int,(hash(key))) & (sz-1)) + 1

function not_iterator_of_pairs(kv)
    return any(x->isempty(methodswith(typeof(kv), x, true)),
               [start, next, done]) ||
           any(x->!isa(x, Union{Tuple,Pair}), kv)
end
