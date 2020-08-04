@deprecate front(x) first(x)
@deprecate back(x) last(x)
@deprecate top(x) first(x)
#@deprecate find_root find_root! # 2020-03-31 - deprecate in v0.18, or when Julia 1.5 is released.
export find_root
const find_root = find_root!

@deprecate deque(::Type{T}) where {T} Deque{T}()

@deprecate path(t::Trie, str::AbstractString) partial_path(t::Trie, str::AbstractString)