# support function

# This is defined in Base, but probably not meant for external consumption,
# so it's redefined here.
_tablesz(x::Integer) = x < 16 ? 16 : one(x)<<((sizeof(x)<<3)-leading_zeros(x-1))

