# 0.18 deprecations. Remove before releasing 0.19
@deprecate path(t::Trie, str::AbstractString) partial_path(t::Trie, str::AbstractString)
@deprecate find_root find_root!
@deprecate top first
@deprecate reverse_iter Iterators.reverse
