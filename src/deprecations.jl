# 0.18 deprecations. Remove before releasing 0.19
@deprecate path(t::Trie, str::AbstractString) partial_path(t::Trie, str::AbstractString)
@deprecate find_root find_root!
@deprecate top first
@deprecate reverse_iter Iterators.reverse
# Deprecations from #700
Base.@deprecate_binding DisjointSets DisjointSet
Base.@deprecate_binding IntDisjointSets IntDisjointSet
# We won't want to make this `@deprecate DisjointSets(xs...) DisjointSet(xs)`
# because then loading this package will trigger a deprecation warning when we
# evaluate the deprecated DisjointSets binding. This breaks any package that
# tries to load DataStructures with --depwarn=error
@deprecate DisjointSet(xs...) DisjointSet(xs)
# Enqueue and dequeue deprecations
@deprecate enqueue!(q::Queue, x) Base.push!(q, x)
@deprecate enqueue!(q::PriorityQueue, x) Base.push!(q, x)
@deprecate enqueue!(q::PriorityQueue, k, v) Base.push!(q, k=>v)
@deprecate dequeue!(q::Queue) Base.popfirst!(q)
@deprecate dequeue!(q::PriorityQueue) Base.popfirst!(q).first # maybe better: `val, _ = popfirst!(pq)`
@deprecate dequeue!(q::PriorityQueue, x) popat!(q, x).first
@deprecate dequeue_pair!(q::PriorityQueue) Base.popfirst!(q)
@deprecate dequeue_pair!(q::PriorityQueue, key) popat!(q, key)

@deprecate startof(m::SortedContainer) firstindex(m::SortedContainer)
@deprecate endof(m::SortedContainer) lastindex(m::SortedContainer)
@deprecate insert!(m::SortedSet, k) push_return_semitoken!(m::SortedSet, k)
@deprecate insert!(m::SortedDict, k, d) push_return_semitoken!(m::SortedDict, k=>d)
@deprecate insert!(m::SortedMultiDict, k, d) (push_return_semitoken!(m::SortedMultiDict, k=>d))[2]

function Base.peek(q::PriorityQueue)
    Expr(:meta, :noinline)
    Base.depwarn("`peek(q::PriorityQueue)` is deprecated, use `first(q)` instead.", :peek)
    first(q)
end
