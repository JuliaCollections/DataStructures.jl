@deprecate front(x) first(x)
@deprecate back(x) last(x)
@deprecate top(x) first(x)
#@deprecate find_root find_root! # 2020-03-31 - deprecate in v0.18, or when Julia 1.5 is released.
const find_root = find_root!